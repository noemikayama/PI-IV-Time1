// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Desacoplamento da persistência e estado com HorseRegistrationController,
// repassando o rascunho e o controlador através da navegação para a modalidade.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela autônoma de adição e gerenciamento de imagens do cavalo
// (etapa 7 de 12), integrando FormProgressIndicator, AuthHeader, AppAddItemButton,
// AppRemovableItemTile com rolagem e botão Seguinte.
// -----------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_item_list_widgets.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../application/controllers/horse_registration_controller.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../data/repositories/horse_registration_repository.dart';
import '../services/horse_image_selection_service.dart';
import '../widgets/horse_registration_alert.dart';
import 'horse_modality_screen.dart';

typedef HorseImagesCallback = void Function(HorseRegistrationDraft draft);

/// Etapa 7 de 12: Seleção e remoção de imagens do cavalo.
class HorseImagesScreen extends StatefulWidget {
  const HorseImagesScreen({
    required this.draft,
    this.controller,
    this.repository,
    this.microchipValidator,
    this.imageSelection = const HorseImageSelectionService(),
    this.onContinue,
    this.onBack,
    super.key,
  });

  final HorseRegistrationDraft draft;
  final HorseRegistrationController? controller;
  final HorseRegistrationRepository? repository;
  final HorseMicrochipValidator? microchipValidator;
  final HorseImageSelectionService imageSelection;
  final HorseImagesCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<HorseImagesScreen> createState() => _HorseImagesScreenState();
}

class _HorseImagesScreenState extends State<HorseImagesScreen> {
  static const _itemHeight = 64.0;
  static const _itemSpacing = 12.0;
  static const _maximumVisibleItems = 3;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
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

  Future<void> _selectImages() async {
    try {
      final selected = await widget.imageSelection.select(
        currentCount: widget.draft.images.length,
      );
      if (!mounted) return;
      setState(() => widget.draft.images.addAll(selected.accepted));
      if (selected.rejected > 0) {
        await showHorseRegistrationNotice(
          context,
          title: 'Algumas imagens foram ignoradas',
          message:
              'São permitidas até 10 imagens JPG ou PNG, com no máximo 5 MB por arquivo.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      await showHorseRegistrationNotice(
        context,
        title: 'Não foi possível abrir os arquivos',
        message: 'Tente novamente ou avance sem imagens.',
      );
    }
  }

  Widget _buildImageList(BuildContext context) {
    final visibleCount = math.min(
      widget.draft.images.length,
      _maximumVisibleItems,
    );
    final listHeight =
        visibleCount * _itemHeight + (visibleCount - 1) * _itemSpacing;

    return SizedBox(
      key: const Key('horse-images-list'),
      height: listHeight,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: widget.draft.images.length >= _maximumVisibleItems,
        child: ListView.separated(
          controller: _scrollController,
          primary: false,
          padding: EdgeInsets.only(
            right: widget.draft.images.length >= _maximumVisibleItems ? 14 : 0,
          ),
          itemCount: widget.draft.images.length,
          separatorBuilder: (_, _) => const SizedBox(height: _itemSpacing),
          itemBuilder: (context, index) {
            final file = widget.draft.images[index];
            return AppRemovableItemTile(
              key: ValueKey('horse-image-item-$index'),
              icon: Symbols.image,
              iconColor: AppColors.seaGreen,
              label: file.name,
              removeKey: ValueKey('remove-horse-image-${file.name}'),
              onRemove: () => setState(() => widget.draft.images.remove(file)),
            );
          },
        ),
      ),
    );
  }

  Future<void> _continue() async {
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(widget.draft);
      return;
    }

    final result = await Navigator.push<HorseRegistrationResult>(
      context,
      MaterialPageRoute<HorseRegistrationResult>(
        builder: (context) => HorseModalityScreen(
          draft: widget.draft,
          controller: widget.controller,
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          imageSelection: widget.imageSelection,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
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
                              configuration:
                                  FormProgressConfiguration.horseRegistration,
                              currentStep: 7,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Imagens',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Adicione imagens que facilitem o\n'
                              'reconhecimento do animal.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            AppAddItemButton(
                              buttonKey: const Key('horse-add-image-button'),
                              label: 'Adicionar imagem',
                              semanticsLabel: 'Adicionar imagens do cavalo',
                              onPressed: _selectImages,
                            ),
                            if (widget.draft.images.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildImageList(context),
                            ],
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-horse-registration',
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
