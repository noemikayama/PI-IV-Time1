// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Criação dos modelos tipados da Home do Profissional, incluindo
// treinos, cavalos, clientes e indicadores de desempenho.
// -----------------------------------------------------------------------------
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Inclusão do total real de cavalos e status opcional dos treinos,
// compatibilizando a Home com os modelos e Mapper da API.
// -----------------------------------------------------------------------------

/// Treino acompanhado pelo profissional na tela inicial.
class TrainerTraining {
  final String id;
  final String title;
  final String horseName;
  final String planName;
  final String? status;

  const TrainerTraining({
    required this.id,
    required this.title,
    required this.horseName,
    required this.planName,
    this.status,
  });
}

class TrainerHorse {
  final String id;
  final String name;

  const TrainerHorse({required this.id, required this.name});
}

class TrainerClient {
  final String id;
  final String name;

  const TrainerClient({required this.id, required this.name});
}

// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Os campos de especialidade e planos ativos agora podem estar
// ausentes, conforme contrato do backend Trainer.
// -----------------------------------------------------------------------------

/// Contrato dos dados fornecidos à Home; independente de Firebase e dos widgets.
class TrainerHomeData {
  final String trainerName;
  final String? specialty;
  final List<TrainerTraining> todayTrainings;
  final int weeklyFeedbacksDone;
  final int weeklyFeedbacksTotal;
  final int? activePlans;
  final int weeklyTrainingsCompleted;
  final int weeklyTrainingsPlanned;
  final int createdExercises;
  final List<TrainerHorse> horses;
  final int? totalLinkedHorses;
  final List<TrainerClient> clients;

  const TrainerHomeData({
    required this.trainerName,
    required this.specialty,
    required this.todayTrainings,
    required this.weeklyFeedbacksDone,
    required this.weeklyFeedbacksTotal,
    required this.activePlans,
    required this.weeklyTrainingsCompleted,
    required this.weeklyTrainingsPlanned,
    required this.createdExercises,
    required this.horses,
    this.totalLinkedHorses,
    required this.clients,
  });

  int get linkedHorsesCount => totalLinkedHorses ?? horses.length;
}
