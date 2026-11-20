// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Suporte ao parâmetro opcional onTrainingCreated para retorno
// integrado ao fluxo de planos de treinamento após criar um novo treino.
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Definição de routeName para retorno ao finalizar o fluxo e
// injeção de FirebaseTrainingRegistrationRepository no controlador.
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da rota de entrada do fluxo de cadastro de treinamentos,
// compondo o controlador com os repositórios Firebase da galeria e de cavalos.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../exercises/data/repositories/firebase_trainer_linked_horse_repository.dart';
import '../../../exercises/data/repositories/trainer_linked_horse_repository.dart';
import '../../application/controllers/training_registration_controller.dart';
import '../../application/states/training_registration_draft.dart';
import '../../data/repositories/firebase_training_exercise_gallery_repository.dart';
import '../../data/repositories/firebase_training_registration_repository.dart';
import '../../data/repositories/training_exercise_gallery_repository.dart';
import '../../data/repositories/training_registration_repository.dart';
import '../screens/training_title_screen.dart';

/// Concentra a composição e abertura do cadastro de treinamentos fora da Home e
/// da barra lateral do treinador.
abstract final class TrainingRegistrationFlowRoute {
  static const routeName = '/trainings/register';

  static Route<void> build({
    TrainingRegistrationController? controller,
    TrainingExerciseGalleryRepository? galleryRepository,
    TrainerLinkedHorseRepository? horseRepository,
    TrainingRegistrationRepository? registrationRepository,
    void Function(
      TrainingRegistrationDraft draft,
      TrainingRegistrationResult? result,
    )?
    onTrainingCreated,
  }) {
    final resolvedGalleryRepository =
        galleryRepository ?? const FirebaseTrainingExerciseGalleryRepository();
    final resolvedHorseRepository =
        horseRepository ?? const FirebaseTrainerLinkedHorseRepository();
    final resolvedRegistrationRepository =
        registrationRepository ??
        const FirebaseTrainingRegistrationRepository();
    final resolvedController =
        controller?.withOnTrainingCreated(
          onTrainingCreated ?? controller.onTrainingCreated,
        ) ??
        TrainingRegistrationController(
          galleryRepository: resolvedGalleryRepository,
          horseRepository: resolvedHorseRepository,
          registrationRepository: resolvedRegistrationRepository,
          onTrainingCreated: onTrainingCreated,
        );

    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: routeName),
      builder: (context) => TrainingTitleScreen(controller: resolvedController),
    );
  }
}
