// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos e segmentos do código de autenticação,
// detalhando responsabilidades, fluxo de dados e integração entre camadas.
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Restauração da sessão persistida pelo Firebase, validação do claim
// de papel e encerramento explícito da autenticação.
// -----------------------------------------------------------------------------

import 'package:firebase_auth/firebase_auth.dart';

import '../../application/states/login_session.dart';
import 'authentication_session_repository.dart';

// Adapta as mudanças de estado do Firebase para o modelo mínimo da aplicação.
final class FirebaseAuthenticationSessionRepository
    implements AuthenticationSessionRepository {
  const FirebaseAuthenticationSessionRepository();

  @override
  Stream<LoginSession?> watchSession() {
    // Cada alteração força a reconstrução da sessão e a validação do claim.
    return FirebaseAuth.instance.authStateChanges().asyncMap(_restoreSession);
  }

  // Uma credencial só é aceita quando o token contém um papel conhecido.
  Future<LoginSession?> _restoreSession(User? user) async {
    if (user == null) return null;

    final token = await user.getIdTokenResult(true);
    final role = AuthenticationRole.fromValue(token.claims?['role']);
    if (role == null) {
      // Impede que uma conta com autorização incompatível permaneça ativa.
      await signOut();
      return null;
    }

    // O nome de exibição tem prioridade; o e-mail é um fallback seguro.
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
    // Delega ao SDK para também limpar a persistência local da credencial.
    return FirebaseAuth.instance.signOut();
  }
}
