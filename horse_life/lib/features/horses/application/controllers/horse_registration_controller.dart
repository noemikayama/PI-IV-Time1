// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Regras do cadastro fora da interface e validação independente.
// -----------------------------------------------------------------------------

import '../../data/mocks/mock_horse_catalog.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../data/repositories/horse_registration_repository.dart';

/// A tela chama este controlador; ele valida e aciona o repositório.
class HorseRegistrationController {
  const HorseRegistrationController({
    required this.repository,
    required this.microchipValidator,
  });

  final HorseRegistrationRepository repository;
  final HorseMicrochipValidator microchipValidator;

  Future<HorseRegistrationResult> register(HorseRegistrationDraft draft) async {
    validateFields(draft);
    // Até o Java estar pronto, esta validação confirma somente o formato.
    try {
      await microchipValidator.validate(draft.microchip);
    } on HorseMicrochipValidationFailure catch (error) {
      throw HorseRegistrationFailure(error.message);
    }
    return repository.register(draft);
  }

  void validateFields(HorseRegistrationDraft draft) {
    if (!draft.relationship.mayRegister) {
      throw const HorseRegistrationFailure(
        'Apenas proprietários podem cadastrar cavalos.',
      );
    }
    if (draft.name.trim().length < 2 || draft.name.trim().length > 80) {
      throw const HorseRegistrationFailure(
        'O nome deve ter entre 2 e 80 caracteres.',
      );
    }
    if (!RegExp(r'^\d{15}$').hasMatch(draft.microchip)) {
      throw const HorseRegistrationFailure(
        'O microchip deve conter exatamente 15 números.',
      );
    }
    final now = DateTime.now();
    final oldest = DateTime(now.year - 50, now.month, now.day);
    if (draft.birthDate == null ||
        draft.birthDate!.isAfter(now) ||
        draft.birthDate!.isBefore(oldest)) {
      throw const HorseRegistrationFailure(
        'Selecione uma data de nascimento válida.',
      );
    }
    if (!MockHorseCatalog.breeds.contains(draft.breed) ||
        !MockHorseCatalog.coats.contains(draft.coat)) {
      throw const HorseRegistrationFailure(
        'Selecione uma raça e uma pelagem das sugestões.',
      );
    }
    if (draft.physicalLimitations.length > 30 ||
        draft.healthNotes.length > 30 ||
        draft.injuries.length > 50) {
      throw const HorseRegistrationFailure(
        'Quantidade de registros adicionais acima do limite.',
      );
    }
    if (draft.injuries.any(
      (item) => item.date.isBefore(draft.birthDate!) || item.date.isAfter(now),
    )) {
      throw const HorseRegistrationFailure(
        'Confira as datas do histórico de lesões.',
      );
    }
  }
}
