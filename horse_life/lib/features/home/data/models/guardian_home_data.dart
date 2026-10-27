// RESPONSÁVEL PELA ATUALIZAÇÃO: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão e padronização dos componentes e dados simulados da Home do Responsável, preservando a integração existente.
// -----------------------------------------------------------------------------

// Contrato dos dados recebidos de um servidor para a Home do responsável.
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do GuardianRepository e dos modelos com as Cloud
// Functions; documentação das responsabilidades e lógicas principais,
// preservando o comportamento anterior da interface.
// -----------------------------------------------------------------------------
class GuardianTraining {
  final String title;
  final String horseName;
  final String trainerName;
  final int durationMinutes;
  final String planName;
  final bool isCompleted;
  final String? recordId;
  final String? status;

  const GuardianTraining({
    required this.title,
    required this.horseName,
    required this.trainerName,
    required this.durationMinutes,
    required this.planName,
    this.isCompleted = false,
    this.recordId,
    this.status,
  });
}

class GuardianHomeData {
  final String guardianName;
  final List<GuardianTraining> todayTrainings;
  final int weeklyCompleted;
  final int weeklyPlanned;
  final int monthlyCompleted;
  final int monthlyPlanned;
  final int allTimeCompleted;
  final List<String> horses;
  // Total real do backend; a lista da home é somente uma prévia (até 5).
  final int? totalHorses;
  final List<String> trainers;

  const GuardianHomeData({
    required this.guardianName,
    required this.todayTrainings,
    required this.weeklyCompleted,
    required this.weeklyPlanned,
    required this.monthlyCompleted,
    required this.monthlyPlanned,
    required this.allTimeCompleted,
    required this.horses,
    this.totalHorses,
    required this.trainers,
  });

  int get horsesCount => totalHorses ?? horses.length;
}
