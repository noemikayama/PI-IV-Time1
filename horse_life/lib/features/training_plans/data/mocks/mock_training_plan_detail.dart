// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do mock com dados padrão para visualização e edição de
// planos de treinamento enquanto a Cloud Function remota não estiver disponível.
// -----------------------------------------------------------------------------

import '../../../exercises/data/models/trainer_linked_horse.dart';
import '../models/training_plan_detail_data.dart';
import '../models/training_plan_weekday.dart';
import 'mock_training_plan_gallery.dart';

/// Provedor de dados mockados para o plano de treinamento.
abstract final class MockTrainingPlanDetail {
  /// Gera um plano de treinamento completo com dados padrão realistas para testes.
  static TrainingPlanDetailData buildDefault({
    String planId = 'mock_plan_id_123',
    String? horseId,
    String? horseName,
    String? trainerId,
    String? trainerName,
    bool isOwner = true,
    TrainingPlanStatus status = TrainingPlanStatus.active,
  }) {
    final trainings = MockTrainingPlanGallery.trainings;
    return TrainingPlanDetailData(
      id: planId,
      code: 682,
      title: 'Condicionamento para percursos de 1,00 m',
      objective: 'Ganhar condicionamento para percursos de 1,00 m',
      startDate: DateTime(2026, 11, 23),
      endDate: DateTime(2027, 1, 31),
      horse: TrainerLinkedHorse(
        id: horseId ?? 'horse-1',
        name: horseName ?? 'Calvino',
      ),
      trainerId: trainerId ?? 'trainer-1',
      trainerName: trainerName ?? 'Carlos Mendes',
      status: status,
      isOwner: isOwner,
      trainingsByDay: {
        TrainingPlanWeekday.monday: trainings[1], // Trabalho de transições
        TrainingPlanWeekday.wednesday: trainings[0], // Aquecimento e flexibilidade
        TrainingPlanWeekday.friday: trainings[2], // Cavaletes e ritmo
      },
    );
  }
}
