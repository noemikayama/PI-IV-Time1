// RESPONSÁVEL PELA DOCUMENTAÇÃO/INTEGRAÇÃO: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 25/10/2026
// Autor da documentação e integração: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização dos cabeçalhos e comentários explicativos das
// principais responsabilidades, regras e fluxos do módulo Guardian.
// -----------------------------------------------------------------------------
import '../models/guardian_model.dart';
import '../models/guardian_home_data.dart';

// A conversão fica isolada para que widgets não dependam dos nomes do backend.
extension GuardianHomeToViewData on GuardianHomeModel {
  GuardianHomeData toViewData() => GuardianHomeData(
    guardianName: name,
    todayTrainings: todayTrainings
        .map(
          (training) => GuardianTraining(
            title: training.title,
            horseName: training.horseName,
            trainerName: training.trainerName,
            durationMinutes: training.durationMinutes,
            planName: training.planName,
            // A view antiga só distingue pendente/não-pendente.
            // NAO_REALIZADO também deixa de aparecer como pendente,
            // mas NÃO deve contar como treino realizado nas estatísticas.
            isCompleted: training.status != GuardianTrainingStatus.planned,
            recordId: training.recordId,
            status: training.status.apiValue,
          ),
        )
        .toList(growable: false),
    weeklyCompleted: week.completed,
    weeklyPlanned: week.total,
    monthlyCompleted: month.completed,
    monthlyPlanned: month.total,
    allTimeCompleted: allTimeCompleted,
    horses: horses.map((horse) => horse.name).toList(growable: false),
    totalHorses: totalHorses,
    trainers: trainers.map((trainer) => trainer.name).toList(growable: false),
  );
}
