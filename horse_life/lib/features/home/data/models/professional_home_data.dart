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
class ProfessionalTraining {
  final String id;
  final String title;
  final String horseName;
  final String planName;
  final String? status;

  const ProfessionalTraining({
    required this.id,
    required this.title,
    required this.horseName,
    required this.planName,
    this.status,
  });
}

class ProfessionalHorse {
  final String id;
  final String name;

  const ProfessionalHorse({required this.id, required this.name});
}

class ProfessionalClient {
  final String id;
  final String name;

  const ProfessionalClient({required this.id, required this.name});
}

/// Contrato dos dados fornecidos à Home; independente de Firebase e dos widgets.
class ProfessionalHomeData {
  final String professionalName;
  final String specialty;
  final List<ProfessionalTraining> todayTrainings;
  final int weeklyFeedbacksDone;
  final int weeklyFeedbacksTotal;
  final int activePlans;
  final int weeklyTrainingsCompleted;
  final int weeklyTrainingsPlanned;
  final int createdExercises;
  final List<ProfessionalHorse> horses;
  final int? totalLinkedHorses;
  final List<ProfessionalClient> clients;

  const ProfessionalHomeData({
    required this.professionalName,
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
