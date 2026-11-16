// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Herança de FormProgressConfiguration em ExerciseProgressConfiguration
// para garantir consistência de tipagem e herança polimórfica.
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Re-exportação e adaptação da barra de progresso unificada em
// core/widgets/form_progress_indicator.dart, mantendo retrocompatibilidade.
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do indicador segmentado de progresso do fluxo de cadastro
// de exercícios, suportando a trilha de 8 etapas (específico) e a trilha de
// 7 etapas (genérico).
// -----------------------------------------------------------------------------

export '../../../../core/widgets/form_progress_indicator.dart';

import '../../../../core/widgets/form_progress_indicator.dart';
import '../../data/models/exercise_type.dart';

// Configura separadamente a quantidade de etapas de cada tipo de exercício.
class ExerciseProgressConfiguration extends FormProgressConfiguration {
  const ExerciseProgressConfiguration._({
    required this.exerciseType,
    required super.totalSteps,
  }) : super(segmentKeyPrefix: 'exercise-progress-segment');

  final ExerciseType exerciseType;

  static const specific = ExerciseProgressConfiguration._(
    exerciseType: ExerciseType.specific,
    totalSteps: 8,
  );
  static const generic = ExerciseProgressConfiguration._(
    exerciseType: ExerciseType.generic,
    totalSteps: 7,
  );
}

typedef ExerciseProgressIndicator = FormProgressIndicator;
