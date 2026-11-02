abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;
  Future<AuthUser> signIn(String email, String password);
  Future<void> signOut();
}

final class AuthUser {
  const AuthUser({required this.id, required this.email});

  final String id;
  final String email;
}
