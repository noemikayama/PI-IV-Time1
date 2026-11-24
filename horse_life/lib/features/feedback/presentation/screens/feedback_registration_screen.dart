// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Remoção da variável local de tema não utilizada na construção do
// formulário, eliminando o warning sem alterar a interface.
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Envio assíncrono, retorno confirmado pelo servidor e tratamento de falhas.
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Extração das regras de formulário para controller e das etapas
// visuais para widgets da feature, mantendo a revisão e os retornos da rota.
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação mockada do cadastro de feedback em quatro etapas,
// com validação, revisão editável, retorno e persistência apenas em memória.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';
import 'package:horse_life/features/feedback/application/controllers/feedback_registration_controller.dart';
import 'package:horse_life/features/feedback/data/repositories/training_feedback_repository.dart';
import 'package:horse_life/features/feedback/data/repositories/feedback_error_message.dart';
import 'package:horse_life/features/feedback/presentation/widgets/feedback_form_sections.dart';

/// Orquestra o formulário sem conhecer os detalhes de cada campo ou do mock.
class FeedbackRegistrationScreen extends StatefulWidget {
  const FeedbackRegistrationScreen({
    required this.recordId,
    required this.repository,
    super.key,
  });

  final String recordId;
  final TrainingFeedbackRepository repository;

  @override
  State<FeedbackRegistrationScreen> createState() =>
      _FeedbackRegistrationScreenState();
}

class _FeedbackRegistrationScreenState
    extends State<FeedbackRegistrationScreen> {
  // A chave valida o campo atual; o controlador mantém as respostas das etapas.
  final _formKey = GlobalKey<FormState>();
  final _flow = FeedbackRegistrationController();

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  // Impede saída durante a gravação e retorna à etapa anterior antes de fechar a tela.
  void _back() {
    if (_flow.isSaving) return;
    FocusScope.of(context).unfocus();
    if (!_flow.previous()) Navigator.of(context).pop();
  }

  // Avança somente com a etapa válida; na revisão, inicia o envio final.
  void _next() {
    FocusScope.of(context).unfocus();
    if (_flow.isReview) {
      _save();
    } else if (_formKey.currentState?.validate() ?? false) {
      _flow.next();
    }
  }

  void _edit(int index) {
    if (_flow.isSaving) return;
    _flow.edit(index);
    // Solicita foco depois que o campo voltará a ser montado na interface.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _flow.focusNodes[index].requestFocus();
    });
  }

  void _showError(String message) => AppSnackBar.show(
    context,
    backgroundColor: AppColors.error,
    icon: Icons.error_outline_rounded,
    message: message,
  );

  // Valida todas as respostas e evita disparar dois cadastros ao mesmo tempo.
  Future<void> _save() async {
    if (_flow.isSaving) return;
    final error = _flow.validateAll();
    if (error != null) {
      _showError(error);
      // A revisão pode apontar diretamente para o campo que precisa de ajuste.
      for (
        var index = 0;
        index < FeedbackRegistrationController.definitions.length;
        index++
      ) {
        if (_flow.validate(index, _flow.textControllers[index].text) != null) {
          _edit(index);
          break;
        }
      }
      return;
    }

    // Bloqueia novas ações enquanto o repositório processa a solicitação.
    _flow.setSaving(true);
    try {
      final updated = await widget.repository.registerFeedback(
        recordId: widget.recordId,
        feedback: _flow.buildFeedback(),
      );
      // Retorna o registro confirmado pelo repositório se a tela ainda estiver ativa.
      if (!mounted) return;
      Navigator.of(context).pop(updated);
      // Em caso de falha, mantém as respostas e libera outra tentativa.
    } catch (error) {
      if (!mounted) return;
      _showError(feedbackErrorMessage(error));
      _flow.setSaving(false);
    }
  }

  // Reconstrói a interface quando o controlador notifica mudanças de etapa ou gravação.
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _flow,
    builder: (context, _) {
      return PopScope(
        canPop: !_flow.isSaving && _flow.step == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 560,
                      minHeight: constraints.maxHeight - 50,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthHeader(onBack: _back),
                        const SizedBox(height: 42),
                        FormProgressIndicator(
                          currentStep: _flow.step + 1,
                          totalSteps: _flow.totalSteps,
                          segmentKeyPrefix: 'feedback-progress-segment',
                        ),
                        const SizedBox(height: 50),
                        // Alterna entre os componentes de preenchimento e de revisão sem duplicar o formulário.
                        if (_flow.isReview)
                          FeedbackReviewSection(
                            controller: _flow,
                            onEdit: _edit,
                          )
                        else
                          FeedbackInputSection(
                            formKey: _formKey,
                            controller: _flow,
                          ),
                        const SizedBox(height: 48),
                        AuthNextButton(
                          buttonKey: Key('feedback-continue-${_flow.step + 1}'),
                          label: _flow.isReview
                              ? 'Registrar feedback'
                              : 'Seguinte',
                          showArrow: !_flow.isReview,
                          isLoading: _flow.isSaving,
                          onPressed: _flow.isSaving ? null : _next,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
