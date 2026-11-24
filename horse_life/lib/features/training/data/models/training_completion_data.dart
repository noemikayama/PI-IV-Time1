// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração do formulário com registerTrainingExecution, incluindo
// percepção numérica e omissão dos campos incompatíveis com treino não feito.
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação completa dos contratos, contadores e regras de
// serialização do formulário de conclusão do treinamento. Alinhamento do
// payload ao contrato de registerTrainingExecution.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos contratos de finalização do treino, com exercícios,
// duração, percepções do atleta e serialização do payload da callable.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

/// Resultado individual de um exercício no momento de finalizar o treino.
@immutable
class TrainingCompletionExercise {
  const TrainingCompletionExercise({
    required this.code,
    required this.completed,
  });

  /// Código estável esperado pela callable `registerTrainingExecution`.
  final String code;

  /// Indica se o atleta marcou o exercício como realizado.
  final bool completed;

  /// Converte o estado visual para os valores textuais aceitos pelo backend.
  Map<String, dynamic> toJson() => {
    'codigo': code,
    'realizacao': completed ? 'REALIZADO' : 'NAO_REALIZADO',
  };
}

/// Formulário completo enviado ao encerrar uma execução ativa.
@immutable
class TrainingCompletionInput {
  const TrainingCompletionInput({
    required this.recordId,
    required this.elapsed,
    required this.performancePerception,
    required this.difficulty,
    required this.notes,
    required this.exercises,
  });

  /// Registro da agenda que identifica a execução autorizada.
  final String recordId;

  /// Tempo medido desde o início até a confirmação do encerramento.
  final Duration elapsed;

  /// Nota de 1 a 10 exigida quando algum exercício foi realizado.
  final int? performancePerception;

  /// Dificuldades opcionais, omitidas quando nenhum exercício foi realizado.
  final String difficulty;

  /// Observação opcional enviada como lista por exigência do contrato remoto.
  final String notes;

  /// Situação final de cada exercício apresentado durante a execução.
  final List<TrainingCompletionExercise> exercises;

  /// Quantidade de exercícios marcados como realizados.
  int get completedCount => exercises.where((item) => item.completed).length;

  /// Quantidade restante, derivada para manter os contadores consistentes.
  int get incompleteCount => exercises.length - completedCount;

  /// Monta o payload remoto, removendo espaços e garantindo ao menos um minuto
  /// para execuções encerradas antes do primeiro minuto completo. Duração,
  /// percepção e dificuldades são omitidas quando todos os exercícios ficaram
  /// como não realizados, conforme a validação do backend.
  Map<String, dynamic> toJson() => {
    'registroId': recordId,
    if (completedCount > 0) ...{
      'duracaoEfetiva': elapsed.inSeconds == 0
          ? 1
          : (elapsed.inSeconds / 60).ceil(),
      if (performancePerception != null)
        'percepcaoDesempenho': performancePerception,
      if (difficulty.trim().isNotEmpty) 'dificuldades': difficulty.trim(),
    },
    'observacoes': notes.trim().isEmpty ? <String>[] : [notes.trim()],
    'exercicios': exercises
        .map((item) => item.toJson())
        .toList(growable: false),
  };
}

/// Confirmação mínima devolvida pela finalização no backend.
@immutable
class TrainingCompletionResult {
  const TrainingCompletionResult({required this.status});

  /// Estado textual persistido para o registro de treino.
  final String status;
}
