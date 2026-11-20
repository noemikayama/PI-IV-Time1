// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da sexta etapa do cadastro de planos de treinamento
// (Seleção de treinamentos), exibindo os 7 dias da semana com seleção pela
// galeria ou criação direta de novo treinamento com retorno integrado.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../../trainings/application/controllers/training_registration_controller.dart';
import '../../../trainings/application/states/training_registration_draft.dart';
import '../../../trainings/data/repositories/training_registration_repository.dart';
import '../../../trainings/presentation/routes/training_registration_flow_route.dart';
import '../../application/controllers/training_plan_registration_controller.dart';
import '../../application/states/training_plan_registration_draft.dart';
import '../../data/models/training_plan_gallery_item.dart';
import '../../data/models/training_plan_weekday.dart';
import '../widgets/training_gallery_bottom_sheet.dart';
import '../widgets/training_plan_cards.dart';
import 'training_plan_confirmation_screen.dart';

typedef TrainingPlanTrainingsCallback =
    void Function(TrainingPlanRegistrationDraft draft);

/// Etapa 6 de 7: Associação de treinamentos aos dias da semana do plano.
class TrainingPlanTrainingsScreen extends StatefulWidget {
  const TrainingPlanTrainingsScreen({
    required this.draft,
    this.controller,
    this.trainingRegistrationController,
    this.onCreateTrainingForDay,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainingPlanRegistrationDraft draft;
  final TrainingPlanRegistrationController? controller;
  final TrainingRegistrationController? trainingRegistrationController;
  final ValueChanged<TrainingPlanWeekday>? onCreateTrainingForDay;
  final TrainingPlanTrainingsCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<TrainingPlanTrainingsScreen> createState() =>
      _TrainingPlanTrainingsScreenState();
}

class _TrainingPlanTrainingsScreenState
    extends State<TrainingPlanTrainingsScreen> {
  late final TrainingPlanRegistrationController _controller;
  late Map<TrainingPlanWeekday, TrainingPlanGalleryItem?> _trainingsByDay;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TrainingPlanRegistrationController();
    _trainingsByDay = Map.of(widget.draft.trainingsByDay);
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  Future<void> _openGalleryForDay(TrainingPlanWeekday weekday) async {
    final horseId = widget.draft.horse?.id ?? '';
    await showTrainingGalleryBottomSheet(
      context: context,
      controller: _controller,
      horseId: horseId,
      selectedTraining: _trainingsByDay[weekday],
      onSelectionChanged: (selectedTraining) {
        if (!mounted) return;
        setState(() {
          if (selectedTraining == null) {
            _trainingsByDay.remove(weekday);
          } else {
            _trainingsByDay[weekday] = selectedTraining;
          }
        });
      },
      onCreateTraining: () => _openTrainingCreationForDay(weekday),
    );
  }

  Future<void> _openTrainingCreationForDay(TrainingPlanWeekday weekday) async {
    final onCreateTrainingForDay = widget.onCreateTrainingForDay;
    if (onCreateTrainingForDay != null) {
      onCreateTrainingForDay(weekday);
      return;
    }

    TrainingRegistrationDraft? createdDraft;
    TrainingRegistrationResult? createdResult;
    final injectedController = widget.trainingRegistrationController;
    final routeController = injectedController?.withOnTrainingCreated((
      draft,
      result,
    ) {
      createdDraft = draft;
      createdResult = result;
      injectedController.onTrainingCreated?.call(draft, result);
    });

    await Navigator.push<void>(
      context,
      TrainingRegistrationFlowRoute.build(
        controller: routeController,
        onTrainingCreated: (draft, result) {
          createdDraft = draft;
          createdResult = result;
        },
      ),
    );

    if (!mounted || createdDraft == null) return;
    final item = _controller.recordCreatedTrainingFromDraft(
      createdDraft!,
      id: createdResult?.id,
      code: createdResult?.code,
    );
    setState(() {
      _trainingsByDay[weekday] = item;
    });
  }

  void _removeTrainingForDay(TrainingPlanWeekday weekday) {
    setState(() {
      _trainingsByDay.remove(weekday);
    });
  }

  void _continue() {
    final updatedDraft = widget.draft.withTrainingsByDay(_trainingsByDay);
    if (!updatedDraft.hasAnySelectedTraining) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Selecione um treinamento para pelo menos um dia da semana.',
      );
      return;
    }

    if (!updatedDraft.hasAnyScheduledOccurrenceInPeriod) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message:
            'Nenhum dia do período escolhido tem treino. Ajuste as datas ou os dias da semana.',
      );
      return;
    }

    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TrainingPlanConfirmationScreen(
          draft: updatedDraft,
          controller: _controller,
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
                              currentStep: 6,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Seleção de\ntreinamentos',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Para cada dia da semana,\n'
                              'selecione qual treinamento será\n'
                              'realizado ao longo do período\n'
                              'especificado.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 44),
                            for (
                              var index = 0;
                              index < TrainingPlanWeekday.values.length;
                              index++
                            ) ...[
                              TrainingPlanWeekdaySectionCard(
                                key: ValueKey(
                                  'weekday-section-${TrainingPlanWeekday.values[index].name}',
                                ),
                                weekday: TrainingPlanWeekday.values[index],
                                training:
                                    _trainingsByDay[TrainingPlanWeekday
                                        .values[index]],
                                onAddFromGallery: () => _openGalleryForDay(
                                  TrainingPlanWeekday.values[index],
                                ),
                                onCreateTraining: () =>
                                    _openTrainingCreationForDay(
                                      TrainingPlanWeekday.values[index],
                                    ),
                                onRemoveTraining: () => _removeTrainingForDay(
                                  TrainingPlanWeekday.values[index],
                                ),
                              ),
                              if (index < TrainingPlanWeekday.values.length - 1)
                                const SizedBox(height: 20),
                            ],
                            const SizedBox(height: 44),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-training-plan-trainings',
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
