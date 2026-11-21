// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação da fábrica de resposta e dos limites verificados em
// cada cenário do repositório e da conversão de permissões.
//
// Data: 20/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes do repositório da agenda para validar payload,
// conversão dos perfis e tratamento de respostas inválidas da callable.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';
import 'package:horse_life/features/training/data/repositories/training_agenda_repository.dart';

void main() {
  // Monta o menor contrato completo aceito pela conversão. O papel altera os
  // campos sensíveis e as permissões exatamente como a callable de produção.
  Map<String, dynamic> response({String role = 'RESPONSAVEL'}) => {
    'role': role,
    'hoje': '2026-11-20',
    'semana': {'dataInicio': '2026-11-16', 'dataFim': '2026-11-22'},
    'planosAtivos': {
      'quantidade': 1,
      'planos': [
        {
          'id': 'plano-1',
          'titulo': 'Condicionamento',
          'nomeCavalo': 'Trovão',
          if (role == 'RESPONSAVEL') 'nomeTreinador': 'Ana',
          'dataInicio': '2026-11-01',
          'dataFim': '2026-12-31',
        },
      ],
    },
    'dias': List.generate(7, (index) => <String, dynamic>{}),
    'treinamentos': [
      {
        'id': 'registro-atleta',
        'nomeTreinamento': 'Transições',
        'nomeCavalo': 'Trovão',
        'nomePlano': 'Condicionamento',
        'data': '2026-11-20',
        'status': 'PLANEJADO',
      },
      {
        'id': 'registro-proprietario',
        'nomeTreinamento': 'Solo',
        'nomeCavalo': 'Lua',
        'nomePlano': 'Retorno',
        'data': '2026-11-20',
        'status': 'PARCIAL',
      },
    ],
    'treinosDoDia': {
      'total': 2,
      'treinos': [
        {
          'id': 'registro-atleta',
          'nomeTreinamento': 'Transições',
          'nomeCavalo': 'Trovão',
          if (role == 'RESPONSAVEL') 'nomeTreinador': 'Ana',
          'duracaoEstimadaMinutos': 45,
          'nomePlano': 'Condicionamento',
          'role': role == 'TREINADOR' ? 'TREINADOR' : 'ATLETA',
        },
        {
          'id': 'registro-proprietario',
          'nomeTreinamento': 'Solo',
          'nomeCavalo': 'Lua',
          if (role == 'RESPONSAVEL') 'nomeTreinador': 'Ana',
          'duracaoEstimadaMinutos': 30,
          'nomePlano': 'Retorno',
          'role': role == 'TREINADOR' ? 'TREINADOR' : 'PROPRIETARIO',
        },
      ],
    },
    'historicoExecucoes': [
      {
        'id': 'registro-antigo',
        'nomeTreinamento': 'Alongamento',
        'nomeCavalo': 'Trovão',
        'data': '2026-11-18',
        'status': 'REALIZADO',
      },
    ],
  };

  // Valida a fronteira do repositório: payload enviado e resposta convertida.
  test('envia a semana no formato do contrato e converte a resposta', () async {
    Map<String, dynamic>? sentPayload;
    final repository = FirebaseTrainingAgendaRepository(
      callable: (payload) async {
        sentPayload = payload;
        return response();
      },
    );

    final agenda = await repository.fetchAgenda(date: DateTime(2026, 11, 26));

    expect(sentPayload, {'data': '2026-11-26'});
    expect(agenda.audience, TrainingAgendaAudience.guardian);
    expect(agenda.activePlansCount, 1);
    expect(agenda.weekTrainings, hasLength(2));
    expect(agenda.history.single.status, TrainingAgendaStatus.completed);
  });

  // Garante que a permissão venha do vínculo informado pelo backend.
  test('somente ATLETA recebe a ação de iniciar treino', () {
    final agenda = TrainingAgendaData.fromJson(response());

    expect(agenda.todayTrainings.first.action, TrainingAgendaAction.start);
    expect(agenda.todayTrainings.last.action, TrainingAgendaAction.view);
    expect(agenda.todayTrainings.last.status, TrainingAgendaStatus.partial);
  });

  // O profissional consulta treinos, mas não inicia uma execução de atleta.
  test('treinador nunca recebe a ação de iniciar treino', () {
    final agenda = TrainingAgendaData.fromJson(response(role: 'TREINADOR'));

    expect(agenda.audience, TrainingAgendaAudience.trainer);
    expect(
      agenda.todayTrainings.map((training) => training.action),
      everyElement(TrainingAgendaAction.view),
    );
    expect(agenda.plans.single.trainerName, isEmpty);
  });
}
