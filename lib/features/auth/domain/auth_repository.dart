abstract class AuthRepository {
  Future<bool> login(String email, String password);
  Future<void> logout();
  Stream<bool> get authStateChanges;
  Future<bool> checkIsAdmin(String email);
  Future<String?> getCurrentUserEmail();
}
