// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Rota de registro desacoplada do repositório mock por meio de
// contrato abstrato, mantendo adaptação mockada na entrada pela agenda.
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Criação da rota central de acesso à execução/feedback, com
// adaptação do item da agenda e injeção opcional do repositório mockado.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/features/feedback/data/repositories/mock_training_feedback_repository.dart';
import 'package:horse_life/features/feedback/data/repositories/training_feedback_repository.dart';
import 'package:horse_life/features/feedback/presentation/screens/training_execution_record_screen.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';

/// Encapsula a navegação, mantendo as Homes livres dos detalhes do cadastro.
abstract final class TrainingFeedbackRoute {
  static const routeName = '/trainings/execution/feedback';

  static Route<HomeNavigationDestination> fromAgenda({
    required TrainingAgendaEntry entry,
    required TrainingAgendaAudience audience,
    MockTrainingFeedbackRepository? repository,
  }) {
    final resolvedRepository = repository ?? MockTrainingFeedbackRepository.instance;
    final record = resolvedRepository.fromAgenda(entry);
    return forRecord(
      recordId: record.id,
      audience: audience,
      repository: resolvedRepository,
    );
  }

  static Route<HomeNavigationDestination> forRecord({
    required String recordId,
    required TrainingAgendaAudience audience,
    TrainingFeedbackRepository? repository,
  }) => MaterialPageRoute<HomeNavigationDestination>(
    settings: const RouteSettings(name: routeName),
    builder: (_) => TrainingExecutionRecordScreen(
      recordId: recordId,
      audience: audience,
      repository: repository ?? MockTrainingFeedbackRepository.instance,
    ),
  );
}
