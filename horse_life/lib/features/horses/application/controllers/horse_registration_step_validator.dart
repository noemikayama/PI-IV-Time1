// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Regras para avançar em cada etapa isoladas da interface.
// -----------------------------------------------------------------------------

import '../states/horse_registration_step.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_microchip_validator.dart';

/// Mensagem exibida quando uma etapa não está pronta para avançar.
class HorseStepWarning {
  const HorseStepWarning(this.title, this.message);
  final String title;
  final String message;
}

/// Valida as etapas. Não salva nada; a persistência continua no controller.
class HorseRegistrationStepValidator {
  const HorseRegistrationStepValidator(this.microchipValidator);

  final HorseMicrochipValidator microchipValidator;

  Future<HorseStepWarning?> validate(
    HorseRegistrationStep step,
    HorseRegistrationDraft draft,
  ) async {
    switch (step) {
      case HorseRegistrationStep.relationship:
        if (!draft.relationship.mayRegister) {
          return const HorseStepWarning(
            'Atletas não podem cadastrar cavalos',
            'O vínculo de atleta permite executar treinos, mas o cadastro do cavalo é exclusivo do proprietário.',
          );
        }
        break;
      case HorseRegistrationStep.microchip:
        try {
          // O Java poderá substituir este validador sem alterar as telas.
          await microchipValidator.validate(draft.microchip);
        } on HorseMicrochipValidationFailure catch (error) {
          return HorseStepWarning('Código inválido', error.message);
        } catch (_) {
          return const HorseStepWarning(
            'Verificação indisponível',
            'Não foi possível verificar o microchip agora. Tente novamente.',
          );
        }
        break;
      case HorseRegistrationStep.birthDate:
        final date = draft.birthDate;
        final now = DateTime.now();
        final oldest = DateTime(now.year - 50, now.month, now.day);
        if (date == null || date.isAfter(now) || date.isBefore(oldest)) {
          return const HorseStepWarning(
            'Data inválida',
            'Selecione uma data de nascimento válida, entre hoje e 50 anos atrás.',
          );
        }
        break;
      case HorseRegistrationStep.breed:
        if (draft.breed.isEmpty) {
          return const HorseStepWarning(
            'Raça obrigatória',
            'Digite e selecione uma raça entre as sugestões.',
          );
        }
        break;
      case HorseRegistrationStep.coat:
        if (draft.coat.isEmpty) {
          return const HorseStepWarning(
            'Pelagem obrigatória',
            'Digite e selecione uma pelagem entre as sugestões.',
          );
        }
        break;
      case HorseRegistrationStep.injuries:
        final birth = draft.birthDate;
        if (birth != null &&
            draft.injuries.any((injury) => injury.date.isBefore(birth))) {
          return const HorseStepWarning(
            'Data de lesão inválida',
            'Uma lesão não pode ser anterior ao nascimento do cavalo.',
          );
        }
        break;
      case HorseRegistrationStep.name:
      case HorseRegistrationStep.sex:
      case HorseRegistrationStep.images:
      case HorseRegistrationStep.modality:
      case HorseRegistrationStep.limitations:
      case HorseRegistrationStep.health:
      case HorseRegistrationStep.review:
        break;
    }
    return null;
  }
}
