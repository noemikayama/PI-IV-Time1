// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Adiciona à seleção somente treinamentos confirmados pelo servidor.
//
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Usa dependências reais por padrão e conserva injeção para testes.
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela de edição de planos de treinamento com
// reutilização dos campos de revisão, seletor de datas, dropdown de cavalo
// e programação semanal com galeria ou criação direta de treinamentos.
// -----------------------------------------------------------------------------

import 'package:horse_life/features/exercises/data/repositories/firebase_trainer_linked_horse_repository.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';
import 'package:horse_life/core/widgets/app_dropdown_field.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/editable_review_field.dart';

import '../../../exercises/data/models/trainer_linked_horse.dart';
import '../../../exercises/data/repositories/trainer_linked_horse_repository.dart';
import '../../../trainings/application/controllers/training_registration_controller.dart';
import '../../../trainings/application/states/training_registration_draft.dart';
import '../../../trainings/data/repositories/training_registration_repository.dart';
import '../../../trainings/presentation/routes/training_registration_flow_route.dart';
import '../../application/controllers/training_plan_registration_controller.dart';
import '../../application/states/training_plan_registration_draft.dart';
import '../../data/models/training_plan_detail_data.dart';
import '../../data/models/training_plan_gallery_item.dart';
import '../../data/models/training_plan_weekday.dart';
import '../widgets/training_gallery_bottom_sheet.dart';
import '../widgets/training_plan_cards.dart';

/// Formulário completo de edição de um plano de treinamento existente.
class TrainingPlanEditScreen extends StatefulWidget {
  const TrainingPlanEditScreen({
    required this.plan,
    this.controller,
    this.horseRepository = const FirebaseTrainerLinkedHorseRepository(),
    this.trainingRegistrationController,
    this.initialHorses,
    this.onCreateTrainingForDay,
    this.onSaved,
    this.onBack,
    super.key,
  });

  final TrainingPlanDetailData plan;
  final TrainingPlanRegistrationController? controller;
  final TrainerLinkedHorseRepository horseRepository;
  final TrainingRegistrationController? trainingRegistrationController;
  final List<TrainerLinkedHorse>? initialHorses;
  final ValueChanged<TrainingPlanWeekday>? onCreateTrainingForDay;
  final ValueChanged<TrainingPlanUpdate>? onSaved;
  final VoidCallback? onBack;

  @override
  State<TrainingPlanEditScreen> createState() => _TrainingPlanEditScreenState();
}

class _TrainingPlanEditScreenState extends State<TrainingPlanEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TrainingPlanRegistrationController _controller;
  late final TextEditingController _titleController;
  late final TextEditingController _objectiveController;
  final _titleFocus = FocusNode();
  final _objectiveFocus = FocusNode();
  final Set<_PlanEditFieldId> _editingFields = {};

  late DateTime _startDate;
  DateTime? _endDate;
  late TrainerLinkedHorse _selectedHorse;
  late List<TrainerLinkedHorse> _horses;
  late Map<TrainingPlanWeekday, TrainingPlanGalleryItem?> _trainingsByDay;
  bool _isLoadingHorses = false;
  bool _hasHorsesError = false;
  bool _isHorseMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        TrainingPlanRegistrationController(
          horseRepository: widget.horseRepository,
        );
    _titleController = TextEditingController(text: widget.plan.title);
    _objectiveController = TextEditingController(text: widget.plan.objective);
    _startDate = TrainingPlanRegistrationDraft.dateOnly(widget.plan.startDate);
    _endDate = TrainingPlanRegistrationDraft.dateOnly(widget.plan.endDate);
    _selectedHorse = widget.plan.horse;
    _trainingsByDay = Map<TrainingPlanWeekday, TrainingPlanGalleryItem?>.of(
      widget.plan.trainingsByDay,
    );

    final initialHorses = widget.initialHorses;
    if (initialHorses != null) {
      _horses = _mergeHorsesWithCurrent(initialHorses);
      _selectedHorse = _resolveSelectedHorse(_horses);
    } else {
      _horses = _mergeHorsesWithCurrent(const []);
      _loadHorses();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _objectiveController.dispose();
    _titleFocus.dispose();
    _objectiveFocus.dispose();
    super.dispose();
  }

  List<TrainerLinkedHorse> _mergeHorsesWithCurrent(
    List<TrainerLinkedHorse> source,
  ) {
    final seenIds = <String>{};
    final result = <TrainerLinkedHorse>[];

    void addIfValid(TrainerLinkedHorse horse) {
      final id = horse.id.trim();
      final name = horse.name.trim();
      if (id.isEmpty || name.isEmpty || !seenIds.add(id)) return;
      result.add(TrainerLinkedHorse(id: id, name: name));
    }

    for (final horse in source) {
      addIfValid(horse);
    }
    addIfValid(widget.plan.horse);
    return List.unmodifiable(result);
  }

  TrainerLinkedHorse _resolveSelectedHorse(List<TrainerLinkedHorse> horses) {
    final targetId = _selectedHorse.id.trim();
    for (final horse in horses) {
      if (horse.id == targetId) return horse;
    }
    return horses.isNotEmpty ? horses.first : widget.plan.horse;
  }

  Future<void> _loadHorses() async {
    setState(() {
      _isLoadingHorses = true;
      _hasHorsesError = false;
    });

    try {
      final response = await _controller.fetchLinkedHorses();
      if (!mounted) return;
      final merged = _mergeHorsesWithCurrent(response);
      setState(() {
        _horses = merged;
        _selectedHorse = _resolveSelectedHorse(merged);
        _isLoadingHorses = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoadingHorses = false;
        _hasHorsesError = true;
      });
    }
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  void _toggleEditing(_PlanEditFieldId field) {
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

  FocusNode _focusFor(_PlanEditFieldId field) {
    return switch (field) {
      _PlanEditFieldId.title => _titleFocus,
      _PlanEditFieldId.objective => _objectiveFocus,
    };
  }

  String? _validateTitle(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Preencha este campo.';
    if (trimmed.length < 3 || trimmed.length > 80) {
      return 'O título deve ter entre 3 e 80 caracteres.';
    }
    return null;
  }

  String? _validateObjective(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Preencha este campo.';
    if (trimmed.length > 1000) {
      return 'O objetivo deve ter no máximo 1000 caracteres.';
    }
    return null;
  }

  Future<void> _pickStartDate() async {
    final today = TrainingPlanRegistrationDraft.dateOnly(DateTime.now());
    final planStart = TrainingPlanRegistrationDraft.dateOnly(
      widget.plan.startDate,
    );
    final firstDate = planStart.isBefore(today) ? planStart : today;
    final lastDate = DateTime(today.year + 5, 12, 31);

    var initialDate = _startDate;
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
    final maxEnd = TrainingPlanRegistrationDraft.maxEndDateFor(_startDate);
    var initialDate = _endDate ?? _startDate;
    if (initialDate.isBefore(_startDate)) {
      initialDate = _startDate;
    } else if (initialDate.isAfter(maxEnd)) {
      initialDate = maxEnd;
    }

    final picked = await showAppDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _startDate,
      lastDate: maxEnd,
      title: 'Data de fim',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _endDate = TrainingPlanRegistrationDraft.dateOnly(picked);
    });
  }

  Future<void> _openGalleryForDay(TrainingPlanWeekday weekday) async {
    await showTrainingGalleryBottomSheet(
      context: context,
      controller: _controller,
      horseId: _selectedHorse.id,
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

    if (!mounted || createdDraft == null || createdResult == null ||
        createdResult!.id.trim().isEmpty) return;
    final item = _controller.recordCreatedTrainingFromDraft(
      createdDraft!,
      id: createdResult!.id,
      code: createdResult!.code,
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

  void _save() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final endDate = _endDate;
    if (endDate == null) {
      _showError('Selecione a data de fim para continuar.');
      return;
    }
    if (endDate.isBefore(_startDate)) {
      _showError('A data de fim não pode ser anterior à data de início.');
      return;
    }
    if (endDate.isAfter(
      TrainingPlanRegistrationDraft.maxEndDateFor(_startDate),
    )) {
      _showError('O plano pode durar no máximo 12 meses.');
      return;
    }

    final draftCheck = TrainingPlanRegistrationDraft(
      title: _titleController.text.trim(),
      objective: _objectiveController.text.trim(),
      horse: _selectedHorse,
      startDate: _startDate,
      endDate: endDate,
      trainingsByDay: _trainingsByDay,
    );
    if (!draftCheck.hasAnySelectedTraining) {
      _showError('Selecione um treinamento para pelo menos um dia da semana.');
      return;
    }
    if (!draftCheck.hasAnyScheduledOccurrenceInPeriod) {
      _showError(
        'Nenhum dia do período escolhido tem treino. Ajuste as datas ou os dias da semana.',
      );
      return;
    }

    final update = TrainingPlanUpdate(
      title: _titleController.text.trim(),
      objective: _objectiveController.text.trim(),
      startDate: _startDate,
      endDate: endDate,
      horse: _selectedHorse,
      trainingsByDay: Map.unmodifiable(_trainingsByDay),
    );

    final onSaved = widget.onSaved;
    if (onSaved != null) {
      onSaved(update);
      return;
    }
    Navigator.of(context).pop(update);
  }

  void _showError(String message) {
    AppSnackBar.show(
      context,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline_rounded,
      message: message,
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
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 36),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 54,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(onBack: _goBack),
                    const SizedBox(height: 36),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Editar plano',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Altere e adicione o que desejar,\n'
                              'mas não esqueça de salvar.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 21,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 36),
                            _buildForm(),
                            const SizedBox(height: 28),
                            Text(
                              'Cavalo selecionado',
                              style: textTheme.titleLarge?.copyWith(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildHorseField(),
                            const SizedBox(height: 30),
                            Text(
                              'Treinamentos selecionados',
                              style: textTheme.titleLarge?.copyWith(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            for (
                              var index = 0;
                              index < TrainingPlanWeekday.values.length;
                              index++
                            ) ...[
                              TrainingPlanWeekdaySectionCard(
                                key: ValueKey(
                                  'edit-weekday-section-${TrainingPlanWeekday.values[index].name}',
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
                                const SizedBox(height: 18),
                            ],
                            const SizedBox(height: 36),
                            AuthNextButton(
                              buttonKey: const Key(
                                'save-training-plan-edit-button',
                              ),
                              label: 'Salvar alterações',
                              showArrow: false,
                              onPressed: _save,
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

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          EditableReviewField(
            fieldKey: const Key('training-plan-edit-title-field'),
            label: 'Título',
            controller: _titleController,
            focusNode: _titleFocus,
            isEditing: _editingFields.contains(_PlanEditFieldId.title),
            validator: _validateTitle,
            textInputAction: TextInputAction.next,
            onToggleEditing: () => _toggleEditing(_PlanEditFieldId.title),
          ),
          const SizedBox(height: 22),
          EditableReviewField(
            fieldKey: const Key('training-plan-edit-objective-field'),
            label: 'Objetivo',
            controller: _objectiveController,
            focusNode: _objectiveFocus,
            isEditing: _editingFields.contains(_PlanEditFieldId.objective),
            minLines: 1,
            maxLines: 4,
            validator: _validateObjective,
            textInputAction: TextInputAction.done,
            onToggleEditing: () => _toggleEditing(_PlanEditFieldId.objective),
          ),
          const SizedBox(height: 22),
          AppDatePickerField(
            key: const Key('training-plan-edit-start-date-field'),
            value: _startDate,
            labelText: 'Data de início',
            hintText: 'DD/MM/AAAA (início)',
            onTap: _pickStartDate,
          ),
          const SizedBox(height: 22),
          AppDatePickerField(
            key: const Key('training-plan-edit-end-date-field'),
            value: _endDate,
            labelText: 'Data de fim',
            hintText: 'DD/MM/AAAA (fim)',
            onTap: _pickEndDate,
          ),
        ],
      ),
    );
  }

  Widget _buildHorseField() {
    if (_isLoadingHorses) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDropdownField<TrainerLinkedHorse>(
          style: AppDropdownStyle.rounded,
          label: 'Selecionar cavalo',
          dropdownKey: const Key('training-plan-edit-horse-dropdown'),
          value: _selectedHorse,
          options: _horses,
          labelFor: (horse) => horse.name,
          isOpen: _isHorseMenuOpen,
          onTap: () => setState(() => _isHorseMenuOpen = true),
          onChanged: (value) => setState(() {
            _selectedHorse = value;
            _isHorseMenuOpen = false;
          }),
        ),
        if (_hasHorsesError)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loadHorses,
              child: const Text('Recarregar cavalos vinculados'),
            ),
          ),
      ],
    );
  }
}

enum _PlanEditFieldId { title, objective }
