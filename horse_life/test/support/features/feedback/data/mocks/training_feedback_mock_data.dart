// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Centralização dos cenários demonstrativos e da adaptação de itens
// da agenda, deixando o repositório mock responsável apenas pelo armazenamento.
// -----------------------------------------------------------------------------

import 'package:horse_life/features/training/data/models/training_agenda_data.dart';

import 'package:horse_life/features/feedback/data/models/training_execution_record.dart';

/// Fonte exclusivamente local de registros exemplificativos da feature.
abstract final class TrainingFeedbackMockData {
  static List<TrainingExecutionRecord> initialRecords() {
    final executedAt = DateTime(2026, 11, 19);
    final exampleFeedback = TrainingExecutionFeedback(
      createdAt: DateTime(2026, 11, 20),
      comment: 'O conjunto apresentou boa resposta aos exercícios. '
          'A regularidade no ritmo melhorou durante a sessão.',
      difficulties: [
        'Pequena perda de equilíbrio e atenção na mão esquerda.',
      ],
      guidelines: [
        'Reforçar as transições com calma e manter o trabalho bilateral.',
      ],
    );
    final pending = TrainingExecutionRecord(
      id: 'feedback-demo-pendente',
      title: 'Treino de adestramento',
      objective: 'Trabalhar transições, ritmo e equilíbrio.',
      durationMinutes: 45,
      executedAt: executedAt,
      horseName: 'Apollo',
      trainerName: 'Mariana Costa',
      athleteName: 'Ana Ribeiro',
      completedExercises: 4,
      incompleteExercises: 1,
      status: 'PARCIAL',
      performancePerception: 'Executado com facilidade',
      difficultiesReport: 'Complicações quando está na mão esquerda',
      observations: 'Cavalo mais agitado no início',
    );
    final registered = TrainingExecutionRecord(
      id: 'feedback-demo-registrado',
      title: 'Treino de equilíbrio',
      objective: 'Melhorar ritmo e resposta aos comandos.',
      durationMinutes: 40,
      executedAt: executedAt,
      horseName: 'Luna',
      trainerName: 'Mariana Costa',
      athleteName: 'Ana Ribeiro',
      completedExercises: 5,
      incompleteExercises: 0,
      status: 'REALIZADO',
      performancePerception: 'Executado com facilidade',
      difficultiesReport: 'Pouca estabilidade nas curvas',
      observations: 'Boa resposta após o aquecimento',
      feedback: TrainingExecutionFeedback(
        createdAt: DateTime(2026, 11, 20),
        comment: exampleFeedback.comment,
        difficulties: exampleFeedback.difficulties,
        guidelines: exampleFeedback.guidelines,
      ),
    );
    return [pending, registered];
  }

  /// Usa campos disponíveis da agenda; o restante permanece ilustrativo.
  static TrainingExecutionRecord fromAgenda(TrainingAgendaEntry entry) {
    return TrainingExecutionRecord(
      id: entry.id,
      title: entry.title,
      objective: 'Aprimorar a técnica e a regularidade dos movimentos.',
      durationMinutes: entry.durationMinutes > 0 ? entry.durationMinutes : 45,
      executedAt: entry.date,
      horseName: entry.horseName,
      trainerName: entry.trainerName,
      athleteName: 'Atleta de demonstração',
      completedExercises: 4,
      incompleteExercises: entry.status == TrainingAgendaStatus.partial ? 1 : 0,
      status: switch (entry.status) {
        TrainingAgendaStatus.completed => 'REALIZADO',
        TrainingAgendaStatus.partial => 'PARCIAL',
        TrainingAgendaStatus.notCompleted => 'NAO_REALIZADO',
        TrainingAgendaStatus.planned => 'PLANEJADO',
      },
      performancePerception: 'Executado com facilidade',
      difficultiesReport: 'Complicações quando está na mão esquerda',
      observations: 'Cavalo mais agitado no início',
    );
  }
}
