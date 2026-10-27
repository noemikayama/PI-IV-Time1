// RESPONSÁVEL PELA IMPLEMENTAÇÃO FLUTTER: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Separação entre modelo de API e dados da Home do Profissional,
// preservando IDs e total de cavalos, conforme o Mapper do Guardian.
// -----------------------------------------------------------------------------
import '../models/professional_model.dart';
import '../models/professional_home_data.dart';

/// Mantém nomes e detalhes de serialização do backend fora dos widgets.
extension ProfessionalHomeToViewData on ProfessionalHomeModel {
  ProfessionalHomeData toViewData() => ProfessionalHomeData(
        professionalName: name,
        specialty: specialty,
        totalLinkedHorses: totalHorses,
        todayTrainings: todayTrainings
            .map((training) => ProfessionalTraining(
                  id: training.recordId,
                  title: training.title,
                  horseName: training.horseName,
                  planName: training.planName,
                  status: training.status,
                ))
            .toList(growable: false),
        weeklyFeedbacksDone: feedbacksWeek.completed,
        weeklyFeedbacksTotal: feedbacksWeek.total,
        activePlans: activePlans,
        weeklyTrainingsCompleted: trainingsWeek.completed,
        weeklyTrainingsPlanned: trainingsWeek.total,
        createdExercises: createdExercises,
        horses: horses
            .map((horse) => ProfessionalHorse(id: horse.id, name: horse.name))
            .toList(growable: false),
        clients: clients
            .map((client) => ProfessionalClient(id: client.id, name: client.name))
            .toList(growable: false),
      );
}
