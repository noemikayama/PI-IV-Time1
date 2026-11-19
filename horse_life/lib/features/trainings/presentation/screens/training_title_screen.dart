// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da primeira etapa do cadastro de treinamentos (1 de 6)
// dedicada à definição do título da sessão de treinamento.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_text_form_field.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../application/controllers/training_registration_controller.dart';
import '../../application/states/training_registration_draft.dart';
import 'training_description_screen.dart';

typedef TrainingTitleCallback = void Function(TrainingRegistrationDraft draft);

/// Etapa 1 de 6: Definição do título do treinamento.
class TrainingTitleScreen extends StatefulWidget {
  const TrainingTitleScreen({
    this.draft = const TrainingRegistrationDraft(),
    this.controller,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainingRegistrationDraft draft;
  final TrainingRegistrationController? controller;
  final TrainingTitleCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<TrainingTitleScreen> createState() => _TrainingTitleScreenState();
}

class _TrainingTitleScreenState extends State<TrainingTitleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.draft.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Preencha este campo.';
    }
    if (trimmed.length < 3 || trimmed.length > 80) {
      return 'O título deve ter entre 3 e 80 caracteres.';
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

    final updatedDraft = widget.draft.withTitle(_titleController.text.trim());
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TrainingDescriptionScreen(
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
                              currentStep: 1,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Título do treinamento',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Dê um nome coerente e de fácil\ncompreensão.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            Form(
                              key: _formKey,
                              child: AppTextFormField(
                                controller: _titleController,
                                hintText: 'Título',
                                keyboardType: TextInputType.text,
                                textCapitalization: TextCapitalization.sentences,
                                textInputAction: TextInputAction.done,
                                validator: _validateTitle,
                                onFieldSubmitted: (_) => _continue(),
                              ),
                            ),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key('continue-training-title'),
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
