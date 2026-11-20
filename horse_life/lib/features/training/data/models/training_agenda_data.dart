// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
