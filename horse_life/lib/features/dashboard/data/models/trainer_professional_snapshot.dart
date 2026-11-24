// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Criação do modelo tipado de indicadores profissionais retornados pelo getDashboard.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários pontuais sobre a responsabilidade do arquivo.
//
// -----------------------------------------------------------------------------

/// Define o modelo tipado dos dados profissionais recebidos da Function.
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

  final int createdPlans;
  final int activePlans;
  final int completedPlans;
  final int cancelledPlans;
  final int feedbackPercent;
  final int clients;
  final int linkedHorses;
  final int evaluations;
  final int exercises;
}
