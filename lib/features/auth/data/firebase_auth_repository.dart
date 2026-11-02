import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../domain/auth_repository.dart';

final class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final firebase.FirebaseAuth _auth;

  @override
  Stream<AuthUser?> get authStateChanges => _auth.authStateChanges().map(
        (user) => user == null
            ? null
            : AuthUser(id: user.uid, email: user.email ?? ''),
      );

  @override
  Future<AuthUser> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('O Firebase não retornou um usuário autenticado.');
    }
    return AuthUser(id: user.uid, email: user.email ?? email);
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
