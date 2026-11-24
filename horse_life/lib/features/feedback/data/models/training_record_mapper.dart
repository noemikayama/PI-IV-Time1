// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Conversão do TrainingRecordView retornado pelas callables, sem dados fictícios.
// -----------------------------------------------------------------------------

import 'training_execution_record.dart';

/// Converte exclusivamente o contrato TrainingRecordView do backend.
abstract final class TrainingRecordMapper {
  static TrainingExecutionRecord fromResponse(Object? response) {
    // Separa os blocos do contrato remoto antes de montar o modelo usado pelas telas.
    final root = _map(response);
    final record = _map(root['registro']);
    final plan = _map(root['plano']);
    final training = _map(root['treinamento']);
    final horse = _map(root['cavalo']);
    final trainer = _map(root['treinador']);
    // Atleta, execução e feedback podem não existir no retorno da consulta.
    final athlete = root['atleta'] == null ? null : _map(root['atleta']);
    final execution = root['execucao'] == null ? null : _map(root['execucao']);
    final feedback = root['feedback'] == null ? null : _map(root['feedback']);
    final permissions = _map(root['permissoes']);
    // Valida o perfil e a permissão recebidos; respostas fora do contrato não são aceitas.
    final role = root['role'];
    if (role != 'TREINADOR' && role != 'RESPONSAVEL') {
      throw const FormatException('Perfil do registro inválido.');
    }
    final canRegister = permissions['podeRegistrarFeedback'];
    if (canRegister is! bool) {
      throw const FormatException('Permissão de feedback inválida.');
    }
    // Normaliza os valores do servidor sem preencher dados de execução inexistentes.
    final perception = _integer(execution?['percepcaoDesempenho']);
    return TrainingExecutionRecord(
      id: _string(record['id']),
      title: _string(training['titulo']),
      objective: _string(plan['objetivo']),
      durationMinutes: _integer(execution?['duracaoEfetiva']),
      executedAt: execution?['dataExecucao'] == null
          ? null
          : DateTime.parse(_string(execution!['dataExecucao'])),
      horseName: _string(horse['nome']),
      trainerName: _string(trainer['nome']),
      athleteName: athlete == null ? 'Não informado' : _string(athlete['nome']),
      completedExercises: _integer(execution?['exerciciosRealizados']),
      incompleteExercises: _integer(execution?['exerciciosNaoRealizados']),
      status: _string(record['status']),
      performancePerception: perception == null
          ? 'Não informada'
          : '$perception/10',
      difficultiesReport: _display(execution?['dificuldades'] as String?),
      observations: _display(_list(execution?['observacoes']).join('\n')),
      hasExecution: execution != null,
      // A escrita exige permissão, perfil de treinador, relato existente e ausência de feedback.
      canRegisterFeedback:
          canRegister &&
          role == 'TREINADOR' &&
          execution != null &&
          feedback == null,
      viewerIsTrainer: role == 'TREINADOR',
      // A data registrada pelo servidor é convertida para o horário local ao montar o feedback.
      feedback: feedback == null
          ? null
          : TrainingExecutionFeedback(
              createdAt: DateTime.parse(_string(feedback['data'])).toLocal(),
              comment: _string(feedback['comentario']),
              difficulties: _list(feedback['dificuldadesIdentificadas']),
              guidelines: _list(feedback['orientacoes']),
            ),
    );
  }

  // Os métodos auxiliares verificam os tipos recebidos antes de utilizá-los no modelo.
  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map) throw const FormatException('Registro inválido.');
    return Map<String, dynamic>.from(value);
  }

  static String _string(Object? value) {
    if (value is! String) throw const FormatException('Texto inválido.');
    return value;
  }

  // Aceita números inteiros e null, rejeitando valores fracionários ou de outros tipos.
  static int? _integer(Object? value) {
    if (value == null) return null;
    if (value is! num || value != value.roundToDouble()) {
      throw const FormatException('Número inválido.');
    }
    return value.toInt();
  }

  // Converte listas opcionais em listas de textos não modificáveis.
  static List<String> _list(Object? value) {
    if (value == null) return const [];
    if (value is! List) throw const FormatException('Lista inválida.');
    return List.unmodifiable(value.map(_string));
  }

  // Usa um rótulo de ausência para campos textuais nulos ou em branco.
  static String _display(String? value) =>
      value == null || value.trim().isEmpty ? 'Não informado' : value;
}
