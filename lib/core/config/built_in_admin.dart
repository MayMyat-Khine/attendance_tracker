abstract final class BuiltInAdmin {
  static const email = 'admin123@gmail.com';
  static const password = '123456';

  static bool matches({required String email, required String password}) {
    return email.trim().toLowerCase() == BuiltInAdmin.email &&
        password == BuiltInAdmin.password;
  }

  static bool matchesEmail(String? email) {
    return email?.trim().toLowerCase() == BuiltInAdmin.email;
  }
}
