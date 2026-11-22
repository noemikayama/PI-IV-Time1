// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Exibição de informações ausentes sem inventar valores de execução.
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Extração dos dois cards de execução em componentes da feature,
// mantendo o CollapsibleSectionCard compartilhado pelo restante do projeto.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/collapsible_section_card.dart';
import 'package:horse_life/features/feedback/data/models/training_execution_record.dart';

import 'feedback_display_fields.dart';

class TrainingExecutionDetailsCard extends StatelessWidget {
  const TrainingExecutionDetailsCard({
    required this.record,
    required this.isTrainer,
    super.key,
  });

  final TrainingExecutionRecord record;
  final bool isTrainer;

  @override
  Widget build(BuildContext context) => CollapsibleSectionCard(
    title: 'Dados do treino',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FeedbackDetailLine(label: 'Título', value: record.title),
        FeedbackDetailLine(label: 'Objetivo', value: record.objective),
        FeedbackDetailLine(
          label: 'Tempo total',
          value: record.durationMinutes == null ? 'Não informado' : '${record.durationMinutes} minutos',
        ),
        FeedbackDetailLine(label: 'Data', value: record.executedAt == null ? 'Não informada' : formatFeedbackDate(record.executedAt!)),
        FeedbackDetailLine(label: 'Cavalo', value: record.horseName),
        FeedbackDetailLine(
          label: isTrainer ? 'Atleta' : 'Treinador',
          value: isTrainer ? record.athleteName : record.trainerName,
        ),
        FeedbackDetailLine(
          label: 'Exercícios concluídos',
          value: record.completedExercises?.toString() ?? 'Não informado',
        ),
        FeedbackDetailLine(
          label: 'Exercícios incompletos',
          value: record.incompleteExercises?.toString() ?? 'Não informado',
        ),
        FeedbackDetailLine(
          label: 'Status',
          value: trainingExecutionStatusLabel(record.status),
          bottomPadding: 0,
        ),
      ],
    ),
  );
}

class TrainingExecutionReportsCard extends StatelessWidget {
  const TrainingExecutionReportsCard({required this.record, super.key});

  final TrainingExecutionRecord record;

  @override
  Widget build(BuildContext context) => CollapsibleSectionCard(
    title: 'Reportes da execução',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FeedbackReadOnlyField(
          label: 'Percepção de desempenho',
          value: record.performancePerception,
        ),
        const SizedBox(height: 20),
        FeedbackReadOnlyField(
          label: 'Dificuldades encontradas',
          value: record.difficultiesReport,
        ),
        const SizedBox(height: 20),
        FeedbackReadOnlyField(label: 'Observações', value: record.observations),
      ],
    ),
  );
}
