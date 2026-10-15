import 'package:attendance_tracker/features/auth/domain/entities/app_user.dart';
import 'package:attendance_tracker/features/auth/domain/entities/user_role.dart';

final class AppUserModel {
  const AppUserModel({
    required this.id,
    required this.email,
    required this.role,
    this.name,
    this.position,
    this.department,
    this.photoUrl,
  });

  final String id;
  final String email;
  final UserRole role;
  final String? name;
  final String? position;
  final String? department;
  final String? photoUrl;

  AppUser toEntity() {
    return AppUser(
      id: id,
      email: email,
      role: role,
      name: name,
      position: position,
      department: department,
      photoUrl: photoUrl,
    );
  }

  factory AppUserModel.fromEntity(AppUser user) {
    return AppUserModel(
      id: user.id,
      email: user.email,
      role: user.role,
      name: user.name,
      position: user.position,
      department: user.department,
      photoUrl: user.photoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'name': name ?? '',
      'position': position ?? '',
      'department': department ?? '',
      'role': role.name,
      'nameLower': (name ?? '').trim().toLowerCase(),
      'emailLower': email.trim().toLowerCase(),
      'photoUrl': photoUrl ?? '',
    };
  }

  static AppUserModel? fromFirestore({
    required String id,
    required Map<String, dynamic>? data,
  }) {
    if (data == null) {
      return null;
    }
    final email = data['email'];
    if (email is! String) {
      return null;
    }
    final role = _roleFromName(data['role']);
    if (role == null) {
      return null;
    }
    return AppUserModel(
      id: id,
      email: email,
      role: role,
      name: _stringField(data['name']),
      position: _stringField(data['position']),
      department: _stringField(data['department']),
      photoUrl: _stringField(data['photoUrl']),
    );
  }

  static String _stringField(Object? value) {
    if (value is! String) {
      return '';
    }
    return value;
  }

  static UserRole? _roleFromName(Object? value) {
    return switch (value) {
      'admin' => UserRole.admin,
      'user' => UserRole.user,
      _ => null,
    };
  }
}
