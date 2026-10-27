// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Restauração da sessão persistida pelo Firebase, validação do claim
// de papel e encerramento explícito da autenticação.
// -----------------------------------------------------------------------------

import 'package:firebase_auth/firebase_auth.dart';

import '../../application/states/login_session.dart';
import 'authentication_session_repository.dart';

final class FirebaseAuthenticationSessionRepository
    implements AuthenticationSessionRepository {
  const FirebaseAuthenticationSessionRepository();

  @override
  Stream<LoginSession?> watchSession() {
    return FirebaseAuth.instance.authStateChanges().asyncMap(_restoreSession);
  }

  Future<LoginSession?> _restoreSession(User? user) async {
    if (user == null) return null;

    final token = await user.getIdTokenResult(true);
    final role = AuthenticationRole.fromValue(token.claims?['role']);
    if (role == null) {
      await signOut();
      return null;
    }

    final displayName = user.displayName?.trim();
    return LoginSession(
      uid: user.uid,
      name: displayName == null || displayName.isEmpty
          ? (user.email ?? 'Usuário')
          : displayName,
      role: role,
    );
  }

  @override
  Future<void> signOut() {
    return FirebaseAuth.instance.signOut();
  }
}
