// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da segunda etapa do cadastro de planos de treinamento
// (Objetivo do plano), com validação obrigatória de 1 a 1000 caracteres e
// navegação para a etapa de seleção do animal.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_multiline_text_form_field.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../application/controllers/training_plan_registration_controller.dart';
import '../../application/states/training_plan_registration_draft.dart';
import 'training_plan_horse_screen.dart';

typedef TrainingPlanObjectiveCallback =
    void Function(TrainingPlanRegistrationDraft draft);

/// Etapa 2 de 7: Descrição detalhada do objetivo do plano de treinamento.
class TrainingPlanObjectiveScreen extends StatefulWidget {
  const TrainingPlanObjectiveScreen({
    required this.draft,
    this.controller,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainingPlanRegistrationDraft draft;
  final TrainingPlanRegistrationController? controller;
  final TrainingPlanObjectiveCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<TrainingPlanObjectiveScreen> createState() =>
      _TrainingPlanObjectiveScreenState();
}

class _TrainingPlanObjectiveScreenState
    extends State<TrainingPlanObjectiveScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _objectiveController;

  @override
  void initState() {
    super.initState();
    _objectiveController = TextEditingController(text: widget.draft.objective);
  }

  @override
  void dispose() {
    _objectiveController.dispose();
    super.dispose();
  }

  String? _validateObjective(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Preencha este campo.';
    }
    if (trimmed.length > 1000) {
      return 'O objetivo deve ter no máximo 1000 caracteres.';
    }
    return null;
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  void _continue() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final updatedDraft = widget.draft.withObjective(
      _objectiveController.text.trim(),
    );
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TrainingPlanHorseScreen(
          draft: updatedDraft,
          controller: widget.controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 18, 32, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(onBack: _goBack),
                    const SizedBox(height: 44),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const FormProgressIndicator(
                              configuration:
                                  FormProgressConfiguration.trainingPlan,
                              currentStep: 2,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Objetivo do plano',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Descreva detalhadamente o\n'
                              'objetivo deste plano de treinos.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 46),
                            Form(
                              key: _formKey,
                              child: AppMultilineTextFormField(
                                fieldKey: const Key(
                                  'training-plan-objective-input',
                                ),
                                controller: _objectiveController,
                                hintText: 'Objetivo',
                                minLines: 6,
                                maxLines: 8,
                                validator: _validateObjective,
                              ),
                            ),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-training-plan-objective',
                              ),
                              onPressed: _continue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
