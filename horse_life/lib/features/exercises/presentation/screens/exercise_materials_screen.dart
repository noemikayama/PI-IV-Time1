// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Validação do limite máximo de 30 materiais conforme contrato do backend.
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adoção dos widgets centralizados FormProgressIndicator,
// AppAddItemButton e AppRemovableItemTile provenientes de core/widgets.
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da etapa de materiais necessários e quantidades para a
// execução do exercício, operando como etapa 5 de 7 (genérico) ou etapa 6 de 8
// (específico), com navegação para a etapa de mídias auxiliares.
// -----------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_item_list_widgets.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/form_progress_indicator.dart';
import '../../../authentication/presentation/widgets/auth_header.dart';
import '../../../authentication/presentation/widgets/auth_next_button.dart';
import '../../application/controllers/exercise_registration_controller.dart';
import '../../application/states/exercise_material.dart';
import '../../application/states/exercise_registration_draft.dart';
import '../widgets/add_exercise_material_dialog.dart';
import 'exercise_media_screen.dart';

typedef ExerciseMaterialsCallback =
    void Function(ExerciseRegistrationDraft draft);

// Etapa dedicada aos materiais necessários para a execução do exercício,
// operando como etapa 5 de 7 no fluxo genérico ou etapa 6 de 8 no específico.
class ExerciseMaterialsScreen extends StatefulWidget {
  const ExerciseMaterialsScreen({
    required this.draft,
    this.registrationController,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final ExerciseRegistrationDraft draft;
  final ExerciseRegistrationController? registrationController;
  final ExerciseMaterialsCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<ExerciseMaterialsScreen> createState() =>
      _ExerciseMaterialsScreenState();
}

class _ExerciseMaterialsScreenState extends State<ExerciseMaterialsScreen> {
  static const _itemHeight = 64.0;
  static const _itemSpacing = 12.0;
  static const _maximumVisibleItems = 3;

  final ScrollController _materialsScrollController = ScrollController();
  late final List<ExerciseMaterial> _materials;

  FormProgressConfiguration get _progressConfiguration =>
      switch (widget.draft) {
        GenericExerciseRegistrationDraft() =>
          FormProgressConfiguration.genericExercise,
        SpecificExerciseRegistrationDraft() =>
          FormProgressConfiguration.specificExercise,
      };

  int get _currentStep => switch (widget.draft) {
    GenericExerciseRegistrationDraft() => 5,
    SpecificExerciseRegistrationDraft() => 6,
  };

  @override
  void initState() {
    super.initState();
    _materials = List.of(widget.draft.materials);
  }

  @override
  void dispose() {
    _materialsScrollController.dispose();
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

  // Abre o modal de inclusão de material e evita duplicações pelo nome.
  Future<void> _addMaterial() async {
    if (_materials.length >= 30) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.info_outline_rounded,
        message: 'Limite máximo de 30 materiais atingido.',
      );
      return;
    }

    final material = await showAddExerciseMaterialDialog(context);
    if (!mounted || material == null) return;

    final normalizedName = material.name.trim().toLowerCase();
    if (_materials.any(
      (existing) => existing.name.trim().toLowerCase() == normalizedName,
    )) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.info_outline_rounded,
        message: 'Esse material já foi adicionado.',
      );
      return;
    }

    setState(() => _materials.add(material));
  }

  void _removeMaterial(int index) {
    setState(() => _materials.removeAt(index));
  }

  // Consolida os materiais no draft e avança para a etapa de mídias auxiliares.
  void _continue() {
    final updatedDraft = widget.draft.withMaterials(_materials);
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ExerciseMediaScreen(
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
                            FormProgressIndicator(
                              configuration: _progressConfiguration,
                              currentStep: _currentStep,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Materiais necessários',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Informe quais materiais são\n'
                              'necessários para a\n'
                              'execução do exercício.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 46),
                            AppAddItemButton(
                              buttonKey: const Key('add-exercise-material'),
                              label: 'Adicionar materiais',
                              onPressed: _addMaterial,
                            ),
                            if (_materials.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildMaterialsList(context),
                            ],
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-exercise-materials',
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

  // Lista os materiais adicionados com rolagem interna quando há mais de 3 itens.
  Widget _buildMaterialsList(BuildContext context) {
    final visibleCount = math.min(_materials.length, _maximumVisibleItems);
    final listHeight =
        visibleCount * _itemHeight + (visibleCount - 1) * _itemSpacing;
    final isScrollable = _materials.length > _maximumVisibleItems;

    return SizedBox(
      key: const Key('exercise-materials-list'),
      height: listHeight,
      child: Scrollbar(
        controller: _materialsScrollController,
        thumbVisibility: isScrollable,
        child: ListView.separated(
          controller: _materialsScrollController,
          primary: false,
          padding: EdgeInsets.only(right: isScrollable ? 14 : 0),
          itemCount: _materials.length,
          separatorBuilder: (_, _) => const SizedBox(height: _itemSpacing),
          itemBuilder: (context, index) {
            final material = _materials[index];
            return AppRemovableItemTile(
              key: ValueKey('exercise-material-item-$index'),
              icon: Icons.handyman_outlined,
              label: material.displayLabel,
              removeKey: ValueKey('remove-exercise-material-$index'),
              onRemove: () => _removeMaterial(index),
            );
          },
        ),
      ),
    );
  }
}
