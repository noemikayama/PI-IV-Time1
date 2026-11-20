// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Refatoração para delegar os cards e a consulta a widgets/tela
// próprios, mantendo apenas a navegação por perfil e os estados de feedback.
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação das telas de registro de execução para ambos os
// perfis, estado vazio do feedback e visualização de feedback registrado,
// reutilizando cards, modais, botões, tema e navegação compartilhados.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_info_dialog.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/gradient_button.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/features/feedback/data/models/training_execution_record.dart';
import 'package:horse_life/features/feedback/data/repositories/training_feedback_repository.dart';
import 'package:horse_life/features/feedback/presentation/widgets/training_execution_cards.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';

import 'feedback_read_screen.dart';
import 'feedback_registration_screen.dart';

/// Página compartilhada: as permissões e os rótulos dependem do perfil.
class TrainingExecutionRecordScreen extends StatefulWidget {
  const TrainingExecutionRecordScreen({
    required this.recordId,
    required this.audience,
    required this.repository,
    super.key,
  });

  final String recordId;
  final TrainingAgendaAudience audience;
  final TrainingFeedbackRepository repository;

  @override
  State<TrainingExecutionRecordScreen> createState() =>
      _TrainingExecutionRecordScreenState();
}

class _TrainingExecutionRecordScreenState
    extends State<TrainingExecutionRecordScreen> {
  TrainingExecutionRecord? get _record => widget.repository.findById(widget.recordId);
  bool get _isTrainer => widget.audience == TrainingAgendaAudience.trainer;

  Future<void> _accessFeedback() async {
    final record = _record;
    if (record == null) return;

    if (record.feedback == null && !_isTrainer) {
      await showAppInfoDialog(
        context,
        title: 'Nenhum feedback registrado',
        message: 'Seu treinador ainda não fez um feedback sobre a execução '
            'deste treino. Volte aqui quando ele estiver disponível.',
        dialogKey: const Key('feedback-empty-dialog'),
        confirmButtonKey: const Key('feedback-empty-confirm'),
      );
      return;
    }

    if (record.feedback == null) {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => FeedbackRegistrationScreen(
            recordId: record.id,
            repository: widget.repository,
          ),
        ),
      );
      if (!mounted) return;
      if (saved == true) {
        setState(() {});
        AppSnackBar.show(
          context,
          backgroundColor: AppColors.seaGreen,
          icon: Icons.check_circle_outline_rounded,
          message: 'Feedback registrado nesta sessão de demonstração.',
        );
      }
      return;
    }

    final destination = await Navigator.of(context).push<HomeNavigationDestination>(
      MaterialPageRoute<HomeNavigationDestination>(
        builder: (_) => FeedbackReadScreen(feedback: record.feedback!),
      ),
    );
    if (mounted && destination != null) {
      Navigator.of(context).pop(destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registro não encontrado')),
        body: const Center(child: Text('Não foi possível carregar esta execução.')),
      );
    }

    final theme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 26),
                  Text(
                    'Registro de execução',
                    textAlign: TextAlign.center,
                    style: theme.displayMedium?.copyWith(fontSize: 34),
                  ),
                  const SizedBox(height: 32),
                  TrainingExecutionDetailsCard(record: record, isTrainer: _isTrainer),
                  TrainingExecutionReportsCard(record: record),
                  const SizedBox(height: 3),
                  if (_isTrainer && record.feedback == null)
                    GradientButton(
                      label: 'Escrever feedback',
                      icon: Icons.rate_review_outlined,
                      onPressed: _accessFeedback,
                    )
                  else
                    AuthNextButton(
                      buttonKey: const Key('access-feedback-button'),
                      label: record.feedback == null
                          ? 'Acessar feedback'
                          : 'Visualizar feedback',
                      showArrow: false,
                      onPressed: _accessFeedback,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Prévia de demonstração: os reportes e feedbacks usam dados mockados.',
                    textAlign: TextAlign.center,
                    style: theme.bodySmall?.copyWith(color: AppColors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNavBar(
        selectedDestination: HomeNavigationDestination.trainings,
        onDestinationSelected: (destination) => Navigator.of(context).pop(destination),
      ),
    );
  }
}
