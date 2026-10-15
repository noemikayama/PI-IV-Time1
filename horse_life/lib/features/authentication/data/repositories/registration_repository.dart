// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do contrato para envio do cadastro ao backend.
// -----------------------------------------------------------------------------

import '../../application/states/registration_draft.dart';

// Seam para a futura implementação baseada em Firebase Functions.
abstract interface class RegistrationRepository {
  // A implementação futura deverá enviar a senha diretamente à Function, sem
  // gravá-la no RegistrationDraft ou em armazenamento local.
  Future<void> createAccount({
    required RegistrationDraft registration,
    required String password,
  });
}
