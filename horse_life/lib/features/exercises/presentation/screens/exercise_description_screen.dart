// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Validação do limite de até 1000 caracteres na descrição do exercício.
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adoção dos widgets compartilhados FormProgressIndicator e
// AppMultilineTextFormField provenientes de core/widgets.
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da etapa de descrição detalhada do exercício, operando
// como etapa 2 de 7 no fluxo genérico ou etapa 3 de 8 no fluxo específico e
// encadeando a navegação para a tela de orientações.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_multiline_text_form_field.dart';
import '../../../../core/widgets/form_progress_indicator.dart';
import '../../../authentication/presentation/widgets/auth_header.dart';
import '../../../authentication/presentation/widgets/auth_next_button.dart';
import '../../application/controllers/exercise_registration_controller.dart';
import '../../application/states/exercise_registration_draft.dart';
import 'exercise_guidelines_screen.dart';

typedef ExerciseDescriptionCallback =
    void Function(ExerciseRegistrationDraft draft);

// Etapa de descrição detalhada do exercício, adaptando o indicador de progresso
// para 7 etapas (genérico, passo 2) ou 8 etapas (específico, passo 3).
class ExerciseDescriptionScreen extends StatefulWidget {
  const ExerciseDescriptionScreen({
    required this.draft,
    this.registrationController,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final ExerciseRegistrationDraft draft;
  final ExerciseRegistrationController? registrationController;
  final ExerciseDescriptionCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<ExerciseDescriptionScreen> createState() =>
      _ExerciseDescriptionScreenState();
}

class _ExerciseDescriptionScreenState extends State<ExerciseDescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;

  FormProgressConfiguration get _progressConfiguration =>
      switch (widget.draft) {
        GenericExerciseRegistrationDraft() =>
          FormProgressConfiguration.genericExercise,
        SpecificExerciseRegistrationDraft() =>
          FormProgressConfiguration.specificExercise,
      };

  int get _currentStep => switch (widget.draft) {
    GenericExerciseRegistrationDraft() => 2,
    SpecificExerciseRegistrationDraft() => 3,
  };

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

  // Atualiza a descrição no draft e avança para a etapa de orientações.
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
        builder: (context) => ExerciseGuidelinesScreen(
          draft: updatedDraft,
          registrationController: widget.registrationController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

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
                            FormProgressIndicator(
                              configuration: _progressConfiguration,
                              currentStep: _currentStep,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Descrição do exercício',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Descreva detalhadamente o que é\no exercício.',
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
                                  'exercise-description-input',
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
                                'continue-exercise-description',
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
