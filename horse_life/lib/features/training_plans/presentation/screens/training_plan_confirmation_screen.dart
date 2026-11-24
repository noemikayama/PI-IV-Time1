// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da sétima e última etapa do cadastro de planos de
// treinamento (Revise os dados), consolidando edição inline de título e
// objetivo, ajuste de datas, visualização do animal e dias planejados e
// submissão para createTrainingPlan.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';
import 'package:horse_life/core/widgets/app_item_list_widgets.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/editable_review_field.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../../exercises/data/models/trainer_linked_horse.dart';
import '../../application/controllers/training_plan_registration_controller.dart';
import '../../application/states/training_plan_registration_draft.dart';
import '../../data/repositories/training_plan_repository.dart';
import '../routes/training_plan_registration_flow_route.dart';
import '../widgets/training_plan_cards.dart';

typedef TrainingPlanConfirmationSubmittedCallback =
    void Function(TrainingPlanRegistrationDraft draft);

/// Etapa 7 de 7: Revisão final e submissão do cadastro de plano de treinamento.
class TrainingPlanConfirmationScreen extends StatefulWidget {
  const TrainingPlanConfirmationScreen({
    required this.draft,
    this.controller,
    this.onSubmitted,
    this.onCreated,
    this.onBack,
    super.key,
  });

  final TrainingPlanRegistrationDraft draft;
  final TrainingPlanRegistrationController? controller;
  final TrainingPlanConfirmationSubmittedCallback? onSubmitted;
  final VoidCallback? onCreated;
  final VoidCallback? onBack;

  @override
  State<TrainingPlanConfirmationScreen> createState() =>
      _TrainingPlanConfirmationScreenState();
}

class _TrainingPlanConfirmationScreenState
    extends State<TrainingPlanConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _objectiveController;
  final _titleFocus = FocusNode();
  final _objectiveFocus = FocusNode();
  final Set<_PlanReviewFieldId> _editingFields = {};

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.draft.title);
    _objectiveController = TextEditingController(text: widget.draft.objective);
    _startDate = widget.draft.startDate != null
        ? TrainingPlanRegistrationDraft.dateOnly(widget.draft.startDate!)
        : null;
    _endDate = widget.draft.endDate != null
        ? TrainingPlanRegistrationDraft.dateOnly(widget.draft.endDate!)
        : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _objectiveController.dispose();
    _titleFocus.dispose();
    _objectiveFocus.dispose();
    super.dispose();
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  void _toggleEditing(_PlanReviewFieldId field) {
    if (_editingFields.contains(field)) {
      setState(() => _editingFields.remove(field));
      _focusFor(field).unfocus();
      return;
    }

    setState(() => _editingFields.add(field));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusFor(field).requestFocus();
    });
  }

  FocusNode _focusFor(_PlanReviewFieldId field) {
    return switch (field) {
      _PlanReviewFieldId.title => _titleFocus,
      _PlanReviewFieldId.objective => _objectiveFocus,
    };
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

    final normalizedStart = TrainingPlanRegistrationDraft.dateOnly(picked);
    final maxEnd = TrainingPlanRegistrationDraft.maxEndDateFor(normalizedStart);
    setState(() {
      _startDate = normalizedStart;
      if (_endDate != null &&
          (_endDate!.isBefore(normalizedStart) || _endDate!.isAfter(maxEnd))) {
        _endDate = null;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final baseStart =
        _startDate ?? TrainingPlanRegistrationDraft.dateOnly(DateTime.now());
    final maxEnd = TrainingPlanRegistrationDraft.maxEndDateFor(baseStart);
    var initialDate = _endDate ?? baseStart;
    if (initialDate.isBefore(baseStart)) {
      initialDate = baseStart;
    } else if (initialDate.isAfter(maxEnd)) {
      initialDate = maxEnd;
    }

    final picked = await showAppDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: baseStart,
      lastDate: maxEnd,
      title: 'Data de fim',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _endDate = TrainingPlanRegistrationDraft.dateOnly(picked);
    });
  }

  TrainingPlanRegistrationDraft _buildUpdatedDraft() {
    return widget.draft
        .withTitle(_titleController.text.trim())
        .withObjective(_objectiveController.text.trim())
        .withStartDate(_startDate)
        .withEndDate(_endDate);
  }

  Future<void> _submitPlan() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final start = _startDate;
    if (start == null) {
      _showError('Selecione a data de início para continuar.');
      return;
    }
    final today = TrainingPlanRegistrationDraft.dateOnly(DateTime.now());
    if (start.isBefore(today)) {
      _showError('A data de início deve ser hoje ou uma data futura.');
      return;
    }

    final end = _endDate;
    if (end == null) {
      _showError('Selecione a data de fim para continuar.');
      return;
    }
    if (end.isBefore(start)) {
      _showError('A data de fim não pode ser anterior à data de início.');
      return;
    }
    if (end.isAfter(TrainingPlanRegistrationDraft.maxEndDateFor(start))) {
      _showError('O plano pode durar no máximo 12 meses.');
      return;
    }

    final updatedDraft = _buildUpdatedDraft();
    if (!updatedDraft.hasAnySelectedTraining) {
      _showError('Escolha um treino para pelo menos um dia da semana.');
      return;
    }
    if (!updatedDraft.hasAnyScheduledOccurrenceInPeriod) {
      _showError(
        'Nenhum dia do período escolhido tem treino. Ajuste as datas ou os dias da semana.',
      );
      return;
    }

    final onSubmitted = widget.onSubmitted;
    if (onSubmitted != null) {
      onSubmitted(updatedDraft);
      return;
    }

    final controller = widget.controller ?? TrainingPlanRegistrationController();
    setState(() => _isSubmitting = true);
    try {
      await controller.createTrainingPlan(draft: updatedDraft);
      if (!mounted) return;
      _finishRegistration();
    } on TrainingPlanRegistrationFailure catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } on Object {
      if (!mounted) return;
      _showError(
        'Não foi possível cadastrar o plano de treinamento. Tente novamente em instantes.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    AppSnackBar.show(
      context,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline_rounded,
      message: message,
    );
  }

  void _finishRegistration() {
    final onCreated = widget.onCreated;
    if (onCreated != null) {
      onCreated();
      return;
    }

    AppSnackBar.show(
      context,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline_rounded,
      message: 'Plano de treinamento cadastrado com sucesso.',
    );

    final navigator = Navigator.of(context);
    var foundEntryRoute = false;
    navigator.popUntil((route) {
      if (route.settings.name == TrainingPlanRegistrationFlowRoute.routeName) {
        foundEntryRoute = true;
        return true;
      }
      return route.isFirst;
    });
    if (foundEntryRoute && navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selectedWeekdayEntries = widget.draft.selectedWeekdayEntries;
    final horse = widget.draft.horse;

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
                              currentStep: 7,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Revise os dados',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Confira se todas as informações\n'
                              'estão corretas antes de continuar.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 44),
                            _buildEditableFieldsForm(),
                            const SizedBox(height: 28),
                            if (horse != null) ...[
                              _buildSelectedHorseSection(context, horse),
                              const SizedBox(height: 28),
                            ],
                            AppReviewSection(
                              title: 'Exercícios selecionados',
                              emptyMessage: 'Nenhum treinamento selecionado.',
                              spacing: 18,
                              children: [
                                for (final entry in selectedWeekdayEntries)
                                  TrainingPlanWeekdaySectionCard(
                                    key: ValueKey(
                                      'plan-review-weekday-${entry.key.name}',
                                    ),
                                    weekday: entry.key,
                                    training: entry.value,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'submit-training-plan-registration',
                              ),
                              label: 'Cadastrar plano',
                              showArrow: false,
                              isLoading: _isSubmitting,
                              onPressed: _submitPlan,
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

  Widget _buildEditableFieldsForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          EditableReviewField(
            fieldKey: const Key('training-plan-review-title'),
            label: 'Título',
            controller: _titleController,
            focusNode: _titleFocus,
            isEditing: _editingFields.contains(_PlanReviewFieldId.title),
            validator: _validateTitle,
            textInputAction: TextInputAction.next,
            onToggleEditing: () => _toggleEditing(_PlanReviewFieldId.title),
          ),
          const SizedBox(height: 24),
          EditableReviewField(
            fieldKey: const Key('training-plan-review-objective'),
            label: 'Objetivo',
            controller: _objectiveController,
            focusNode: _objectiveFocus,
            isEditing: _editingFields.contains(_PlanReviewFieldId.objective),
            minLines: 1,
            maxLines: 4,
            validator: _validateObjective,
            textInputAction: TextInputAction.done,
            onToggleEditing: () =>
                _toggleEditing(_PlanReviewFieldId.objective),
          ),
          const SizedBox(height: 24),
          AppDatePickerField(
            key: const Key('training-plan-review-start-date'),
            value: _startDate,
            labelText: 'Data de início',
            hintText: 'DD/MM/AAAA',
            onTap: _pickStartDate,
          ),
          const SizedBox(height: 24),
          AppDatePickerField(
            key: const Key('training-plan-review-end-date'),
            value: _endDate,
            labelText: 'Data de fim',
            hintText: 'DD/MM/AAAA',
            onTap: _pickEndDate,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedHorseSection(
    BuildContext context,
    TrainerLinkedHorse horse,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cavalo selecionado',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          key: const Key('training-plan-review-selected-horse'),
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: Color(0xFFE9E9E9),
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/black-head-horse.png',
                width: 28,
                height: 28,
                color: AppColors.blueSpruce,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  horse.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontSize: 19),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _PlanReviewFieldId { title, objective }
