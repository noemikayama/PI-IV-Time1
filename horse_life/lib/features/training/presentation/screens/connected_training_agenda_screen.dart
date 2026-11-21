// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Correção da troca e da repetição de carga da semana para manter o
// callback de setState síncrono, sem retornar Future; documentação do estado,
// da adaptação dos dados e do tratamento dos erros da callable.
//
// Data: 20/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do contêiner conectado da agenda, com carregamento por
// semana, adaptação dos dados da API, progresso e tratamento de erros.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';
import 'package:horse_life/features/training/data/repositories/training_agenda_repository.dart';
import 'package:horse_life/features/training/presentation/screens/training_agenda_screen.dart';

/// Contêiner que mantém a agenda sincronizada com o backend por semana.
///
/// Preserva os últimos dados enquanto uma nova semana é carregada e traduz a
/// resposta do repositório para a API de apresentação de [TrainingAgendaScreen].
class ConnectedTrainingAgendaScreen extends StatefulWidget {
  const ConnectedTrainingAgendaScreen({
    required this.loader,
    this.onViewPlans,
    this.onViewPlan,
    this.onStartTraining,
    this.onViewTraining,
    this.onViewHistory,
    super.key,
  });

  /// Fonte substituível que consulta a semana inicial e as semanas navegadas.
  final TrainingAgendaLoader loader;

  /// Ações encaminhadas à tela visual sem acoplá-la ao backend.
  final VoidCallback? onViewPlans;
  final ValueChanged<TrainingAgendaPlan>? onViewPlan;
  final TrainingAgendaEntryCallback? onStartTraining;
  final TrainingAgendaEntryCallback? onViewTraining;
  final TrainingAgendaEntryCallback? onViewHistory;

  @override
  State<ConnectedTrainingAgendaScreen> createState() =>
      _ConnectedTrainingAgendaScreenState();
}

class _ConnectedTrainingAgendaScreenState
    extends State<ConnectedTrainingAgendaScreen> {
  // Requisição observada pelo FutureBuilder e último resultado mantido durante
  // uma atualização, evitando substituir toda a agenda por um spinner.
  late Future<TrainingAgendaData> _future;
  TrainingAgendaData? _current;

  @override
  void initState() {
    super.initState();
    _future = widget.loader.fetchAgenda();
  }

  @override
  void didUpdateWidget(covariant ConnectedTrainingAgendaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loader != widget.loader) {
      _current = null;
      _future = widget.loader.fetchAgenda();
    }
  }

  // Inicia a operação antes do setState para que seu callback permaneça
  // estritamente síncrono, conforme o contrato do Flutter.
  void _loadWeek(DateTime date) {
    final future = widget.loader.fetchAgenda(date: date);
    setState(() {
      _future = future;
    });
  }

  // Repete a semana visível quando já existem dados; após falha inicial, deixa
  // o backend escolher a semana corrente ao receber uma data nula.
  void _retry() {
    final date = _current?.weekStart;
    final future = widget.loader.fetchAgenda(date: date);
    setState(() {
      _future = future;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TrainingAgendaData>(
      future: _future,
      initialData: _current,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final data = snapshot.data!;
          _current = data;

          // A lista sob o calendário reutiliza o componente visual de planos,
          // mas representa os treinamentos consultivos retornados para a semana.
          final calendarPlans = data.weekTrainings
              .map(
                (training) => TrainingAgendaPlan(
                  id: training.id,
                  trainingName: training.title,
                  horseName: training.horseName,
                  trainerName: training.trainerName,
                  planName: training.planName,
                  date: training.date,
                  status: training.status,
                ),
              )
              .toList(growable: false);
          return Stack(
            children: [
              TrainingAgendaScreen(
                key: ValueKey<String>(
                  '${data.weekStart.year}-${data.weekStart.month}-${data.weekStart.day}',
                ),
                audience: data.audience,
                activePlansCount: data.activePlansCount,
                plans: data.plans,
                trainings: data.weekTrainings,
                calendarPlans: calendarPlans,
                todayTrainings: data.todayTrainings,
                history: data.history,
                initialDate:
                    data.today.isBefore(data.weekStart) ||
                        data.today.isAfter(data.weekEnd)
                    ? data.weekStart
                    : data.today,
                onViewPlans: widget.onViewPlans,
                onViewPlan: (plan) {
                  for (final training in data.weekTrainings) {
                    if (training.id == plan.id) {
                      widget.onViewTraining?.call(training);
                      return;
                    }
                  }
                  widget.onViewPlan?.call(plan);
                },
                onStartTraining: widget.onStartTraining,
                onViewTraining: widget.onViewTraining,
                onViewHistory: widget.onViewHistory,
                onWeekChanged: _loadWeek,
              ),
              if (snapshot.connectionState != ConnectionState.done)
                const Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(child: LinearProgressIndicator()),
                ),
            ],
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return _AgendaLoadError(error: snapshot.error, onRetry: _retry);
      },
    );
  }
}

// Traduz somente erros com ação específica para o usuário; falhas técnicas não
// reconhecidas recebem uma mensagem neutra e a mesma opção de nova tentativa.
class _AgendaLoadError extends StatelessWidget {
  const _AgendaLoadError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (error) {
      FirebaseFunctionsException(:final code)
          when code == 'permission-denied' =>
        'Seu perfil não tem permissão para acessar esta agenda.',
      FirebaseFunctionsException(:final code) when code == 'unauthenticated' =>
        'Sua sessão expirou. Entre novamente para acessar a agenda.',
      _ => 'Não foi possível carregar a agenda.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
