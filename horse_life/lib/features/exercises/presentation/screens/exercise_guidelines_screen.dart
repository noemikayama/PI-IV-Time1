// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da etapa de orientações do exercício, permitindo adicionar,
// listar e remover instruções de execução e cuidados antes de avançar para a
// etapa de duração padrão.
// -----------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../authentication/presentation/widgets/auth_header.dart';
import '../../../authentication/presentation/widgets/auth_next_button.dart';
import '../../application/controllers/exercise_registration_controller.dart';
import '../../application/states/exercise_registration_draft.dart';
import '../widgets/add_exercise_guideline_dialog.dart';
import '../widgets/exercise_item_list_widgets.dart';
import '../widgets/exercise_progress_indicator.dart';
import 'exercise_duration_screen.dart';

typedef ExerciseGuidelinesCallback =
    void Function(ExerciseRegistrationDraft draft);

// Etapa de orientações de execução do exercício, operando como etapa 3 de 7
// no fluxo genérico ou etapa 4 de 8 no fluxo específico.
class ExerciseGuidelinesScreen extends StatefulWidget {
  const ExerciseGuidelinesScreen({
    required this.draft,
    this.registrationController,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final ExerciseRegistrationDraft draft;
  final ExerciseRegistrationController? registrationController;
  final ExerciseGuidelinesCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<ExerciseGuidelinesScreen> createState() =>
      _ExerciseGuidelinesScreenState();
}

class _ExerciseGuidelinesScreenState extends State<ExerciseGuidelinesScreen> {
  // Altura estimada para exibir confortavelmente até três itens antes da rolagem.
  static const _itemMinHeight = 76.0;
  static const _itemSpacing = 14.0;
  static const _maximumVisibleItems = 3;

  final ScrollController _guidelinesScrollController = ScrollController();
  late final List<String> _guidelines;

  ExerciseProgressConfiguration get _progressConfiguration =>
      switch (widget.draft) {
        GenericExerciseRegistrationDraft() =>
          ExerciseProgressConfiguration.generic,
        SpecificExerciseRegistrationDraft() =>
          ExerciseProgressConfiguration.specific,
      };

  int get _currentStep => switch (widget.draft) {
    GenericExerciseRegistrationDraft() => 3,
    SpecificExerciseRegistrationDraft() => 4,
  };

  @override
  void initState() {
    super.initState();
    _guidelines = List.of(widget.draft.guidelines);
  }

  @override
  void dispose() {
    _guidelinesScrollController.dispose();
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

  // Abre o modal de adição e inclui a nova orientação se não for duplicada.
  Future<void> _addGuideline() async {
    final guideline = await showAddExerciseGuidelineDialog(context);
    if (!mounted || guideline == null || guideline.trim().isEmpty) return;

    final normalized = guideline.trim();
    if (_guidelines.any(
      (existing) => existing.toLowerCase() == normalized.toLowerCase(),
    )) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.info_outline_rounded,
        message: 'Essa orientação já foi adicionada.',
      );
      return;
    }

    setState(() => _guidelines.add(normalized));
  }

  void _removeGuideline(int index) {
    setState(() => _guidelines.removeAt(index));
  }

  // Consolida as orientações no draft e avança para a etapa de duração padrão.
  void _continue() {
    final updatedDraft = widget.draft.withGuidelines(_guidelines);
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ExerciseDurationScreen(
          draft: updatedDraft,
          registrationController: widget.registrationController,
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
                            ExerciseProgressIndicator(
                              configuration: _progressConfiguration,
                              currentStep: _currentStep,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Orientações do exercício',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Adicione detalhes de como o\n'
                              'exercício deve ser feito e quais\n'
                              'cuidados devem ser tomados.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 46),
                            _buildAddButton(context),
                            if (_guidelines.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildGuidelinesList(context),
                            ],
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-exercise-guidelines',
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

  // Botão cinza arredondado para acionar o modal de inclusão de orientação.
  Widget _buildAddButton(BuildContext context) {
    return ExerciseAddItemButton(
      buttonKey: const Key('add-exercise-guideline'),
      label: 'Adicionar orientação',
      onPressed: _addGuideline,
    );
  }

  // Exibe os cards de orientações adicionadas com opção de exclusão individual.
  Widget _buildGuidelinesList(BuildContext context) {
    final visibleCount = math.min(_guidelines.length, _maximumVisibleItems);
    final maxHeight =
        visibleCount * _itemMinHeight + (visibleCount - 1) * _itemSpacing;
    final isScrollable = _guidelines.length > _maximumVisibleItems;

    final listView = ListView.separated(
      controller: _guidelinesScrollController,
      shrinkWrap: !isScrollable,
      physics: isScrollable
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      primary: false,
      padding: EdgeInsets.only(right: isScrollable ? 14 : 0),
      itemCount: _guidelines.length,
      separatorBuilder: (_, _) => const SizedBox(height: _itemSpacing),
      itemBuilder: (context, index) {
        final guideline = _guidelines[index];
        return ExerciseRemovableItemTile(
          key: ValueKey('exercise-guideline-item-$index'),
          icon: Icons.chat_bubble_outline_rounded,
          label: guideline,
          minHeight: _itemMinHeight,
          maxLines: null,
          removeKey: ValueKey('remove-exercise-guideline-$index'),
          onRemove: () => _removeGuideline(index),
        );
      },
    );

    if (!isScrollable) {
      return listView;
    }

    return SizedBox(
      key: const Key('exercise-guidelines-list'),
      height: maxHeight,
      child: Scrollbar(
        controller: _guidelinesScrollController,
        thumbVisibility: true,
        child: listView,
      ),
    );
  }
}
