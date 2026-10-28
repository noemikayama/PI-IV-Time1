// RESPONSÁVEL PELA IMPLEMENTAÇÃO FLUTTER: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 27/10/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Definição de valor padrão 0 para activePlans quando o backend
// não fornecer o campo planosAtivos, evitando indicador de dado nulo na Home.
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Separação entre modelo de API e dados da Home do Profissional,
// preservando IDs e total de cavalos, conforme o Mapper do Guardian.
// -----------------------------------------------------------------------------
import '../models/trainer_model.dart';
import '../models/trainer_home_data.dart';

/// Mantém nomes e detalhes de serialização do backend fora dos widgets.
extension TrainerHomeToViewData on TrainerHomeModel {
  TrainerHomeData toViewData() => TrainerHomeData(
        trainerName: name,
        specialty: specialty,
        totalLinkedHorses: totalHorses,
        todayTrainings: todayTrainings
            .map((training) => TrainerTraining(
                  id: training.recordId,
                  title: training.title,
                  horseName: training.horseName,
                  planName: training.planName,
                  status: training.status,
                ))
            .toList(growable: false),
        weeklyFeedbacksDone: feedbacksWeek.completed,
        weeklyFeedbacksTotal: feedbacksWeek.total,
        activePlans: activePlans ?? 0,
        weeklyTrainingsCompleted: trainingsWeek.completed,
        weeklyTrainingsPlanned: trainingsWeek.total,
        createdExercises: createdExercises,
        horses: horses
            .map((horse) => TrainerHorse(id: horse.id, name: horse.name))
            .toList(growable: false),
        clients: clients
            .map((client) => TrainerClient(id: client.id, name: client.name))
            .toList(growable: false),
      );
}
