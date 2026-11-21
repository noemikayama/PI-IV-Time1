// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Validação impedindo que a duração estimada seja menor do que a
// soma da duração dos exercícios selecionados.
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da quinta etapa do cadastro de treinamentos (5 de 6),
// exibindo a soma informativa do tempo dos exercícios selecionados via
// sumExerciseDurations (com fallback local) e coletando a duração estimada
// entre 1 e 480 minutos.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_text_form_field.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../application/controllers/training_registration_controller.dart';
import '../../application/states/training_registration_draft.dart';
import 'training_confirmation_screen.dart';

typedef TrainingDurationCallback =
    void Function(TrainingRegistrationDraft draft);

/// Etapa 5 de 6: Definição da duração estimada total do treinamento (em minutos).
class TrainingDurationScreen extends StatefulWidget {
  const TrainingDurationScreen({
    required this.draft,
    this.controller,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainingRegistrationDraft draft;
  final TrainingRegistrationController? controller;
  final TrainingDurationCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<TrainingDurationScreen> createState() => _TrainingDurationScreenState();
}

class _TrainingDurationScreenState extends State<TrainingDurationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _durationController;
  late int _totalExercisesMinutes;

  @override
  void initState() {
    super.initState();
    final initialMinutes = widget.draft.estimatedDurationMinutes;
    _durationController = TextEditingController(
      text: initialMinutes != null ? initialMinutes.toString() : '',
    );
    _totalExercisesMinutes = widget.draft.totalExercisesDurationMinutes;
    _refreshTotalExercisesDuration();
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _refreshTotalExercisesDuration() async {
    final controller = widget.controller;
    if (controller == null) return;

    final totalMinutes = await controller.sumExerciseDurations(
      widget.draft.selectedExercises,
    );
    if (!mounted) return;
    if (totalMinutes != _totalExercisesMinutes) {
      setState(() {
        _totalExercisesMinutes = totalMinutes;
      });
    }
  }

  String? _validateDuration(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Preencha este campo.';
    }
    final minutes = int.tryParse(trimmed);
    if (minutes == null || minutes < 1 || minutes > 480) {
      return 'Informe uma duração válida entre 1 e 480 minutos.';
    }
    if (minutes < _totalExercisesMinutes) {
      return 'A duração não pode ser menor que a soma dos exercícios ($_totalExercisesMinutes min).';
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

    final minutes = int.parse(_durationController.text.trim());
    final updatedDraft = widget.draft.withEstimatedDurationMinutes(minutes);

    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TrainingConfirmationScreen(
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
                              currentStep: 5,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Duração estimada',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Informe quanto tempo (em\n'
                              'minutos) esta sessão pode levar\n'
                              '(incluindo descansos, tempo de\n'
                              'troca entre os exercícios, etc.).',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 36),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: AppColors.seaGreen,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text.rich(
                                    key: const Key(
                                      'selected-exercises-total-duration',
                                    ),
                                    TextSpan(
                                      style: textTheme.bodyLarge?.copyWith(
                                        fontSize: 18,
                                        color: AppColors.text,
                                        height: 1.25,
                                      ),
                                      children: [
                                        const TextSpan(
                                          text:
                                              'Tempo total dos exercícios selecionados: ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        TextSpan(
                                          text: '$_totalExercisesMinutes min',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            Form(
                              key: _formKey,
                              child: AppTextFormField(
                                key: const Key('training-duration-input'),
                                controller: _durationController,
                                hintText: 'Duração',
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
                                'continue-training-duration',
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
