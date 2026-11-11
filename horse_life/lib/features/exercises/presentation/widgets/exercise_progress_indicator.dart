// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do indicador segmentado de progresso do fluxo de cadastro
// de exercícios, suportando a trilha de 8 etapas (específico) e a trilha de
// 7 etapas (genérico).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/exercise_type.dart';

// Configura separadamente a quantidade de etapas de cada tipo de exercício.
class ExerciseProgressConfiguration {
  const ExerciseProgressConfiguration._({
    required this.exerciseType,
    required this.totalSteps,
  });

  // Identidade do fluxo e número total de etapas exibidas no topo da tela.
  final ExerciseType exerciseType;
  final int totalSteps;

  // Exercício específico possui 8 etapas (incluindo a seleção do cavalo).
  static const specific = ExerciseProgressConfiguration._(
    exerciseType: ExerciseType.specific,
    totalSteps: 8,
  );

  // Exercício genérico possui 7 etapas (iniciando diretamente pelo nome).
  static const generic = ExerciseProgressConfiguration._(
    exerciseType: ExerciseType.generic,
    totalSteps: 7,
  );
}

// Exibe o progresso segmentado correspondente ao fluxo de exercício escolhido.
class ExerciseProgressIndicator extends StatelessWidget {
  const ExerciseProgressIndicator({
    required this.configuration,
    required this.currentStep,
    super.key,
  });

  // Configuração do fluxo e etapa ativa, usando índice iniciado em um.
  final ExerciseProgressConfiguration configuration;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    // Restringe valores externos aos limites disponíveis no indicador.
    final activeStep = currentStep.clamp(0, configuration.totalSteps);

    return Semantics(
      label: 'Etapa $activeStep de ${configuration.totalSteps}',
      // Cada segmento ocupa a mesma largura e somente o atual recebe destaque.
      child: Row(
        children: [
          for (var index = 0; index < configuration.totalSteps; index++) ...[
            Expanded(
              child: Container(
                key: Key('exercise-progress-segment-${index + 1}'),
                height: 8,
                decoration: BoxDecoration(
                  color: index == activeStep - 1
                      ? AppColors.seaGreen
                      : AppColors.alabasterGray,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            if (index < configuration.totalSteps - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}
