// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// HISTÓRICO DE ALTERAÇÕES
// 30/10/2026 - Mock de indicadores profissionais prontos por período, sem Firebase.

class TrainerProfessionalSnapshot {
  const TrainerProfessionalSnapshot({
    required this.createdPlans,
    required this.activePlans,
    required this.completedPlans,
    required this.cancelledPlans,
    required this.feedbackPercent,
    required this.clients,
    required this.linkedHorses,
    required this.evaluations,
    required this.exercises,
  });
  final int createdPlans, activePlans, completedPlans, cancelledPlans;
  final int feedbackPercent, clients, linkedHorses, evaluations, exercises;
  static const empty = TrainerProfessionalSnapshot(
    createdPlans: 0,
    activePlans: 0,
    completedPlans: 0,
    cancelledPlans: 0,
    feedbackPercent: 0,
    clients: 0,
    linkedHorses: 0,
    evaluations: 0,
    exercises: 0,
  );
}

abstract final class TrainerDashboardMockData {
  static const periods = [
    'Desde sempre',
    'Diário',
    'Semanal',
    'Último mês',
    'Últimos 6 meses',
    'Último ano',
  ];
  // Valores demonstrativos preenchidos manualmente: a Function fará cálculos reais.
  static const snapshots = <String, TrainerProfessionalSnapshot>{
    'Desde sempre': TrainerProfessionalSnapshot(
      createdPlans: 7,
      activePlans: 6,
      completedPlans: 1,
      cancelledPlans: 0,
      feedbackPercent: 76,
      clients: 13,
      linkedHorses: 12,
      evaluations: 19,
      exercises: 16,
    ),
    'Diário': TrainerProfessionalSnapshot.empty,
    'Semanal': TrainerProfessionalSnapshot(
      createdPlans: 1,
      activePlans: 1,
      completedPlans: 0,
      cancelledPlans: 0,
      feedbackPercent: 80,
      clients: 13,
      linkedHorses: 12,
      evaluations: 2,
      exercises: 1,
    ),
    'Último mês': TrainerProfessionalSnapshot(
      createdPlans: 2,
      activePlans: 2,
      completedPlans: 0,
      cancelledPlans: 0,
      feedbackPercent: 75,
      clients: 13,
      linkedHorses: 12,
      evaluations: 5,
      exercises: 4,
    ),
    'Últimos 6 meses': TrainerProfessionalSnapshot(
      createdPlans: 5,
      activePlans: 4,
      completedPlans: 1,
      cancelledPlans: 0,
      feedbackPercent: 78,
      clients: 13,
      linkedHorses: 12,
      evaluations: 14,
      exercises: 11,
    ),
    'Último ano': TrainerProfessionalSnapshot(
      createdPlans: 7,
      activePlans: 6,
      completedPlans: 1,
      cancelledPlans: 0,
      feedbackPercent: 76,
      clients: 13,
      linkedHorses: 12,
      evaluations: 19,
      exercises: 16,
    ),
  };
  static TrainerProfessionalSnapshot forPeriod(String period) =>
      snapshots[period] ?? TrainerProfessionalSnapshot.empty;
}
