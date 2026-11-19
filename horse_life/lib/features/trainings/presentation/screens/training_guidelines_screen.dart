// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Validação obrigatória da inclusão de ao menos uma orientação no
// fluxo de cadastro de treinamentos, exibindo alerta via AppSnackBar em caso de lista vazia.
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da quarta etapa do cadastro de treinamentos (4 de 6),
// permitindo adicionar via modal, listar com rolagem limitada e remover
// orientações opcionais da sessão antes de avançar para duração estimada.
// -----------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_item_list_widgets.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../application/controllers/training_registration_controller.dart';
import '../../application/states/training_registration_draft.dart';
import '../widgets/add_training_guideline_dialog.dart';
import 'training_duration_screen.dart';

typedef TrainingGuidelinesCallback =
    void Function(TrainingRegistrationDraft draft);

/// Etapa 4 de 6: Adição de orientações opcionais para a sessão de treinamento.
class TrainingGuidelinesScreen extends StatefulWidget {
  const TrainingGuidelinesScreen({
    required this.draft,
    this.controller,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainingRegistrationDraft draft;
  final TrainingRegistrationController? controller;
  final TrainingGuidelinesCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<TrainingGuidelinesScreen> createState() =>
      _TrainingGuidelinesScreenState();
}

class _TrainingGuidelinesScreenState extends State<TrainingGuidelinesScreen> {
  // Altura estimada para exibir até três orientações antes de habilitar rolagem.
  static const _itemMinHeight = 76.0;
  static const _itemSpacing = 14.0;
  static const _maximumVisibleItems = 3;

  final ScrollController _guidelinesScrollController = ScrollController();
  late final List<String> _guidelines;

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

  Future<void> _addGuideline() async {
    if (_guidelines.length >= 30) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.info_outline_rounded,
        message: 'Limite máximo de 30 orientações atingido.',
      );
      return;
    }

    final guideline = await showAddTrainingGuidelineDialog(context);
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

  void _continue() {
    if (_guidelines.isEmpty) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Adicione pelo menos uma orientação para continuar.',
      );
      return;
    }

    final updatedDraft = widget.draft.withGuidelines(_guidelines);
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TrainingDurationScreen(
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
                              configuration: FormProgressConfiguration.training,
                              currentStep: 4,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Orientações do\ntreinamento',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Adicione detalhes úteis para a\n'
                              'realização desta sessão de\n'
                              'treinamento.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 46),
                            AppAddItemButton(
                              buttonKey: const Key('add-training-guideline'),
                              label: 'Adicionar orientação',
                              onPressed: _addGuideline,
                            ),
                            if (_guidelines.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildGuidelinesList(),
                            ],
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-training-guidelines',
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

  Widget _buildGuidelinesList() {
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
        return AppRemovableItemTile(
          key: ValueKey('training-guideline-item-$index'),
          icon: Icons.chat_bubble_outline_rounded,
          label: guideline,
          minHeight: _itemMinHeight,
          maxLines: null,
          removeKey: ValueKey('remove-training-guideline-$index'),
          onRemove: () => _removeGuideline(index),
        );
      },
    );

    if (!isScrollable) {
      return listView;
    }

    return SizedBox(
      key: const Key('training-guidelines-list'),
      height: maxHeight,
      child: Scrollbar(
        controller: _guidelinesScrollController,
        thumbVisibility: true,
        child: listView,
      ),
    );
  }
}
