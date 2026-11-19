// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da segunda etapa do cadastro de treinamentos (2 de 6)
// dedicada à descrição do objetivo da sessão de treinamento.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_multiline_text_form_field.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../application/controllers/training_registration_controller.dart';
import '../../application/states/training_registration_draft.dart';
import 'training_exercises_screen.dart';

typedef TrainingDescriptionCallback =
    void Function(TrainingRegistrationDraft draft);

/// Etapa 2 de 6: Descrição detalhada do treinamento.
class TrainingDescriptionScreen extends StatefulWidget {
  const TrainingDescriptionScreen({
    required this.draft,
    this.controller,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainingRegistrationDraft draft;
  final TrainingRegistrationController? controller;
  final TrainingDescriptionCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<TrainingDescriptionScreen> createState() =>
      _TrainingDescriptionScreenState();
}

class _TrainingDescriptionScreenState extends State<TrainingDescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.draft.description,
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateDescription(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Preencha este campo.';
    }
    if (trimmed.length > 1000) {
      return 'A descrição deve ter no máximo 1000 caracteres.';
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

    final updatedDraft = widget.draft.withDescription(
      _descriptionController.text.trim(),
    );
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TrainingExercisesScreen(
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
                              configuration: FormProgressConfiguration.training,
                              currentStep: 2,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Descrição do\ntreinamento',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Descreva detalhadamente o\nobjetivo deste treinamento.',
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
                                  'training-description-input',
                                ),
                                controller: _descriptionController,
                                hintText: 'Descrição',
                                minLines: 6,
                                maxLines: 8,
                                validator: _validateDescription,
                              ),
                            ),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-training-description',
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
