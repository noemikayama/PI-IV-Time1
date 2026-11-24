// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação das dependências e operações coordenadas pelo
// controlador de perfil.
//
// Data: 04/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do controlador que coordena a atualização do nome do
// responsável e a solicitação de redefinição de senha.
// -----------------------------------------------------------------------------

import 'package:horse_life/features/authentication/data/repositories/password_reset_repository.dart';
import 'package:horse_life/features/profile/data/models/guardian_profile_data.dart';
import 'package:horse_life/features/profile/data/repositories/guardian_profile_repository.dart';

/// Coordena as alterações do perfil sem expor integrações à apresentação.
class GuardianProfileController {
  const GuardianProfileController({
    required GuardianProfileRepository profileRepository,
    required PasswordResetRepository passwordResetRepository,
  }) : _profileRepository = profileRepository,
       _passwordResetRepository = passwordResetRepository;

  // --- Dependências de aplicação --------------------------------------------
  // Cada repositório preserva sua responsabilidade e pode ser substituído em
  // testes sem expor Firebase ou autenticação à camada de apresentação.
  final GuardianProfileRepository _profileRepository;
  final PasswordResetRepository _passwordResetRepository;

  // --- Operações do perfil --------------------------------------------------
  /// Encaminha os campos editáveis ao repositório de perfil.
  Future<GuardianProfileUpdate> updateName({
    required String firstName,
    required String lastName,
  }) {
    return _profileRepository.updateGuardianProfile(
      firstName: firstName,
      lastName: lastName,
    );
  }

  /// Solicita o envio das instruções de redefinição ao e-mail cadastrado.
  Future<String> requestPasswordReset(String email) {
    return _passwordResetRepository.requestPasswordReset(email: email);
  }
}
