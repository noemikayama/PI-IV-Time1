// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Preservação do status dos treinos do dia a partir de
// historicoExecucoes (ou status próprio do item) ao navegar entre semanas no
// calendário.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos segmentos da resposta completa, das regras de
// conversão de status e da validação defensiva dos campos recebidos da API.
//
// Data: 20/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão do contrato completo retornado por getTrainingAgenda,
// conversão do JSON da API e validação dos campos de semana, planos e treinos.
//
// Data: 18/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos contratos imutáveis da agenda, com públicos, ações,
// planos e estados de execução convertidos a partir da API. Documentação dos
// contratos, campos e regra de conversão da API.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

// Situação de um treino na agenda, independentemente do valor usado na API.
enum TrainingAgendaStatus { planned, completed, partial, notCompleted }

// Ação disponibilizada ao usuário para um treino agendado.
enum TrainingAgendaAction { start, view }

// Perfil que está consultando a agenda e define os dados visíveis na tela.
enum TrainingAgendaAudience { guardian, trainer }

// Treino exibido em um dia da agenda.
//
// Este contrato desacopla a apresentação dos modelos específicos das Homes
// de responsável e treinador.
@immutable
class TrainingAgendaEntry {
  const TrainingAgendaEntry({
    required this.id,
    required this.title,
    required this.horseName,
    required this.trainerName,
    required this.planName,
    required this.date,
    required this.durationMinutes,
    required this.status,
    required this.action,
  });

  // Identificador estável usado para localizar o treino na fonte original.
  final String id;

  // Nome do treino prescrito.
  final String title;

  // Cavalo ao qual o treino pertence.
  final String horseName;

  // Profissional responsável pela prescrição.
  final String trainerName;

  // Plano que agrupa o treino.
  final String planName;

  // Dia em que o treino deve ser exibido.
  final DateTime date;

  // Duração prevista do treino, em minutos.
  final int durationMinutes;

  // Estado atual normalizado para uso pela interface.
  final TrainingAgendaStatus status;

  // Operação permitida ao público que está visualizando o item.
  final TrainingAgendaAction action;

  // Indica se existe uma execução total ou parcial para o histórico.
  bool get wasExecuted =>
      status == TrainingAgendaStatus.completed ||
      status == TrainingAgendaStatus.partial;
}

// Resumo de um plano ativo apresentado na semana e no modal de planos.
@immutable
class TrainingAgendaPlan {
  const TrainingAgendaPlan({
    required this.id,
    required this.trainingName,
    required this.horseName,
    required this.trainerName,
    required this.planName,
    required this.date,
    required this.status,
  });

  // Identificador estável do plano adaptado.
  final String id;

  // Treino usado para representar o plano na agenda.
  final String trainingName;

  // Cavalo associado ao plano.
  final String horseName;

  // Profissional responsável pelo plano.
  final String trainerName;

  // Nome de exibição do plano.
  final String planName;

  // Data usada para posicionar o plano na semana.
  final DateTime date;

  // Situação normalizada do treino representativo.
  final TrainingAgendaStatus status;
}

// Resposta completa da callable getTrainingAgenda. A separação entre semana,
// hoje e histórico espelha o backend e evita que a interface deduza permissões.
@immutable
class TrainingAgendaData {
  const TrainingAgendaData({
    required this.audience,
    required this.today,
    required this.weekStart,
    required this.weekEnd,
    required this.activePlansCount,
    required this.plans,
    required this.weekTrainings,
    required this.todayTrainings,
    required this.history,
  });

  // Perfil autorizado que consultou a agenda.
  final TrainingAgendaAudience audience;

  // Data de referência calculada pelo backend.
  final DateTime today;

  // Limites inclusivos da semana retornada.
  final DateTime weekStart;
  final DateTime weekEnd;

  // Resumo e detalhes dos planos ativos visíveis para o perfil.
  final int activePlansCount;
  final List<TrainingAgendaPlan> plans;

  // Itens do calendário semanal, treinos acionáveis do dia e execuções
  // históricas são mantidos separados conforme o contrato da callable.
  final List<TrainingAgendaEntry> weekTrainings;
  final List<TrainingAgendaEntry> todayTrainings;
  final List<TrainingAgendaEntry> history;

  // Converte a resposta sem confiar em casts implícitos. Campos estruturais
  // ausentes ou inválidos produzem FormatException com o caminho do campo.
  factory TrainingAgendaData.fromJson(Map<String, dynamic> json) {
    final audience = switch (json['role']) {
      'TREINADOR' => TrainingAgendaAudience.trainer,
      'RESPONSAVEL' => TrainingAgendaAudience.guardian,
      _ => throw const FormatException('Campo role inválido.'),
    };
    final today = _agendaDate(json['hoje'], 'hoje');
    final week = _agendaMap(json['semana'], 'semana');
    final plansPayload = _agendaMap(json['planosAtivos'], 'planosAtivos');
    final weekPayload = _agendaList(json['treinamentos'], 'treinamentos');

    final weekTrainings = weekPayload
        .map((value) {
          final item = _agendaMap(value, 'treinamentos[]');
          return TrainingAgendaEntry(
            id: _agendaString(item['id'], 'treinamentos[].id'),
            title: _agendaString(
              item['nomeTreinamento'],
              'treinamentos[].nomeTreinamento',
            ),
            horseName: _agendaString(
              item['nomeCavalo'],
              'treinamentos[].nomeCavalo',
            ),
            trainerName: '',
            planName: _agendaString(
              item['nomePlano'],
              'treinamentos[].nomePlano',
            ),
            date: _agendaDate(item['data'], 'treinamentos[].data'),
            durationMinutes: 0,
            status: trainingAgendaStatusFromApi(item['status'] as String?),
            // A lista semanal é apenas consultiva para os dois perfis.
            action: TrainingAgendaAction.view,
          );
        })
        .toList(growable: false);

    final history =
        _agendaList(json['historicoExecucoes'], 'historicoExecucoes')
            .map((value) {
              final item = _agendaMap(value, 'historicoExecucoes[]');
              return TrainingAgendaEntry(
                id: _agendaString(item['id'], 'historicoExecucoes[].id'),
                title: _agendaString(
                  item['nomeTreinamento'],
                  'historicoExecucoes[].nomeTreinamento',
                ),
                horseName: _agendaString(
                  item['nomeCavalo'],
                  'historicoExecucoes[].nomeCavalo',
                ),
                trainerName: '',
                planName: '',
                date: _agendaDate(item['data'], 'historicoExecucoes[].data'),
                durationMinutes: 0,
                status: trainingAgendaStatusFromApi(item['status'] as String?),
                action: TrainingAgendaAction.view,
              );
            })
            .toList(growable: false);

    final statusById = <String, TrainingAgendaStatus>{
      for (final item in history) item.id: item.status,
      for (final training in weekTrainings) training.id: training.status,
    };
    final todayPayload = _agendaMap(json['treinosDoDia'], 'treinosDoDia');
    final todayTrainings =
        _agendaList(todayPayload['treinos'], 'treinosDoDia.treinos')
            .map((value) {
              final item = _agendaMap(value, 'treinosDoDia.treinos[]');
              final id = _agendaString(item['id'], 'treinosDoDia.treinos[].id');
              final role = _agendaString(
                item['role'],
                'treinosDoDia.treinos[].role',
              );
              return TrainingAgendaEntry(
                id: id,
                title: _agendaString(
                  item['nomeTreinamento'],
                  'treinosDoDia.treinos[].nomeTreinamento',
                ),
                horseName: _agendaString(
                  item['nomeCavalo'],
                  'treinosDoDia.treinos[].nomeCavalo',
                ),
                trainerName: item['nomeTreinador'] as String? ?? '',
                planName: _agendaString(
                  item['nomePlano'],
                  'treinosDoDia.treinos[].nomePlano',
                ),
                date: today,
                durationMinutes:
                    (item['duracaoEstimadaMinutos'] as num?)?.toInt() ?? 0,
                status: item['status'] is String
                    ? trainingAgendaStatusFromApi(item['status'] as String)
                    : (statusById[id] ?? TrainingAgendaStatus.planned),
                // Somente o papel ATLETA é autorizado pelo backend a iniciar.
                action: role == 'ATLETA'
                    ? TrainingAgendaAction.start
                    : TrainingAgendaAction.view,
              );
            })
            .toList(growable: false);

    final plans = _agendaList(plansPayload['planos'], 'planosAtivos.planos')
        .map((value) {
          final item = _agendaMap(value, 'planosAtivos.planos[]');
          final title = _agendaString(
            item['titulo'],
            'planosAtivos.planos[].titulo',
          );
          return TrainingAgendaPlan(
            id: _agendaString(item['id'], 'planosAtivos.planos[].id'),
            trainingName: title,
            horseName: _agendaString(
              item['nomeCavalo'],
              'planosAtivos.planos[].nomeCavalo',
            ),
            trainerName: item['nomeTreinador'] as String? ?? '',
            planName: title,
            date: _agendaDate(
              item['dataInicio'],
              'planosAtivos.planos[].dataInicio',
            ),
            status: TrainingAgendaStatus.planned,
          );
        })
        .toList(growable: false);

    return TrainingAgendaData(
      audience: audience,
      today: today,
      weekStart: _agendaDate(week['dataInicio'], 'semana.dataInicio'),
      weekEnd: _agendaDate(week['dataFim'], 'semana.dataFim'),
      activePlansCount:
          (plansPayload['quantidade'] as num?)?.toInt() ?? plans.length,
      plans: plans,
      weekTrainings: weekTrainings,
      todayTrainings: todayTrainings,
      history: history,
    );
  }
}

// Converte o estado textual da API para o domínio visual da agenda.
//
// Valores ausentes ou ainda desconhecidos são tratados como planejados para
// que novos estados do backend não sejam exibidos como execução concluída.
TrainingAgendaStatus trainingAgendaStatusFromApi(String? value) {
  return switch (value) {
    'REALIZADO' => TrainingAgendaStatus.completed,
    'PARCIAL' => TrainingAgendaStatus.partial,
    'NAO_REALIZADO' => TrainingAgendaStatus.notCompleted,
    _ => TrainingAgendaStatus.planned,
  };
}

// Converte o estado visual para o vocabulário aceito pelos modelos legados das
// Homes. Esta função não envia dados à callable.
String trainingAgendaStatusToApi(TrainingAgendaStatus value) => switch (value) {
  TrainingAgendaStatus.completed => 'REALIZADO',
  TrainingAgendaStatus.partial => 'PARCIAL',
  TrainingAgendaStatus.notCompleted => 'NAO_REALIZADO',
  TrainingAgendaStatus.planned => 'PLANEJADO',
};

// Validadores pequenos mantêm mensagens de erro uniformes durante a conversão.
Map<String, dynamic> _agendaMap(Object? value, String field) {
  if (value is! Map) throw FormatException('Campo $field inválido.');
  return Map<String, dynamic>.from(value);
}

List<dynamic> _agendaList(Object? value, String field) {
  if (value is! List) throw FormatException('Campo $field inválido.');
  return value;
}

String _agendaString(Object? value, String field) {
  if (value is! String) throw FormatException('Campo $field inválido.');
  return value;
}

// Aceita somente datas civis ISO no formato AAAA-MM-DD e rejeita normalizações
// automáticas, como 31 de fevereiro convertido pelo DateTime.
DateTime _agendaDate(Object? value, String field) {
  final text = _agendaString(value, field);
  final parts = text.split('-');
  if (parts.length != 3) throw FormatException('Campo $field inválido.');
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) {
    throw FormatException('Campo $field inválido.');
  }
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    throw FormatException('Campo $field inválido.');
  }
  return date;
}
