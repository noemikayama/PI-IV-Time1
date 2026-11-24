// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do controlador da submissão do cadastro.
// -----------------------------------------------------------------------------

import '../../data/repositories/registration_repository.dart';
import '../states/registration_draft.dart';

// Encaminha o cadastro validado ao repository sem expor o backend às telas.
class RegistrationController {
  const RegistrationController(this._repository);

  // Dependência abstrata que futuramente esconderá a chamada à Function.
  final RegistrationRepository _repository;

  // Submissão coordenada sem serialização ou detalhes de Firebase nesta camada.
  Future<void> createAccount({
    required RegistrationDraft registration,
    required String password,
  }) {
    return _repository.createAccount(
      registration: registration,
      password: password,
    );
  }
}
