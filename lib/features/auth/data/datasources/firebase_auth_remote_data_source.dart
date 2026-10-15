import 'package:attendance_tracker/core/network/network_info.dart';
import 'package:attendance_tracker/core/config/app_environment.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:attendance_tracker/core/error/map_to_failure.dart';
import 'package:attendance_tracker/core/error/failure.dart';
import 'package:attendance_tracker/features/auth/domain/entities/profile_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:attendance_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:attendance_tracker/features/auth/data/models/app_user_model.dart';
import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';

final class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource({
    FirebaseAuth? auth,
    required this._networkInfo,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final NetworkInfo _networkInfo;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static String get _users => AppConfig.users;
  AppUserModel? _cachedProfile;

  @override
  Future<AppUserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user?.uid;
    if (uid == null) {
      throw FirebaseException(plugin: 'firebase_auth', code: 'user-not-found');
    }

    final profile = await _readProfile(uid, server: true);
    if (profile == null) {
      await _auth.signOut();
    }
    return profile;
  }

  @override
  Future<AppUserModel> register({
    required String email,
    required String password,
    required UserRole role,
    String? name,
    String? position,
    String? department,
    ProfileImage? profileImage,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user?.uid;
    if (uid == null) {
      throw FirebaseException(plugin: 'firebase_auth', code: 'user-not-found');
    }

    String? photoUrl;
    try {
      if (profileImage != null) {
        final ref = FirebaseStorage.instance.ref(
          '${AppConfig.profiles}/$uid/avatar',
        );
        await ref.putData(
          profileImage.bytes,
          SettableMetadata(contentType: profileImage.contentType),
        );
        photoUrl = await ref.getDownloadURL();
      }
      final model = AppUserModel(
        id: uid,
        email: email,
        role: UserRole.user,
        photoUrl: photoUrl,
        name: name,
        position: position,
        department: department,
      );
      await _firestore.collection(_users).doc(uid).set(model.toJson());
      _cachedProfile = model;
      return model;
    } catch (_) {
      try {
        await FirebaseStorage.instance
            .ref('${AppConfig.profiles}/$uid/avatar')
            .delete();
      } catch (_) {}
      try {
        await credential.user?.delete();
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<AppUserModel?> currentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return null;
    }

    if (_cachedProfile?.id == uid) {
      return _cachedProfile;
    }
    final profile = await _readProfile(uid);
    if (profile == null) {
      await _auth.signOut();
    }
    return profile;
  }

  @override
  Future<void> signOut() async {
    _cachedProfile = null;
    await _auth.signOut();
  }

  Future<AppUserModel?> _readProfile(String uid, {bool server = false}) async {
    final offline = !server && !await _networkInfo.isConnected;
    final ref = _firestore.collection(_users).doc(uid);
    DocumentSnapshot<Map<String, Object?>> snapshot;
    try {
      snapshot = await ref
          .get(GetOptions(source: offline ? Source.cache : Source.server))
          .timeout(const Duration(seconds: 8));
    } catch (error) {
      if (server || mapToFailure(error) is! NetworkFailure) rethrow;
      snapshot = await ref.get(const GetOptions(source: Source.cache));
    }
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    final profile = AppUserModel.fromFirestore(id: uid, data: data);
    if (profile == null) {
      await _auth.signOut();
      throw FirebaseException(plugin: 'cloud_firestore', code: 'missing-role');
    }
    _cachedProfile = profile;
    return profile;
  }
}
