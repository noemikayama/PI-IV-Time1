// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Notificação do resultado do treinamento recém-criado via
// onTrainingCreated ao concluir o cadastro.
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Validação obrigatória de ao menos uma orientação e conferência de que
// a duração não seja inferior à soma das durações dos exercícios selecionados.
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da sexta etapa do cadastro de treinamentos (6 de 6),
// consolidando revisão com edição inline de título, descrição e duração,
// remoção de orientações e exercícios selecionados e submissão final.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_item_list_widgets.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/editable_review_field.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../application/controllers/training_registration_controller.dart';
import '../../application/states/training_registration_draft.dart';
import '../../data/models/training_exercise_item.dart';
import '../../data/repositories/training_registration_repository.dart';
import '../routes/training_registration_flow_route.dart';
import '../widgets/training_exercise_cards.dart';

typedef TrainingConfirmationSubmittedCallback =
    void Function(TrainingRegistrationDraft draft);

/// Etapa 6 de 6: Revisão dos dados e submissão do cadastro de treinamento.
class TrainingConfirmationScreen extends StatefulWidget {
  const TrainingConfirmationScreen({
    required this.draft,
    this.controller,
    this.onSubmitted,
    this.onCreated,
    this.onBack,
    super.key,
  });

  final TrainingRegistrationDraft draft;
  final TrainingRegistrationController? controller;
  final TrainingConfirmationSubmittedCallback? onSubmitted;
  final VoidCallback? onCreated;
  final VoidCallback? onBack;

  @override
  State<TrainingConfirmationScreen> createState() =>
      _TrainingConfirmationScreenState();
}

class _TrainingConfirmationScreenState
    extends State<TrainingConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _durationFocus = FocusNode();
  final Set<_TrainingReviewFieldId> _editingFields = {};

  late final List<String> _guidelines;
  late final List<TrainingExerciseItem> _selectedExercises;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.draft.title);
    _descriptionController = TextEditingController(
      text: widget.draft.description,
    );
    _durationController = TextEditingController(
      text: widget.draft.estimatedDurationMinutes?.toString() ?? '',
    );
    _guidelines = List.of(widget.draft.guidelines);
    _selectedExercises = List.of(widget.draft.selectedExercises);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _durationFocus.dispose();
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

  void _toggleEditing(_TrainingReviewFieldId field) {
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

  FocusNode _focusFor(_TrainingReviewFieldId field) {
    return switch (field) {
      _TrainingReviewFieldId.title => _titleFocus,
      _TrainingReviewFieldId.description => _descriptionFocus,
      _TrainingReviewFieldId.duration => _durationFocus,
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

  String? _validateDuration(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Preencha este campo.';
    }
    final minutes = int.tryParse(trimmed);
    if (minutes == null || minutes < 1 || minutes > 480) {
      return 'Informe uma duração válida entre 1 e 480 minutos.';
    }
    final totalExercisesDuration = _selectedExercises.fold<int>(
      0,
      (total, exercise) => total + exercise.estimatedDurationMinutes,
    );
    if (minutes < totalExercisesDuration) {
      return 'A duração não pode ser menor que a soma dos exercícios ($totalExercisesDuration min).';
    }
    return null;
  }

  TrainingRegistrationDraft _buildUpdatedDraft() {
    return widget.draft
        .withTitle(_titleController.text.trim())
        .withDescription(_descriptionController.text.trim())
        .withEstimatedDurationMinutes(
          int.parse(_durationController.text.trim()),
        )
        .withGuidelines(_guidelines)
        .withSelectedExercises(_selectedExercises);
  }

  Future<void> _submitTraining() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedExercises.isEmpty) {
      _showError(
        'Adicione pelo menos um exercício para cadastrar o treinamento.',
      );
      return;
    }

    if (_guidelines.isEmpty) {
      _showError(
        'Adicione pelo menos uma orientação para cadastrar o treinamento.',
      );
      return;
    }

    final updatedDraft = _buildUpdatedDraft();
    final onSubmitted = widget.onSubmitted;
    if (onSubmitted != null) {
      onSubmitted(updatedDraft);
      return;
    }

    final controller = widget.controller ?? TrainingRegistrationController();
    setState(() => _isSubmitting = true);
    try {
      final result = await controller.registerTraining(draft: updatedDraft);
      if (!mounted) return;
      _finishRegistration(updatedDraft, result);
    } on TrainingRegistrationFailure catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } on Object {
      if (!mounted) return;
      _showError(
        'Não foi possível cadastrar o treinamento. Tente novamente em instantes.',
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

  void _finishRegistration([
    TrainingRegistrationDraft? createdDraft,
    TrainingRegistrationResult? result,
  ]) {
    if (createdDraft != null) {
      widget.controller?.onTrainingCreated?.call(createdDraft, result);
    }

    final onCreated = widget.onCreated;
    if (onCreated != null) {
      onCreated();
      return;
    }

    AppSnackBar.show(
      context,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline_rounded,
      message: 'Treinamento cadastrado com sucesso.',
    );

    final navigator = Navigator.of(context);
    var foundEntryRoute = false;
    navigator.popUntil((route) {
      if (route.settings.name == TrainingRegistrationFlowRoute.routeName) {
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
                              currentStep: 6,
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
                            const SizedBox(height: 36),
                            _buildGuidelinesSection(),
                            const SizedBox(height: 28),
                            _buildExercisesSection(),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'submit-training-registration',
                              ),
                              label: 'Cadastrar treinamento',
                              showArrow: false,
                              isLoading: _isSubmitting,
                              onPressed: _submitTraining,
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
            fieldKey: const Key('training-review-title'),
            label: 'Título',
            controller: _titleController,
            focusNode: _titleFocus,
            isEditing: _editingFields.contains(_TrainingReviewFieldId.title),
            validator: _validateTitle,
            textInputAction: TextInputAction.next,
            onToggleEditing: () =>
                _toggleEditing(_TrainingReviewFieldId.title),
          ),
          const SizedBox(height: 24),
          EditableReviewField(
            fieldKey: const Key('training-review-description'),
            label: 'Descrição',
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            isEditing: _editingFields.contains(
              _TrainingReviewFieldId.description,
            ),
            minLines: 1,
            maxLines: 4,
            validator: _validateDescription,
            textInputAction: TextInputAction.done,
            onToggleEditing: () =>
                _toggleEditing(_TrainingReviewFieldId.description),
          ),
          const SizedBox(height: 24),
          EditableReviewField(
            fieldKey: const Key('training-review-duration'),
            label: 'Duração',
            controller: _durationController,
            focusNode: _durationFocus,
            isEditing: _editingFields.contains(_TrainingReviewFieldId.duration),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validateDuration,
            textInputAction: TextInputAction.done,
            onToggleEditing: () =>
                _toggleEditing(_TrainingReviewFieldId.duration),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelinesSection() {
    return AppReviewSection(
      title: 'Orientações',
      emptyMessage: 'Nenhuma orientação adicionada.',
      children: [
        for (var index = 0; index < _guidelines.length; index++)
          AppRemovableItemTile(
            key: ValueKey('training-review-guideline-$index'),
            icon: Icons.chat_bubble_outline_rounded,
            label: _guidelines[index],
            minHeight: 72,
            maxLines: null,
            removeKey: ValueKey('remove-training-review-guideline-$index'),
            onRemove: () => setState(() => _guidelines.removeAt(index)),
          ),
      ],
    );
  }

  Widget _buildExercisesSection() {
    return AppReviewSection(
      title: 'Exercícios selecionados',
      emptyMessage: 'Nenhum exercício selecionado.',
      children: [
        for (var index = 0; index < _selectedExercises.length; index++)
          SelectedTrainingExerciseCard(
            key: ValueKey('training-review-exercise-$index'),
            exercise: _selectedExercises[index],
            removeKey: ValueKey('remove-training-review-exercise-$index'),
            onRemove: () => setState(() => _selectedExercises.removeAt(index)),
          ),
      ],
    );
  }
}

enum _TrainingReviewFieldId { title, description, duration }
