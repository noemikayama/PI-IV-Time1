// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição da configuração de etapas (trainingPlan) para o fluxo de
// cadastro de planos de treinamento.
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição da configuração de 6 etapas (training) para o fluxo de
// cadastro de treinamentos.
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Suporte a segmentSpacing configurável e inclusão da configuração
// horseRegistration (12 etapas) para o fluxo de cadastro de cavalos.
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do indicador segmentado unificado de progresso para
// formulários em etapas, consolidando as versões de cadastro de usuários e
// de cadastro de exercícios em um único componente reutilizável em core/widgets.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Configuração do total de etapas e prefixo de chave para formulários segmentados.
class FormProgressConfiguration {
  const FormProgressConfiguration({
    required this.totalSteps,
    this.segmentKeyPrefix = 'form-progress-segment',
    this.segmentSpacing = 10,
  });

  /// Quantidade total de passos exibidos na barra.
  final int totalSteps;

  /// Prefixo para geração das chaves de identificação dos segmentos.
  final String segmentKeyPrefix;

  /// Espaçamento horizontal entre os segmentos da barra.
  final double segmentSpacing;

  // --- Predefinições compartilhadas pelo aplicativo ---------------------------

  /// Trilha de 4 passos para cadastro de responsável.
  static const guardian = FormProgressConfiguration(
    totalSteps: 4,
    segmentKeyPrefix: 'registration-progress-segment',
  );

  /// Trilha de 8 passos para cadastro profissional de treinador.
  static const trainer = FormProgressConfiguration(
    totalSteps: 8,
    segmentKeyPrefix: 'registration-progress-segment',
  );

  /// Trilha de 8 passos para cadastro de exercício específico vinculado a cavalo.
  static const specificExercise = FormProgressConfiguration(
    totalSteps: 8,
    segmentKeyPrefix: 'exercise-progress-segment',
  );

  /// Trilha de 7 passos para cadastro de exercício genérico.
  static const genericExercise = FormProgressConfiguration(
    totalSteps: 7,
    segmentKeyPrefix: 'exercise-progress-segment',
  );

  /// Trilha de 12 passos para cadastro de cavalo.
  static const horseRegistration = FormProgressConfiguration(
    totalSteps: 12,
    segmentKeyPrefix: 'horse-progress-segment',
    segmentSpacing: 6,
  );

  /// Trilha de 6 passos para cadastro de treinamento.
  static const training = FormProgressConfiguration(
    totalSteps: 6,
    segmentKeyPrefix: 'training-progress-segment',
  );

  /// Trilha de passos para cadastro de plano de treinamento.
  static const trainingPlan = FormProgressConfiguration(
    totalSteps: 7,
    segmentKeyPrefix: 'training-plan-progress-segment',
    segmentSpacing: 8,
  );
}

/// Barra segmentada de progresso reutilizável em formulários passo a passo.
class FormProgressIndicator extends StatelessWidget {
  const FormProgressIndicator({
    required this.currentStep,
    this.totalSteps,
    this.configuration,
    this.segmentKeyPrefix,
    this.segmentSpacing,
    super.key,
  }) : assert(
         totalSteps != null || configuration != null,
         'Informe totalSteps ou uma configuration para o FormProgressIndicator.',
       );

  /// Etapa atual em execução (base 1).
  final int currentStep;

  /// Total de etapas quando utilizado de forma independente sem configuração prévia.
  final int? totalSteps;

  /// Configuração predefinida ou customizada do formulário.
  final FormProgressConfiguration? configuration;

  /// Sobrescreve o prefixo de identificação das chaves de cada segmento.
  final String? segmentKeyPrefix;

  /// Sobrescreve o espaçamento horizontal entre segmentos.
  final double? segmentSpacing;

  int get _resolvedTotalSteps =>
      configuration?.totalSteps ?? totalSteps ?? 1;

  String get _resolvedKeyPrefix =>
      segmentKeyPrefix ??
      configuration?.segmentKeyPrefix ??
      'form-progress-segment';

  double get _resolvedSegmentSpacing =>
      segmentSpacing ?? configuration?.segmentSpacing ?? 10;

  @override
  Widget build(BuildContext context) {
    final activeStep = currentStep.clamp(0, _resolvedTotalSteps);

    return Semantics(
      label: 'Etapa $activeStep de $_resolvedTotalSteps',
      child: Row(
        children: [
          for (var index = 0; index < _resolvedTotalSteps; index++) ...[
            Expanded(
              child: Container(
                key: Key('$_resolvedKeyPrefix-${index + 1}'),
                height: 8,
                decoration: BoxDecoration(
                  color: index == activeStep - 1
                      ? AppColors.seaGreen
                      : AppColors.alabasterGray,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            if (index < _resolvedTotalSteps - 1)
              SizedBox(width: _resolvedSegmentSpacing),
          ],
        ],
      ),
    );
  }
}
