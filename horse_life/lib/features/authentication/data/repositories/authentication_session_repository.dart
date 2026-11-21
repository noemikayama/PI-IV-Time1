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
// Alteração: Criação do contrato para observar e encerrar a sessão persistente.
// -----------------------------------------------------------------------------

import '../../application/states/login_session.dart';

// Boundary da sessão persistente. O AppGate observa esse contrato sem conhecer
// FirebaseAuth ou o formato dos claims do token.
abstract interface class AuthenticationSessionRepository {
  // Emite null no logout e uma sessão válida em cada autenticação restaurada.
  Stream<LoginSession?> watchSession();

  // Encerra explicitamente a credencial persistida pelo provedor.
  Future<void> signOut();
}
