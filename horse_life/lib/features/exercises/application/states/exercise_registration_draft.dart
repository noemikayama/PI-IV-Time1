// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da hierarquia selada e imutável de rascunhos do cadastro
// de exercícios, separando o fluxo genérico (7 etapas) do fluxo específico
// vinculado a um cavalo (8 etapas), seguindo o padrão de RegistrationDraft.
// -----------------------------------------------------------------------------

import '../../data/models/exercise_type.dart';
import '../../data/models/trainer_linked_horse.dart';
import 'exercise_material.dart';
import 'exercise_media.dart';

// Estado-base com os atributos compartilhados pelos dois fluxos de cadastro de
// exercícios. Suas subclasses determinam se há vínculo com um cavalo específico.
sealed class ExerciseRegistrationDraft {
  const ExerciseRegistrationDraft({
    this.name = '',
    this.description = '',
    this.guidelines = const [],
    this.defaultDurationMinutes,
    this.materials = const [],
    this.mediaItems = const [],
  });

  // Dados comuns preenchidos ao longo das etapas subsequentes do formulário.
  final String name;
  final String description;
  final List<String> guidelines;
  final int? defaultDurationMinutes;
  final List<ExerciseMaterial> materials;
  final List<ExerciseMedia> mediaItems;

  // Identifica o tipo do fluxo ativo para decisões de apresentação e progresso.
  ExerciseType get exerciseType;

  // Retorna uma nova instância preservando o subtipo concreto ao definir o nome.
  ExerciseRegistrationDraft withName(String name);

  // Retorna uma nova instância preservando o subtipo ao definir a descrição.
  ExerciseRegistrationDraft withDescription(String description);

  // Atualiza de forma imutável a coleção de orientações de execução.
  ExerciseRegistrationDraft withGuidelines(List<String> guidelines);

  // Atualiza a duração padrão estimada em minutos.
  ExerciseRegistrationDraft withDefaultDurationMinutes(
    int? defaultDurationMinutes,
  );

  // Atualiza de forma imutável a lista de materiais necessários.
  ExerciseRegistrationDraft withMaterials(List<ExerciseMaterial> materials);

  // Atualiza de forma imutável a lista de mídias auxiliares anexadas.
  ExerciseRegistrationDraft withMediaItems(List<ExerciseMedia> mediaItems);
}

// Estado exclusivo de exercícios genéricos (trilha de 7 etapas, sem cavalo).
final class GenericExerciseRegistrationDraft extends ExerciseRegistrationDraft {
  const GenericExerciseRegistrationDraft({
    super.name,
    super.description,
    super.guidelines,
    super.defaultDurationMinutes,
    super.materials,
    super.mediaItems,
  });

  @override
  ExerciseType get exerciseType => ExerciseType.generic;

  @override
  GenericExerciseRegistrationDraft withName(String name) {
    return GenericExerciseRegistrationDraft(
      name: name,
      description: description,
      guidelines: guidelines,
      defaultDurationMinutes: defaultDurationMinutes,
      materials: materials,
      mediaItems: mediaItems,
    );
  }

  @override
  GenericExerciseRegistrationDraft withDescription(String description) {
    return GenericExerciseRegistrationDraft(
      name: name,
      description: description,
      guidelines: guidelines,
      defaultDurationMinutes: defaultDurationMinutes,
      materials: materials,
      mediaItems: mediaItems,
    );
  }

  @override
  GenericExerciseRegistrationDraft withGuidelines(List<String> guidelines) {
    return GenericExerciseRegistrationDraft(
      name: name,
      description: description,
      guidelines: List.unmodifiable(guidelines),
      defaultDurationMinutes: defaultDurationMinutes,
      materials: materials,
      mediaItems: mediaItems,
    );
  }

  @override
  GenericExerciseRegistrationDraft withDefaultDurationMinutes(
    int? defaultDurationMinutes,
  ) {
    return GenericExerciseRegistrationDraft(
      name: name,
      description: description,
      guidelines: guidelines,
      defaultDurationMinutes: defaultDurationMinutes,
      materials: materials,
      mediaItems: mediaItems,
    );
  }

  @override
  GenericExerciseRegistrationDraft withMaterials(
    List<ExerciseMaterial> materials,
  ) {
    return GenericExerciseRegistrationDraft(
      name: name,
      description: description,
      guidelines: guidelines,
      defaultDurationMinutes: defaultDurationMinutes,
      materials: List.unmodifiable(materials),
      mediaItems: mediaItems,
    );
  }

  @override
  GenericExerciseRegistrationDraft withMediaItems(
    List<ExerciseMedia> mediaItems,
  ) {
    return GenericExerciseRegistrationDraft(
      name: name,
      description: description,
      guidelines: guidelines,
      defaultDurationMinutes: defaultDurationMinutes,
      materials: materials,
      mediaItems: List.unmodifiable(mediaItems),
    );
  }
}

// Estado exclusivo de exercícios específicos (trilha de 8 etapas, iniciada pela
// seleção obrigatória do cavalo vinculado ao treinador).
final class SpecificExerciseRegistrationDraft
    extends ExerciseRegistrationDraft {
  const SpecificExerciseRegistrationDraft({
    required this.horse,
    super.name,
    super.description,
    super.guidelines,
    super.defaultDurationMinutes,
    super.materials,
    super.mediaItems,
  });

  // Cavalo vinculado para o qual o exercício está sendo prescrito.
  final TrainerLinkedHorse horse;

  @override
  ExerciseType get exerciseType => ExerciseType.specific;

  // Permite substituir o cavalo selecionado preservando os demais campos.
  SpecificExerciseRegistrationDraft withHorse(TrainerLinkedHorse horse) {
    return SpecificExerciseRegistrationDraft(
      horse: horse,
      name: name,
      description: description,
      guidelines: guidelines,
      defaultDurationMinutes: defaultDurationMinutes,
      materials: materials,
      mediaItems: mediaItems,
    );
  }

  @override
  SpecificExerciseRegistrationDraft withName(String name) {
    return SpecificExerciseRegistrationDraft(
      horse: horse,
      name: name,
      description: description,
      guidelines: guidelines,
      defaultDurationMinutes: defaultDurationMinutes,
      materials: materials,
      mediaItems: mediaItems,
    );
  }

  @override
  SpecificExerciseRegistrationDraft withDescription(String description) {
    return SpecificExerciseRegistrationDraft(
      horse: horse,
      name: name,
      description: description,
      guidelines: guidelines,
      defaultDurationMinutes: defaultDurationMinutes,
      materials: materials,
      mediaItems: mediaItems,
    );
  }

  @override
  SpecificExerciseRegistrationDraft withGuidelines(List<String> guidelines) {
    return SpecificExerciseRegistrationDraft(
      horse: horse,
      name: name,
      description: description,
      guidelines: List.unmodifiable(guidelines),
      defaultDurationMinutes: defaultDurationMinutes,
      materials: materials,
      mediaItems: mediaItems,
    );
  }

  @override
  SpecificExerciseRegistrationDraft withDefaultDurationMinutes(
    int? defaultDurationMinutes,
  ) {
    return SpecificExerciseRegistrationDraft(
      horse: horse,
      name: name,
      description: description,
      guidelines: guidelines,
      defaultDurationMinutes: defaultDurationMinutes,
      materials: materials,
      mediaItems: mediaItems,
    );
  }

  @override
  SpecificExerciseRegistrationDraft withMaterials(
    List<ExerciseMaterial> materials,
  ) {
    return SpecificExerciseRegistrationDraft(
      horse: horse,
      name: name,
      description: description,
      guidelines: guidelines,
      defaultDurationMinutes: defaultDurationMinutes,
      materials: List.unmodifiable(materials),
      mediaItems: mediaItems,
    );
  }

  @override
  SpecificExerciseRegistrationDraft withMediaItems(
    List<ExerciseMedia> mediaItems,
  ) {
    return SpecificExerciseRegistrationDraft(
      horse: horse,
      name: name,
      description: description,
      guidelines: guidelines,
      defaultDurationMinutes: defaultDurationMinutes,
      materials: materials,
      mediaItems: List.unmodifiable(mediaItems),
    );
  }
}
