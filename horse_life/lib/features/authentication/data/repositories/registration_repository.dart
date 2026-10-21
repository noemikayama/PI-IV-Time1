// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão da falha tipada apresentada pela confirmação.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do contrato para envio do cadastro ao backend.
// -----------------------------------------------------------------------------

import '../../application/states/registration_draft.dart';

// Contrato que mantém os detalhes do Firebase Functions fora das telas.
abstract interface class RegistrationRepository {
  // Envia a senha diretamente à Function, sem gravá-la no
  // RegistrationDraft ou em armazenamento local.
  Future<void> createAccount({
    required RegistrationDraft registration,
    required String password,
  });
}

// Erro seguro para apresentação na interface, sem expor detalhes internos da
// infraestrutura Firebase.
final class RegistrationFailure implements Exception {
  const RegistrationFailure(this.message);

  const RegistrationFailure.connection()
    : message = 'Erro de conexão com o servidor';

  final String message;
}
