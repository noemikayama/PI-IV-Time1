// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Redirecionamento direto das barras inferiores da execução e do
// feedback, sem devolver destinos por pop.
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Consulta assíncrona, permissões reais e atualização pelo retorno da gravação.
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
import 'package:horse_life/features/feedback/data/repositories/feedback_error_message.dart';
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
  TrainingExecutionRecord? _record;
  Object? _error;
  bool _loading = true;
  // Prioriza o perfil retornado pela API e usa o perfil de entrada quando ele não foi informado.
  bool get _isTrainer =>
      _record?.viewerIsTrainer ??
      (widget.audience == TrainingAgendaAudience.trainer);
  // A ação de cadastro depende também da permissão de escrita do registro.
  bool get _canWrite => _isTrainer && (_record?.canRegisterFeedback ?? false);

  @override
  void initState() {
    super.initState();
    _load();
  }

  // Consulta o registro e mantém estados de carregamento e erro para permitir nova tentativa.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final record = await widget.repository.findById(widget.recordId);
      // Evita atualizar o estado caso a tela tenha sido fechada durante a consulta.
      if (!mounted) return;
      setState(() {
        _record = record;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _accessFeedback() async {
    final record = _record;
    if (record == null) return;

    // Sem feedback e sem permissão de cadastro, apresenta o aviso em vez de abrir o formulário.
    if (record.feedback == null && !_canWrite) {
      await showAppInfoDialog(
        context,
        title: 'Nenhum feedback registrado',
        message: _isTrainer
            ? 'O feedback ainda não está disponível para este registro.'
            : 'Seu treinador ainda não fez um feedback sobre a execução deste treino. Volte aqui quando ele estiver disponível.',
        dialogKey: const Key('feedback-empty-dialog'),
        confirmButtonKey: const Key('feedback-empty-confirm'),
      );
      return;
    }

    // Abre o cadastro para o registro ainda não avaliado quando a escrita está permitida.
    if (record.feedback == null) {
      final saved = await Navigator.of(context).push<TrainingExecutionRecord>(
        MaterialPageRoute<TrainingExecutionRecord>(
          builder: (_) => FeedbackRegistrationScreen(
            recordId: record.id,
            repository: widget.repository,
          ),
        ),
      );
      if (!mounted) return;
      // Atualiza a tela usando o registro devolvido após a gravação, sem recriar o feedback localmente.
      if (saved != null) {
        setState(() {
          _record = saved;
        });
        AppSnackBar.show(
          context,
          backgroundColor: AppColors.seaGreen,
          icon: Icons.check_circle_outline_rounded,
          message: 'Feedback registrado com sucesso.',
        );
      }
      return;
    }

    // Se já existir feedback, abre a consulta e propaga a escolha de navegação inferior.
    final destination = await Navigator.of(context)
        .push<HomeNavigationDestination>(
          MaterialPageRoute<HomeNavigationDestination>(
            builder: (_) => FeedbackReadScreen(feedback: record.feedback!),
          ),
        );
    if (mounted && destination != null) {
      navigateToHomeDestination(context, destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    // Renderiza os estados de carregamento, falha ou conteúdo de forma separada.
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registro de execução')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || record == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registro não encontrado')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error == null
                    ? 'Registro de treino não encontrado.'
                    : feedbackErrorMessage(_error!),
              ),
              TextButton(
                onPressed: _load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
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
                  TrainingExecutionDetailsCard(
                    record: record,
                    isTrainer: _isTrainer,
                  ),
                  // Os reportes são exibidos somente quando o registro possui relato de execução.
                  if (record.hasExecution)
                    TrainingExecutionReportsCard(record: record)
                  else
                    const Text(
                      'Ainda não há relato de execução para este treino.',
                    ),
                  const SizedBox(height: 3),
                  if (_canWrite && record.feedback == null)
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
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNavBar(
        selectedDestination: HomeNavigationDestination.trainings,
        onDestinationSelected: (destination) =>
            navigateToHomeDestination(context, destination),
      ),
    );
  }
}
