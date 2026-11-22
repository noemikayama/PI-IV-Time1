// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento de comentários e docstrings explicativos para
// facilitar o entendimento do ciclo de edição, validações e fluxos modais.
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela de edição de treinamentos com reutilização de
// EditableReviewField, modal de adição de orientações (AddTrainingGuidelineDialog),
// galeria de exercícios (ExerciseGalleryBottomSheet), criação direta de exercício
// (ExerciseRegistrationFlowRoute) e cards SelectedTrainingExerciseCard.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_item_list_widgets.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/editable_review_field.dart';

import '../../../exercises/application/controllers/exercise_registration_controller.dart';
import '../../../exercises/application/states/exercise_registration_draft.dart';
import '../../../exercises/presentation/routes/exercise_registration_flow_route.dart';
import '../../application/controllers/training_registration_controller.dart';
import '../../data/models/training_detail_data.dart';
import '../../data/models/training_exercise_item.dart';
import '../../data/repositories/firebase_training_exercise_gallery_repository.dart';
import '../../data/repositories/firebase_training_registration_repository.dart';
import '../../../exercises/data/repositories/firebase_trainer_linked_horse_repository.dart';
import '../widgets/add_training_guideline_dialog.dart';
import '../widgets/exercise_gallery_bottom_sheet.dart';
import '../widgets/training_exercise_cards.dart';

/// Formulário completo de edição de um treinamento existente.
///
/// Permite alterar:
/// - **Título**, **Descrição** e **Duração estimada** através de [EditableReviewField];
/// - **Orientações**: adição via [AddTrainingGuidelineDialog] e remoção individual;
/// - **Exercícios selecionados**: adição a partir da galeria ([ExerciseGalleryBottomSheet]),
///   cadastro de novos exercícios ([ExerciseRegistrationFlowRoute]) e remoção.
///
/// Ao salvar, valida se a duração estimada é maior ou igual à soma das durações
/// dos exercícios e se há pelo menos um exercício e uma orientação cadastrados.
class TrainingEditScreen extends StatefulWidget {
  const TrainingEditScreen({
    required this.training,
    this.controller,
    this.exerciseRegistrationController,
    this.onCreateExercise,
    this.onSaved,
    this.onBack,
    super.key,
  });

  /// Dados atuais do treinamento para preenchimento dos campos editáveis.
  final TrainingDetailData training;

  /// Controlador compartilhado para gravação e estado temporário de criação.
  final TrainingRegistrationController? controller;

  /// Controlador compartilhado para injeção de dependências do fluxo de exercícios.
  final ExerciseRegistrationController? exerciseRegistrationController;

  /// Callback para sobrescrever a ação de criação de novos exercícios em testes.
  final VoidCallback? onCreateExercise;

  /// Callback acionado quando a edição é validada e concluída com sucesso.
  final ValueChanged<TrainingUpdate>? onSaved;

  /// Ação executada ao clicar no botão de retorno.
  final VoidCallback? onBack;

  @override
  State<TrainingEditScreen> createState() => _TrainingEditScreenState();
}

class _TrainingEditScreenState extends State<TrainingEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TrainingRegistrationController _controller;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;
  final _titleFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _durationFocus = FocusNode();
  final Set<_TrainingEditFieldId> _editingFields = {};

  late final List<String> _guidelines;
  late List<TrainingExerciseItem> _selectedExercises;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        TrainingRegistrationController(
          galleryRepository: const FirebaseTrainingExerciseGalleryRepository(),
          horseRepository: const FirebaseTrainerLinkedHorseRepository(),
          registrationRepository: const FirebaseTrainingRegistrationRepository(),
        );
    _titleController = TextEditingController(text: widget.training.title);
    _descriptionController = TextEditingController(
      text: widget.training.description,
    );
    _durationController = TextEditingController(
      text: widget.training.estimatedDurationMinutes.toString(),
    );
    _guidelines = List.of(widget.training.guidelines);
    _selectedExercises = widget.training.exercises
        .map((exercise) => exercise.toExerciseItem())
        .toList();
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

  // Gerenciamento de Foco e Edição Inline

  /// Alterna o modo de edição inline de um campo de texto e requisita o foco.
  void _toggleEditing(_TrainingEditFieldId field) {
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

  FocusNode _focusFor(_TrainingEditFieldId field) {
    return switch (field) {
      _TrainingEditFieldId.title => _titleFocus,
      _TrainingEditFieldId.description => _descriptionFocus,
      _TrainingEditFieldId.duration => _durationFocus,
    };
  }

  // Validações de Regras de Negócio

  /// Soma acumulada das durações de todos os exercícios atualmente selecionados.
  int get _totalExercisesDuration => _selectedExercises.fold<int>(
    0,
    (total, exercise) => total + exercise.estimatedDurationMinutes,
  );

  /// Valida o título do treinamento conforme regras do backend (3 a 80 caracteres).
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

  /// Valida a descrição do treinamento (máximo de 1000 caracteres se preenchida).
  String? _validateDescription(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length > 1000) {
      return 'A descrição deve ter no máximo 1000 caracteres.';
    }
    return null;
  }

  /// Valida se a duração está no intervalo permitido (1 a 480 min) e é maior ou
  /// igual ao somatório dos exercícios selecionados na sessão.
  String? _validateDuration(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Preencha este campo.';
    }
    final minutes = int.tryParse(trimmed);
    if (minutes == null || minutes < 1 || minutes > 480) {
      return 'Informe uma duração válida entre 1 e 480 minutos.';
    }
    final exercisesSum = _totalExercisesDuration;
    if (minutes < exercisesSum) {
      return 'A duração não pode ser menor que a soma dos exercícios ($exercisesSum min).';
    }
    return null;
  }

  // Ações de Orientações da Sessão

  /// Abre o modal para adição de uma nova orientação textual ao treinamento.
  Future<void> _addGuideline() async {
    if (_guidelines.length >= 30) {
      _showError('Limite máximo de 30 orientações atingido.');
      return;
    }

    final guideline = await showAddTrainingGuidelineDialog(context);
    if (!mounted || guideline == null || guideline.trim().isEmpty) return;

    final normalized = guideline.trim();
    if (_guidelines.any(
      (existing) => existing.toLowerCase() == normalized.toLowerCase(),
    )) {
      _showError('Essa orientação já foi adicionada.');
      return;
    }

    setState(() => _guidelines.add(normalized));
  }

  /// Remove uma orientação existente pelo índice da lista.
  void _removeGuideline(int index) {
    setState(() => _guidelines.removeAt(index));
  }

  // Ações de Seleção e Cadastro de Exercícios

  /// Abre o modal inferior (bottom sheet) da galeria de exercícios para seleção múltipla.
  Future<void> _openGallery() async {
    await showExerciseGalleryBottomSheet(
      context: context,
      controller: _controller,
      selectedExercises: _selectedExercises,
      onSelectionChanged: (updatedSelection) {
        if (!mounted) return;
        final merged = updatedSelection.map((item) {
          for (final existing in _selectedExercises) {
            if (existing.matches(item)) {
              return item.copyWith(
                code: item.code ?? existing.code,
                description: item.description ?? existing.description,
              );
            }
          }
          return item;
        }).toList();

        setState(() {
          _selectedExercises = merged;
          _syncDurationIfBelowExercisesSum();
        });
      },
      onCreateExercise: _openExerciseCreation,
    );
  }

  /// Inicia o fluxo completo de cadastro de um novo exercício, anexando-o ao
  /// treinamento assim que a criação for confirmada.
  Future<void> _openExerciseCreation() async {
    final onCreateExercise = widget.onCreateExercise;
    if (onCreateExercise != null) {
      onCreateExercise();
      return;
    }

    ExerciseRegistrationDraft? createdDraft;
    String? createdExerciseId;
    int? createdExerciseCode;
    final injectedController = widget.exerciseRegistrationController;
    final routeController = injectedController?.withOnExerciseCreated(
      (draft) {
        createdDraft = draft;
        injectedController.onExerciseCreated?.call(draft);
      },
      onExerciseCreatedWithId: (draft, id) {
        createdDraft = draft;
        createdExerciseId = id;
        injectedController.onExerciseCreatedWithId?.call(draft, id);
      },
      onExerciseCreatedWithResult: (draft, result) {
        createdDraft = draft;
        createdExerciseId = result?.id;
        createdExerciseCode = result?.code;
        injectedController.onExerciseCreatedWithResult?.call(draft, result);
      },
    );

    await Navigator.push<void>(
      context,
      ExerciseRegistrationFlowRoute.build(
        registrationController: routeController,
        onExerciseCreated: (draft) {
          createdDraft = draft;
        },
        onExerciseCreatedWithId: (draft, id) {
          createdDraft = draft;
          createdExerciseId = id;
        },
        onExerciseCreatedWithResult: (draft, result) {
          createdDraft = draft;
          createdExerciseId = result?.id;
          createdExerciseCode = result?.code;
        },
      ),
    );

    if (!mounted || createdDraft == null) return;
    final createdItem = _controller.recordCreatedExerciseFromDraft(
      createdDraft!,
      id: createdExerciseId,
      code: createdExerciseCode,
    );
    setState(() {
      if (!_selectedExercises.any((item) => item.matches(createdItem))) {
        _selectedExercises.add(createdItem);
        _syncDurationIfBelowExercisesSum();
      }
    });
  }

  /// Sincroniza a duração estimada caso o somatório dos exercícios selecionados
  /// passe a exceder o valor atual informado pelo usuário.
  void _syncDurationIfBelowExercisesSum() {
    final exercisesSum = _totalExercisesDuration;
    final currentMinutes = int.tryParse(_durationController.text.trim()) ?? 0;
    if (exercisesSum > currentMinutes) {
      _durationController.text = exercisesSum.toString();
    }
  }

  /// Remove um exercício selecionado da lista.
  void _removeExercise(int index) {
    setState(() => _selectedExercises.removeAt(index));
  }

  // Validação Final e Submissão

  /// Valida todos os campos obrigatórios e emite o payload consolidado [TrainingUpdate].
  void _save() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_guidelines.isEmpty) {
      _showError('Adicione pelo menos uma orientação para salvar o treinamento.');
      return;
    }

    if (_selectedExercises.isEmpty) {
      _showError('Selecione pelo menos um exercício para salvar o treinamento.');
      return;
    }

    final update = TrainingUpdate(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      estimatedDurationMinutes: int.parse(_durationController.text.trim()),
      guidelines: List.unmodifiable(_guidelines),
      exercises: List.unmodifiable(_selectedExercises),
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
                              'Editar treinamento',
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
                            const SizedBox(height: 30),
                            _buildGuidelinesSection(textTheme),
                            const SizedBox(height: 30),
                            _buildExercisesSection(textTheme),
                            const SizedBox(height: 38),
                            AuthNextButton(
                              buttonKey: const Key('save-training-edit-button'),
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
            fieldKey: const Key('training-edit-title-field'),
            label: 'Título',
            controller: _titleController,
            focusNode: _titleFocus,
            isEditing: _editingFields.contains(_TrainingEditFieldId.title),
            validator: _validateTitle,
            textInputAction: TextInputAction.next,
            onToggleEditing: () => _toggleEditing(_TrainingEditFieldId.title),
          ),
          const SizedBox(height: 22),
          EditableReviewField(
            fieldKey: const Key('training-edit-description-field'),
            label: 'Descrição',
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            isEditing: _editingFields.contains(
              _TrainingEditFieldId.description,
            ),
            minLines: 1,
            maxLines: 4,
            validator: _validateDescription,
            textInputAction: TextInputAction.done,
            onToggleEditing: () =>
                _toggleEditing(_TrainingEditFieldId.description),
          ),
          const SizedBox(height: 22),
          EditableReviewField(
            fieldKey: const Key('training-edit-duration-field'),
            label: 'Duração',
            controller: _durationController,
            focusNode: _durationFocus,
            isEditing: _editingFields.contains(_TrainingEditFieldId.duration),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validateDuration,
            textInputAction: TextInputAction.done,
            onToggleEditing: () =>
                _toggleEditing(_TrainingEditFieldId.duration),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelinesSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Orientações',
          style: textTheme.titleLarge?.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('training-edit-add-guideline-button'),
            onPressed: _addGuideline,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.seaGreen,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: Text(
              'Adicionar',
              style: textTheme.titleLarge?.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w500,
                color: AppColors.seaGreen,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_guidelines.isEmpty)
          Text(
            'Nenhuma orientação adicionada.',
            key: const Key('training-edit-empty-guidelines'),
            style: textTheme.bodyLarge?.copyWith(color: AppColors.grey),
          )
        else
          for (var index = 0; index < _guidelines.length; index++) ...[
            AppRemovableItemTile(
              key: ValueKey('training-edit-guideline-$index'),
              icon: Icons.chat_bubble_outline_rounded,
              label: _guidelines[index],
              minHeight: 72,
              maxLines: null,
              removeKey: ValueKey('remove-training-edit-guideline-$index'),
              onRemove: () => _removeGuideline(index),
            ),
            if (index < _guidelines.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _buildExercisesSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Seleção de exercícios',
          style: textTheme.titleLarge?.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        AppAddItemButton(
          buttonKey: const Key('training-edit-open-exercise-gallery-button'),
          label: 'Adicionar da galeria',
          onPressed: _openGallery,
        ),
        const SizedBox(height: 14),
        AppAddItemButton(
          buttonKey: const Key('training-edit-create-exercise-button'),
          label: 'Criar exercício',
          onPressed: _openExerciseCreation,
        ),
        const SizedBox(height: 18),
        if (_selectedExercises.isEmpty)
          Text(
            'Nenhum exercício selecionado.',
            key: const Key('training-edit-empty-exercises'),
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.grey),
          )
        else
          for (var index = 0; index < _selectedExercises.length; index++) ...[
            SelectedTrainingExerciseCard(
              key: ValueKey('training-edit-exercise-$index'),
              exercise: _selectedExercises[index],
              removeKey: ValueKey('remove-training-edit-exercise-$index'),
              onRemove: () => _removeExercise(index),
            ),
            if (index < _selectedExercises.length - 1)
              const SizedBox(height: 14),
          ],
      ],
    );
  }
}

enum _TrainingEditFieldId { title, description, duration }
