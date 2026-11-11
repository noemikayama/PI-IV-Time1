// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Encadeamento da navegação da etapa de nome para a etapa de
// descrição detalhada do exercício.
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da etapa de definição do nome do exercício, parametrizada
// para operar como etapa 1 de 7 no fluxo genérico ou como etapa 2 de 8 no
// fluxo específico após a seleção do cavalo vinculado.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_text_form_field.dart';
import '../../../authentication/presentation/widgets/auth_header.dart';
import '../../../authentication/presentation/widgets/auth_next_button.dart';
import '../../application/controllers/exercise_registration_controller.dart';
import '../../application/states/exercise_registration_draft.dart';
import '../../data/models/exercise_type.dart';
import '../widgets/exercise_progress_indicator.dart';
import 'exercise_description_screen.dart';

typedef ExerciseNameCallback =
    void Function(ExerciseRegistrationDraft draft);

// Etapa compartilhável de definição do nome do exercício, ajustando o total de
// segmentos e o passo ativo conforme o tipo de exercício selecionado.
class ExerciseNameScreen extends StatefulWidget {
  const ExerciseNameScreen.generic({
    GenericExerciseRegistrationDraft? this.draft,
    this.registrationController,
    this.onContinue,
    this.onBack,
    super.key,
  }) : exerciseType = ExerciseType.generic,
       progressConfiguration = ExerciseProgressConfiguration.generic,
       currentStep = 1;

  const ExerciseNameScreen.specific({
    required SpecificExerciseRegistrationDraft this.draft,
    this.registrationController,
    this.onContinue,
    this.onBack,
    super.key,
  }) : exerciseType = ExerciseType.specific,
       progressConfiguration = ExerciseProgressConfiguration.specific,
       currentStep = 2;

  final ExerciseType exerciseType;
  final ExerciseProgressConfiguration progressConfiguration;
  final int currentStep;
  final ExerciseRegistrationDraft? draft;
  final ExerciseRegistrationController? registrationController;
  final ExerciseNameCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<ExerciseNameScreen> createState() => _ExerciseNameScreenState();
}

class _ExerciseNameScreenState extends State<ExerciseNameScreen> {
  // Estado e controlador do campo de nome do exercício.
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.draft?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Impede o avanço com o campo de nome vazio ou composto apenas por espaços.
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Preencha este campo.';
    }
    return null;
  }

  // Retorno injetável com fallback para o Navigator.
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  // Normaliza o nome e atualiza o draft preservando o tipo do exercício.
  void _continue() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final updatedDraft = switch (widget.draft) {
      final SpecificExerciseRegistrationDraft specific => specific.withName(
        name,
      ),
      final GenericExerciseRegistrationDraft generic => generic.withName(name),
      null => GenericExerciseRegistrationDraft(name: name),
    };

    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ExerciseDescriptionScreen(
          draft: updatedDraft,
          registrationController: widget.registrationController,
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
                            ExerciseProgressIndicator(
                              configuration: widget.progressConfiguration,
                              currentStep: widget.currentStep,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Nome do exercício',
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
                                controller: _nameController,
                                hintText: 'Nome',
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.done,
                                validator: _validateName,
                                onFieldSubmitted: (_) => _continue(),
                              ),
                            ),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key('continue-exercise-name'),
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
