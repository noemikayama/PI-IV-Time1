// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do catálogo estático mockado de treinamentos disponíveis
// para seleção nos dias da semana durante testes locais e de widget.
// -----------------------------------------------------------------------------

import '../models/training_plan_gallery_item.dart';

/// Catálogo local utilizado para testes isolados da galeria de treinamentos no
/// cadastro de planos.
abstract final class MockTrainingPlanGallery {
  static const List<TrainingPlanGalleryItem> trainings = [
    TrainingPlanGalleryItem(
      id: 'tr-1',
      code: 41,
      title: 'Aquecimento e flexibilidade',
      estimatedDurationMinutes: 30,
      exerciseNames: [
        'Aquecimento ao passo',
        'Alongamento de pescoço',
        'Círculos ao trote',
      ],
    ),
    TrainingPlanGalleryItem(
      id: 'tr-2',
      code: 42,
      title: 'Trabalho de transições',
      estimatedDurationMinutes: 45,
      exerciseNames: [
        'Aquecimento ao passo',
        'Transições trote-galope',
      ],
    ),
    TrainingPlanGalleryItem(
      id: 'tr-3',
      code: 43,
      title: 'Cavaletes e ritmo',
      estimatedDurationMinutes: 50,
      exerciseNames: [
        'Círculos ao trote',
        'Cavaletes elevados',
      ],
    ),
  ];
}
