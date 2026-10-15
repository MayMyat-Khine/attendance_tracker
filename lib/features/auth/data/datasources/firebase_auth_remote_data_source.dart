import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:attendance_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:attendance_tracker/features/auth/data/models/app_user_model.dart';
import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';

final class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _users = 'users';

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

    final profile = await _readProfile(uid);
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
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user?.uid;
    if (uid == null) {
      throw FirebaseException(plugin: 'firebase_auth', code: 'user-not-found');
    }

    final model = AppUserModel(
      id: uid,
      email: email,
      role: role,
      name: name,
      position: position,
      department: department,
    );
    await _firestore.collection(_users).doc(uid).set(model.toJson());
    return model;
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

    final profile = await _readProfile(uid);
    if (profile == null) {
      await _auth.signOut();
    }
    return profile;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AppUserModel?> _readProfile(String uid) async {
    final snapshot = await _firestore.collection(_users).doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    final profile = AppUserModel.fromFirestore(id: uid, data: data);
    if (profile == null) {
      await _auth.signOut();
      throw FirebaseException(plugin: 'cloud_firestore', code: 'missing-role');
    }
    return profile;
  }
}
