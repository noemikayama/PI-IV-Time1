// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Encadeamento da navegação padrão para TrainingPlanTrainingsScreen.
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da quinta etapa do cadastro de planos de treinamento
// (Data de fim), utilizando AppDatePickerField localizado em português e
// validando período mínimo e limite máximo de 12 meses conforme contrato.
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
import 'training_plan_trainings_screen.dart';

typedef TrainingPlanEndDateCallback =
    void Function(TrainingPlanRegistrationDraft draft);

/// Etapa 5 de 7: Seleção da data de término do plano de treinamento.
class TrainingPlanEndDateScreen extends StatefulWidget {
  const TrainingPlanEndDateScreen({
    required this.draft,
    this.controller,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainingPlanRegistrationDraft draft;
  final TrainingPlanRegistrationController? controller;
  final TrainingPlanEndDateCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<TrainingPlanEndDateScreen> createState() =>
      _TrainingPlanEndDateScreenState();
}

class _TrainingPlanEndDateScreenState extends State<TrainingPlanEndDateScreen> {
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _endDate = widget.draft.endDate != null
        ? TrainingPlanRegistrationDraft.dateOnly(widget.draft.endDate!)
        : null;
  }

  DateTime get _resolvedStartDate => TrainingPlanRegistrationDraft.dateOnly(
    widget.draft.startDate ?? DateTime.now(),
  );

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  Future<void> _pickEndDate() async {
    final firstDate = _resolvedStartDate;
    final lastDate = TrainingPlanRegistrationDraft.maxEndDateFor(firstDate);
    var initialDate = _endDate ?? firstDate;
    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final picked = await showAppDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      title: 'Data de fim',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _endDate = TrainingPlanRegistrationDraft.dateOnly(picked);
    });
  }

  void _continue() {
    final selectedDate = _endDate;
    if (selectedDate == null) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Selecione a data de fim para continuar.',
      );
      return;
    }

    final normalizedEnd = TrainingPlanRegistrationDraft.dateOnly(selectedDate);
    final startDate = _resolvedStartDate;
    if (normalizedEnd.isBefore(startDate)) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'A data de fim não pode ser anterior à data de início.',
      );
      return;
    }

    final maxEndDate = TrainingPlanRegistrationDraft.maxEndDateFor(startDate);
    if (normalizedEnd.isAfter(maxEndDate)) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'O plano pode durar no máximo 12 meses.',
      );
      return;
    }

    final updatedDraft = widget.draft.withEndDate(normalizedEnd);
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TrainingPlanTrainingsScreen(
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
                              currentStep: 5,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Data de fim',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Informe até quando este plano\n'
                              'deverá ser finalizado pelo atleta.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            AppDatePickerField(
                              key: const Key('training-plan-end-date-field'),
                              value: _endDate,
                              hintText: 'DD/MM/AAAA',
                              helpText: 'Data de fim',
                              onTap: _pickEndDate,
                            ),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-training-plan-end-date',
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
