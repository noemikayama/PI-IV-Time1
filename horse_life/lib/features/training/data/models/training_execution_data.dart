// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação completa dos contratos de referência, exercícios,
// materiais, mídias e dados consolidados da execução.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos contratos da execução de treino, incluindo referência,
// exercícios, materiais, mídias, orientações e estado de finalização.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';

/// Identidade e contexto necessários para localizar um treino agendado.
@immutable
class TrainingExecutionReference {
  const TrainingExecutionReference({
    required this.recordId,
    required this.planId,
    required this.title,
    required this.date,
    required this.durationMinutes,
    required this.status,
  });

  /// Identificador do registro de agenda que será finalizado posteriormente.
  final String recordId;

  /// Identificador do plano usado para resolver o código do treino.
  final String planId;

  /// Título e data diferenciam o treino dentro do cronograma do plano.
  final String title;
  final DateTime date;

  /// Duração exibida enquanto os detalhes completos ainda são carregados.
  final int durationMinutes;

  /// Estado conhecido pela agenda no momento da navegação.
  final TrainingAgendaStatus status;

  /// Impede iniciar novamente execuções totais ou parciais já registradas.
  bool get isFinished =>
      status == TrainingAgendaStatus.completed ||
      status == TrainingAgendaStatus.partial;
}

/// Exercício enriquecido com os recursos necessários para sua execução.
@immutable
class TrainingExecutionExercise {
  const TrainingExecutionExercise({
    required this.code,
    required this.name,
    required this.durationMinutes,
    required this.description,
    this.guidelines = const [],
    this.materials = const [],
    this.media = const [],
  });

  /// Código usado para buscar orientações, materiais e mídias adicionais.
  final String code;

  /// Conteúdo principal retornado pelos detalhes do treinamento.
  final String name;

  /// Duração prevista e instrução resumida do exercício.
  final int durationMinutes;
  final String description;

  /// Recursos opcionais carregados separadamente por exercício.
  final List<String> guidelines;
  final List<TrainingExerciseMaterial> materials;
  final List<TrainingExerciseMedia> media;

  /// Preserva o conteúdo principal ao incorporar recursos complementares.
  TrainingExecutionExercise copyWith({
    List<String>? guidelines,
    List<TrainingExerciseMaterial>? materials,
    List<TrainingExerciseMedia>? media,
  }) => TrainingExecutionExercise(
    code: code,
    name: name,
    durationMinutes: durationMinutes,
    description: description,
    guidelines: guidelines ?? this.guidelines,
    materials: materials ?? this.materials,
    media: media ?? this.media,
  );
}

/// Material e quantidade necessários para executar um exercício.
@immutable
class TrainingExerciseMaterial {
  const TrainingExerciseMaterial({
    required this.description,
    required this.quantity,
  });

  /// Nome ou descrição apresentada ao atleta.
  final String description;

  /// Quantidade necessária para a execução.
  final int quantity;
}

/// Tipos de mídia suportados pelo carrossel da execução ativa.
enum TrainingExerciseMediaType { image, video }

/// Recurso remoto associado a um exercício.
@immutable
class TrainingExerciseMedia {
  const TrainingExerciseMedia({required this.url, required this.type});

  /// URL, normalmente assinada, retornada pelo backend.
  final String url;

  /// Define se o recurso deve ser exibido como imagem ou vídeo.
  final TrainingExerciseMediaType type;
}

/// Treinamento consolidado consumido pelas telas de detalhes e execução ativa.
@immutable
class TrainingExecutionData {
  const TrainingExecutionData({
    required this.recordId,
    required this.title,
    required this.durationMinutes,
    required this.description,
    required this.guidelines,
    required this.exercises,
    required this.isFinished,
  });

  /// Registro que conecta a execução ao item original da agenda.
  final String recordId;

  /// Informações gerais exibidas antes e durante o treino.
  final String title;
  final int durationMinutes;
  final String description;
  final List<String> guidelines;

  /// Exercícios enriquecidos na ordem definida pelo treinamento.
  final List<TrainingExecutionExercise> exercises;

  /// Indica se a tela deve impedir uma nova execução.
  final bool isFinished;
}
