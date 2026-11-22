// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Inclusão das permissões remotas e dos campos nulos de execução.
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Criação dos contratos imutáveis de execução e feedback para
// prototipação independente da persistência remota.
// -----------------------------------------------------------------------------

/// Feedback do treinador vinculado a uma execução de treinamento.
///
/// Na API, [difficulties] e [guidelines] correspondem aos arrays
/// dificuldadesIdentificadas e orientacoes, respectivamente.
class TrainingExecutionFeedback {
  const TrainingExecutionFeedback({
    required this.createdAt,
    required this.comment,
    required this.difficulties,
    required this.guidelines,
  });

  final DateTime createdAt;
  final String comment;
  final List<String> difficulties;
  final List<String> guidelines;

  String get difficultiesText => difficulties.isEmpty
      ? 'Nenhuma dificuldade identificada.'
      : difficulties.join('\n');

  String get guidelinesText => guidelines.isEmpty
      ? 'Nenhuma orientação adicional.'
      : guidelines.join('\n');
}

/// Projeção de leitura das informações necessárias nas telas do protótipo.
/// Dados do registro retornado pela API ou pelos cenários de demonstração.
class TrainingExecutionRecord {
  const TrainingExecutionRecord({
    required this.id,
    required this.title,
    required this.objective,
    required this.durationMinutes,
    required this.executedAt,
    required this.horseName,
    required this.trainerName,
    required this.athleteName,
    required this.completedExercises,
    required this.incompleteExercises,
    required this.status,
    required this.performancePerception,
    required this.difficultiesReport,
    required this.observations,
    this.feedback,
    this.canRegisterFeedback = true,
    this.hasExecution = true,
    this.viewerIsTrainer,
  });

  final String id;
  final String title;
  final String objective;
  final int? durationMinutes;
  final DateTime? executedAt;
  final String horseName;
  final String trainerName;
  final String athleteName;
  final int? completedExercises;
  final int? incompleteExercises;
  final String status;
  final String performancePerception;
  final String difficultiesReport;
  final String observations;
  final TrainingExecutionFeedback? feedback;
  final bool canRegisterFeedback;
  final bool hasExecution;
  final bool? viewerIsTrainer;

  TrainingExecutionRecord withFeedback(TrainingExecutionFeedback value) =>
      TrainingExecutionRecord(
        id: id,
        title: title,
        objective: objective,
        durationMinutes: durationMinutes,
        executedAt: executedAt,
        horseName: horseName,
        trainerName: trainerName,
        athleteName: athleteName,
        completedExercises: completedExercises,
        incompleteExercises: incompleteExercises,
        status: status,
        performancePerception: performancePerception,
        difficultiesReport: difficultiesReport,
        observations: observations,
        feedback: value,
        canRegisterFeedback: false,
        hasExecution: hasExecution,
        viewerIsTrainer: viewerIsTrainer,
      );
}
