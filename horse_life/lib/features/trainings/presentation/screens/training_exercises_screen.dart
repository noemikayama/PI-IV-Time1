// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Encadeamento para a etapa de orientações do treinamento e
// captura do identificador real do exercício criado na mesma sessão.
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da terceira etapa do cadastro de treinamentos (3 de 6),
// integrando o bottom sheet da galeria de exercícios (genéricos por padrão e
// específicos por filtro de cavalo vinculado) e o redirecionamento para o fluxo
// de criação de exercício com retorno e atualização da lista.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_item_list_widgets.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../../exercises/application/controllers/exercise_registration_controller.dart';
import '../../../exercises/application/states/exercise_registration_draft.dart';
import '../../../exercises/presentation/routes/exercise_registration_flow_route.dart';
import '../../application/controllers/training_registration_controller.dart';
import '../../application/states/training_registration_draft.dart';
import '../../data/models/training_exercise_item.dart';
import '../widgets/exercise_gallery_bottom_sheet.dart';
import '../widgets/training_exercise_cards.dart';
import 'training_guidelines_screen.dart';

typedef TrainingExercisesCallback =
    void Function(TrainingRegistrationDraft draft);

/// Etapa 3 de 6: Seleção múltipla dos exercícios que compõem o treinamento.
class TrainingExercisesScreen extends StatefulWidget {
  const TrainingExercisesScreen({
    required this.draft,
    this.controller,
    this.exerciseRegistrationController,
    this.onCreateExercise,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainingRegistrationDraft draft;
  final TrainingRegistrationController? controller;
  final ExerciseRegistrationController? exerciseRegistrationController;
  final VoidCallback? onCreateExercise;
  final TrainingExercisesCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<TrainingExercisesScreen> createState() =>
      _TrainingExercisesScreenState();
}

class _TrainingExercisesScreenState extends State<TrainingExercisesScreen> {
  late final TrainingRegistrationController _controller;
  late List<TrainingExerciseItem> _selectedExercises;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TrainingRegistrationController();
    _selectedExercises = List.of(widget.draft.selectedExercises);
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  Future<void> _openGallery() async {
    await showExerciseGalleryBottomSheet(
      context: context,
      controller: _controller,
      selectedExercises: _selectedExercises,
      onSelectionChanged: (updatedSelection) {
        if (!mounted) return;
        setState(() {
          _selectedExercises = List.of(updatedSelection);
        });
      },
      onCreateExercise: _openExerciseCreation,
    );
  }

  Future<void> _openExerciseCreation() async {
    final onCreateExercise = widget.onCreateExercise;
    if (onCreateExercise != null) {
      onCreateExercise();
      return;
    }

    ExerciseRegistrationDraft? createdDraft;
    String? createdExerciseId;
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
      ),
    );

    if (!mounted) return;
    if (createdDraft != null) {
      final createdItem = _controller.recordCreatedExerciseFromDraft(
        createdDraft!,
        id: createdExerciseId,
      );
      setState(() {
        if (!_selectedExercises.any((item) => item.id == createdItem.id)) {
          _selectedExercises.add(createdItem);
        }
      });
    }
  }

  void _removeExercise(int index) {
    setState(() => _selectedExercises.removeAt(index));
  }

  void _continue() {
    if (_selectedExercises.isEmpty) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Adicione pelo menos um exercício para continuar.',
      );
      return;
    }

    final updatedDraft = widget.draft.withSelectedExercises(_selectedExercises);
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TrainingGuidelinesScreen(
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
                              configuration: FormProgressConfiguration.training,
                              currentStep: 3,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Seleção de exercícios',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Adicione os exercícios planejados\npara esta sessão de treinamento.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 46),
                            AppAddItemButton(
                              buttonKey: const Key(
                                'open-exercise-gallery-button',
                              ),
                              label: 'Adicionar da galeria',
                              onPressed: _openGallery,
                            ),
                            const SizedBox(height: 16),
                            AppAddItemButton(
                              buttonKey: const Key(
                                'create-training-exercise-button',
                              ),
                              label: 'Criar exercício',
                              onPressed: _openExerciseCreation,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Exercícios selecionados:',
                              style: textTheme.titleLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (_selectedExercises.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Text(
                                  'Nenhum',
                                  key: const Key('empty-selected-exercises'),
                                  textAlign: TextAlign.center,
                                  style: textTheme.headlineSmall?.copyWith(
                                    fontSize: 20,
                                    color: AppColors.text,
                                  ),
                                ),
                              )
                            else
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (
                                    var index = 0;
                                    index < _selectedExercises.length;
                                    index++
                                  ) ...[
                                    SelectedTrainingExerciseCard(
                                      key: ValueKey(
                                        'selected-training-exercise-$index',
                                      ),
                                      exercise: _selectedExercises[index],
                                      removeKey: ValueKey(
                                        'remove-selected-training-exercise-$index',
                                      ),
                                      onRemove: () => _removeExercise(index),
                                    ),
                                    if (index < _selectedExercises.length - 1)
                                      const SizedBox(height: 14),
                                  ],
                                ],
                              ),
                            const SizedBox(height: 44),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-training-exercises',
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
