// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Propagação de ExerciseRegistrationResult completo via
// onExerciseCreatedWithResult após conclusão do cadastro.
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Propagação do identificador real do exercício criado via
// onExerciseCreatedWithId após conclusão do cadastro.
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Suporte ao retorno até a tela chamadora de ExerciseRegistrationFlowRoute
// e notificação via onExerciseCreated após concluir o cadastro do exercício.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Integração com retorno de persistência do ExerciseRegistrationResult,
// exibição de alertas parciais de mídias e validações de nome, descrição e duração.
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adoção dos componentes centralizados FormProgressIndicator,
// AppRemovableItemTile e AppReviewSection provenientes de core/widgets.
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Restrição obrigatória de submissão do exercício quando não houver
// ao menos uma orientação cadastrada.
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela final de revisão e confirmação do cadastro de
// exercícios, adaptando-se ao fluxo genérico (etapa 7 de 7) e específico
// (etapa 8 de 8, com exibição do cavalo selecionado), permitindo edição inline
// dos campos textuais e remoção de orientações, materiais e mídias.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_item_list_widgets.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/form_progress_indicator.dart';
import '../../../authentication/presentation/widgets/auth_header.dart';
import '../../../authentication/presentation/widgets/auth_next_button.dart';
import '../../../authentication/presentation/widgets/editable_review_field.dart';
import '../../application/controllers/exercise_registration_controller.dart';
import '../../application/states/exercise_material.dart';
import '../../application/states/exercise_media.dart';
import '../../application/states/exercise_registration_draft.dart';
import '../../data/models/exercise_registration_result.dart';
import '../../data/models/trainer_linked_horse.dart';
import '../../data/repositories/exercise_registration_repository.dart';
import '../routes/exercise_registration_flow_route.dart';

typedef ExerciseConfirmationSubmittedCallback =
    void Function(ExerciseRegistrationDraft draft);

// Última etapa do formulário de criação de exercícios (etapa 7 de 7 para
// genéricos e etapa 8 de 8 para específicos): consolida todos os dados para
// revisão, edição pontual e submissão final.
class ExerciseConfirmationScreen extends StatefulWidget {
  const ExerciseConfirmationScreen({
    required this.draft,
    this.registrationController,
    this.onSubmitted,
    this.onCreated,
    this.onBack,
    super.key,
  });

  final ExerciseRegistrationDraft draft;
  final ExerciseRegistrationController? registrationController;
  final ExerciseConfirmationSubmittedCallback? onSubmitted;
  final VoidCallback? onCreated;
  final VoidCallback? onBack;

  @override
  State<ExerciseConfirmationScreen> createState() =>
      _ExerciseConfirmationScreenState();
}

class _ExerciseConfirmationScreenState
    extends State<ExerciseConfirmationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _durationFocus = FocusNode();
  final Set<_ExerciseReviewFieldId> _editingFields = {};

  late final List<String> _guidelines;
  late final List<ExerciseMaterial> _materials;
  late final List<ExerciseMedia> _mediaItems;
  bool _isSubmitting = false;

  FormProgressConfiguration get _progressConfiguration =>
      switch (widget.draft) {
        GenericExerciseRegistrationDraft() =>
          FormProgressConfiguration.genericExercise,
        SpecificExerciseRegistrationDraft() =>
          FormProgressConfiguration.specificExercise,
      };

  int get _currentStep => switch (widget.draft) {
    GenericExerciseRegistrationDraft() => 7,
    SpecificExerciseRegistrationDraft() => 8,
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.draft.name);
    _descriptionController = TextEditingController(
      text: widget.draft.description,
    );
    _durationController = TextEditingController(
      text: widget.draft.defaultDurationMinutes?.toString() ?? '',
    );
    _guidelines = List.of(widget.draft.guidelines);
    _materials = List.of(widget.draft.materials);
    _mediaItems = List.of(widget.draft.mediaItems);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _nameFocus.dispose();
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

  // Alterna a edição inline do campo selecionado e move o foco para ele.
  void _toggleEditing(_ExerciseReviewFieldId field) {
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

  FocusNode _focusFor(_ExerciseReviewFieldId field) {
    return switch (field) {
      _ExerciseReviewFieldId.name => _nameFocus,
      _ExerciseReviewFieldId.description => _descriptionFocus,
      _ExerciseReviewFieldId.duration => _durationFocus,
    };
  }

  String? _validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Preencha este campo.';
    }
    if (trimmed.length < 3 || trimmed.length > 80) {
      return 'O nome deve ter entre 3 e 80 caracteres.';
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
    if (minutes == null || minutes <= 0 || minutes > 240) {
      return 'Informe uma duração válida entre 1 e 240 minutos.';
    }
    return null;
  }

  ExerciseRegistrationDraft _buildUpdatedDraft() {
    return widget.draft
        .withName(_nameController.text.trim())
        .withDescription(_descriptionController.text.trim())
        .withDefaultDurationMinutes(int.parse(_durationController.text.trim()))
        .withGuidelines(_guidelines)
        .withMaterials(_materials)
        .withMediaItems(_mediaItems);
  }

  Future<void> _submitExercise() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_guidelines.isEmpty) {
      _showError(
        'Adicione pelo menos uma orientação para cadastrar o exercício.',
      );
      return;
    }

    final updatedDraft = _buildUpdatedDraft();
    final onSubmitted = widget.onSubmitted;
    if (onSubmitted != null) {
      onSubmitted(updatedDraft);
      return;
    }

    final controller = widget.registrationController;
    setState(() => _isSubmitting = true);
    try {
      ExerciseRegistrationResult? createdResult;
      if (controller != null) {
        final result = await controller.registerExercise(draft: updatedDraft);
        createdResult = result;
        if (!mounted) return;
        if (result.hasMediaWarning) {
          AppSnackBar.show(
            context,
            backgroundColor: AppColors.error,
            icon: Icons.warning_amber_rounded,
            message: result.warning!,
          );
        }
      }
      if (!mounted) return;
      _finishRegistration(updatedDraft, createdResult);
    } on ExerciseRegistrationFailure catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } on Object {
      if (!mounted) return;
      _showError(
        'Não foi possível cadastrar o exercício. Tente novamente em instantes.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    AppSnackBar.show(
      context,
      backgroundColor: Theme.of(context).colorScheme.error,
      icon: Icons.error,
      message: message,
    );
  }

  void _finishRegistration([
    ExerciseRegistrationDraft? createdDraft,
    ExerciseRegistrationResult? createdResult,
  ]) {
    if (createdDraft != null) {
      widget.registrationController?.onExerciseCreated?.call(createdDraft);
      widget.registrationController?.onExerciseCreatedWithId?.call(
        createdDraft,
        createdResult?.id,
      );
      widget.registrationController?.onExerciseCreatedWithResult?.call(
        createdDraft,
        createdResult,
      );
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
      message: 'Exercício cadastrado com sucesso.',
    );

    final navigator = Navigator.of(context);
    var foundEntryRoute = false;
    navigator.popUntil((route) {
      if (route.settings.name == ExerciseRegistrationFlowRoute.routeName) {
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
                            FormProgressIndicator(
                              configuration: _progressConfiguration,
                              currentStep: _currentStep,
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
                            if (widget.draft
                                case SpecificExerciseRegistrationDraft(
                                  :final horse,
                                )) ...[
                              _buildSelectedHorseSection(context, horse),
                              const SizedBox(height: 28),
                            ],
                            _buildEditableFieldsForm(),
                            const SizedBox(height: 36),
                            _buildGuidelinesSection(),
                            const SizedBox(height: 28),
                            _buildMaterialsSection(),
                            const SizedBox(height: 28),
                            _buildMediaSection(),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'submit-exercise-registration',
                              ),
                              label: 'Cadastrar exercício',
                              showArrow: false,
                              isLoading: _isSubmitting,
                              onPressed: _submitExercise,
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

  // Exibe a seção "Cavalo selecionado" apenas quando o exercício é específico.
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
          key: const Key('exercise-review-selected-horse'),
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

  // Campos textuais editáveis inline (Nome, Descrição e Tempo), reutilizando
  // EditableReviewField.
  Widget _buildEditableFieldsForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          EditableReviewField(
            fieldKey: const Key('exercise-review-name'),
            label: 'Nome',
            controller: _nameController,
            focusNode: _nameFocus,
            isEditing: _editingFields.contains(_ExerciseReviewFieldId.name),
            validator: _validateName,
            textInputAction: TextInputAction.next,
            onToggleEditing: () => _toggleEditing(_ExerciseReviewFieldId.name),
          ),
          const SizedBox(height: 24),
          EditableReviewField(
            fieldKey: const Key('exercise-review-description'),
            label: 'Descrição',
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            isEditing: _editingFields.contains(
              _ExerciseReviewFieldId.description,
            ),
            minLines: 1,
            maxLines: 4,
            validator: _validateDescription,
            textInputAction: TextInputAction.done,
            onToggleEditing: () =>
                _toggleEditing(_ExerciseReviewFieldId.description),
          ),
          const SizedBox(height: 24),
          EditableReviewField(
            fieldKey: const Key('exercise-review-duration'),
            label: 'Tempo',
            controller: _durationController,
            focusNode: _durationFocus,
            isEditing: _editingFields.contains(_ExerciseReviewFieldId.duration),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validateDuration,
            textInputAction: TextInputAction.done,
            onToggleEditing: () =>
                _toggleEditing(_ExerciseReviewFieldId.duration),
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
            key: ValueKey('exercise-review-guideline-$index'),
            icon: Icons.chat_bubble_outline_rounded,
            label: _guidelines[index],
            minHeight: 72,
            maxLines: null,
            removeKey: ValueKey('remove-exercise-review-guideline-$index'),
            onRemove: () => setState(() => _guidelines.removeAt(index)),
          ),
      ],
    );
  }

  Widget _buildMaterialsSection() {
    return AppReviewSection(
      title: 'Materiais necessários',
      emptyMessage: 'Nenhum material adicionado.',
      children: [
        for (var index = 0; index < _materials.length; index++)
          AppRemovableItemTile(
            key: ValueKey('exercise-review-material-$index'),
            icon: Icons.handyman_outlined,
            label: _materials[index].displayLabel,
            removeKey: ValueKey('remove-exercise-review-material-$index'),
            onRemove: () => setState(() => _materials.removeAt(index)),
          ),
      ],
    );
  }

  Widget _buildMediaSection() {
    return AppReviewSection(
      title: 'Mídias auxiliares',
      emptyMessage: 'Nenhuma mídia anexada.',
      children: [
        for (var index = 0; index < _mediaItems.length; index++)
          AppRemovableItemTile(
            key: ValueKey('exercise-review-media-$index'),
            icon: _mediaItems[index].type == ExerciseMediaType.video
                ? Icons.movie_outlined
                : Icons.image_outlined,
            label: _mediaItems[index].name,
            removeKey: ValueKey('remove-exercise-review-media-$index'),
            onRemove: () => setState(() => _mediaItems.removeAt(index)),
          ),
      ],
    );
  }
}

enum _ExerciseReviewFieldId { name, description, duration }
