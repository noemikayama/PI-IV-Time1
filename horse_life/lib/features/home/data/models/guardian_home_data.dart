// Contrato dos dados recebidos de um servidor para a Home do responsável.
class GuardianTraining {
  final String title;
  final String horseName;
  final String trainerName;
  final int durationMinutes;
  final String planName;
  final bool isCompleted;

  const GuardianTraining({
    required this.title,
    required this.horseName,
    required this.trainerName,
    required this.durationMinutes,
    required this.planName,
    this.isCompleted = false,
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
    required this.trainers,
  });

  int get horsesCount => horses.length;
}
