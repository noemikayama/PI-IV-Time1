// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Inclusão do método toApiPayload() e getter isSpecific na hierarquia
// selada de drafts de exercícios para integração com a callable registerExercise.
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

  // Indica se o rascunho refere-se a um exercício direcionado a um cavalo específico.
  bool get isSpecific => this is SpecificExerciseRegistrationDraft;

  // Converte o rascunho em payload formatado conforme o contrato do backend.
  Map<String, Object?> toApiPayload();

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
  Map<String, Object?> toApiPayload() => <String, Object?>{
    'privacidade': 'GENERICO',
    'nome': name.trim(),
    'descricao': description.trim(),
    'orientacoes': guidelines
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false),
    'duracaoPadraoMinutos': defaultDurationMinutes ?? 0,
    'materiais': materials
        .map((material) => material.toJson())
        .toList(growable: false),
  };

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

  @override
  Map<String, Object?> toApiPayload() => <String, Object?>{
    'privacidade': 'ESPECIFICO',
    'cavaloId': horse.id.trim(),
    'nome': name.trim(),
    'descricao': description.trim(),
    'orientacoes': guidelines
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false),
    'duracaoPadraoMinutos': defaultDurationMinutes ?? 0,
    'materiais': materials
        .map((material) => material.toJson())
        .toList(growable: false),
  };

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
