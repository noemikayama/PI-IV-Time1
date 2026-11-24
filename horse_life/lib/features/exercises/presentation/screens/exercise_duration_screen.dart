// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Validação da duração entre 1 e 240 minutos conforme contrato do backend.
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adoção do componente unificado FormProgressIndicator proveniente
// de core/widgets.
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da etapa de duração padrão do exercício em minutos, com
// restrição estrita a caracteres numéricos e adaptação automática ao fluxo
// genérico (etapa 4 de 7) ou específico (etapa 5 de 8).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/app_text_form_field.dart';
import '../../../../core/widgets/form_progress_indicator.dart';
import '../../../authentication/presentation/widgets/auth_header.dart';
import '../../../authentication/presentation/widgets/auth_next_button.dart';
import '../../application/controllers/exercise_registration_controller.dart';
import '../../application/states/exercise_registration_draft.dart';
import 'exercise_materials_screen.dart';

typedef ExerciseDurationCallback =
    void Function(ExerciseRegistrationDraft draft);

// Etapa dedicada à duração padrão estimada (em minutos) para a execução do
// exercício, operando como etapa 4 de 7 (genérico) ou etapa 5 de 8 (específico).
class ExerciseDurationScreen extends StatefulWidget {
  const ExerciseDurationScreen({
    required this.draft,
    this.registrationController,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final ExerciseRegistrationDraft draft;
  final ExerciseRegistrationController? registrationController;
  final ExerciseDurationCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<ExerciseDurationScreen> createState() => _ExerciseDurationScreenState();
}

class _ExerciseDurationScreenState extends State<ExerciseDurationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _durationController;

  FormProgressConfiguration get _progressConfiguration =>
      switch (widget.draft) {
        GenericExerciseRegistrationDraft() =>
          FormProgressConfiguration.genericExercise,
        SpecificExerciseRegistrationDraft() =>
          FormProgressConfiguration.specificExercise,
      };

  int get _currentStep => switch (widget.draft) {
    GenericExerciseRegistrationDraft() => 4,
    SpecificExerciseRegistrationDraft() => 5,
  };

  @override
  void initState() {
    super.initState();
    final initialMinutes = widget.draft.defaultDurationMinutes;
    _durationController = TextEditingController(
      text: initialMinutes != null ? initialMinutes.toString() : '',
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  // Garante que o tempo informado seja um inteiro positivo entre 1 e 240 minutos.
  String? _validateDuration(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Preencha este campo.';
    }
    final minutes = int.tryParse(trimmed);
    if (minutes == null || minutes <= 0 || minutes > 240) {
      return 'Informe uma duração válida entre 1 e 240 minutos.';
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

  // Converte os minutos validados e atualiza o draft preservando o fluxo ativo.
  void _continue() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final minutes = int.parse(_durationController.text.trim());
    final updatedDraft = widget.draft.withDefaultDurationMinutes(minutes);

    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ExerciseMaterialsScreen(
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
                            FormProgressIndicator(
                              configuration: _progressConfiguration,
                              currentStep: _currentStep,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Duração padrão',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Informe quanto tempo (em\n'
                              'minutos) esse exercício costuma\n'
                              'levar para ser executado.',
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
                                controller: _durationController,
                                hintText: 'Tempo',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textInputAction: TextInputAction.done,
                                validator: _validateDuration,
                                onFieldSubmitted: (_) => _continue(),
                              ),
                            ),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-exercise-duration',
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
