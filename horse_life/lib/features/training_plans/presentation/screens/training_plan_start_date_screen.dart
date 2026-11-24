// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da quarta etapa do cadastro de planos de treinamento
// (Data de início), utilizando AppDatePickerField localizado em português,
// validando data igual ou posterior a hoje e navegando para a data de fim.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../application/controllers/training_plan_registration_controller.dart';
import '../../application/states/training_plan_registration_draft.dart';
import 'training_plan_end_date_screen.dart';

typedef TrainingPlanStartDateCallback =
    void Function(TrainingPlanRegistrationDraft draft);

/// Etapa 4 de 7: Seleção da data de início do plano de treinamento.
class TrainingPlanStartDateScreen extends StatefulWidget {
  const TrainingPlanStartDateScreen({
    required this.draft,
    this.controller,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainingPlanRegistrationDraft draft;
  final TrainingPlanRegistrationController? controller;
  final TrainingPlanStartDateCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<TrainingPlanStartDateScreen> createState() =>
      _TrainingPlanStartDateScreenState();
}

class _TrainingPlanStartDateScreenState
    extends State<TrainingPlanStartDateScreen> {
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.draft.startDate != null
        ? TrainingPlanRegistrationDraft.dateOnly(widget.draft.startDate!)
        : null;
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  Future<void> _pickStartDate() async {
    final today = TrainingPlanRegistrationDraft.dateOnly(DateTime.now());
    final lastDate = DateTime(today.year + 5, 12, 31);
    var initialDate = _startDate ?? today;
    if (initialDate.isBefore(today)) {
      initialDate = today;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final picked = await showAppDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: lastDate,
      title: 'Data de início',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _startDate = TrainingPlanRegistrationDraft.dateOnly(picked);
    });
  }

  void _continue() {
    final selectedDate = _startDate;
    if (selectedDate == null) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Selecione a data de início para continuar.',
      );
      return;
    }

    final today = TrainingPlanRegistrationDraft.dateOnly(DateTime.now());
    final normalizedStart = TrainingPlanRegistrationDraft.dateOnly(selectedDate);
    if (normalizedStart.isBefore(today)) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'A data de início deve ser hoje ou uma data futura.',
      );
      return;
    }

    final updatedDraft = widget.draft.withStartDate(normalizedStart);
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TrainingPlanEndDateScreen(
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
                              currentStep: 4,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Data de início',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Informe quando este plano deverá\n'
                              'ser iniciado pelo atleta.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            AppDatePickerField(
                              key: const Key('training-plan-start-date-field'),
                              value: _startDate,
                              hintText: 'DD/MM/AAAA',
                              helpText: 'Data de início',
                              onTap: _pickStartDate,
                            ),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-training-plan-start-date',
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
