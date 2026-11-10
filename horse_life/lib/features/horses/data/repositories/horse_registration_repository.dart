// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026 (integração com registro persistido)
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Resultado distingue cadastro efetivo de cadastro fake nos testes.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Contrato independente de Firebase para cadastro e modalidades.
// -----------------------------------------------------------------------------

import '../models/horse_registration_draft.dart';

class HorseRegistrationResult {
  const HorseRegistrationResult({
    required this.id,
    required this.name,
    this.isPersisted = true,
    this.warning,
  });
  final String id;
  final String name;

  /// False apenas nos testes com repositório mock.
  final bool isPersisted;

  /// Cadastro realizado, mas houve problema no envio de alguma imagem.
  final String? warning;
}

class HorseRegistrationFailure implements Exception {
  const HorseRegistrationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class HorseRegistrationRepository {
  Future<List<HorseModality>> getModalities();
  Future<HorseRegistrationResult> register(HorseRegistrationDraft draft);
}
