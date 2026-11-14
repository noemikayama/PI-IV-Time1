// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela autônoma de limitações físicas do cavalo (etapa 9 de 12),
// integrando FormProgressIndicator, AuthHeader, AppAddItemButton, AppRemovableItemTile
// com ícone Symbols.do_not_touch e botão Seguinte.
// -----------------------------------------------------------------------------

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
import '../widgets/horse_text_entry_dialog.dart';
import 'horse_health_notes_screen.dart';

typedef HorseLimitationsCallback = void Function(HorseRegistrationDraft draft);

/// Etapa 9 de 12: Inclusão e listagem de limitações físicas do cavalo.
class HorseLimitationsScreen extends StatefulWidget {
  const HorseLimitationsScreen({
    required this.draft,
    this.repository,
    this.microchipValidator,
    this.controller,
    this.imageSelection = const HorseImageSelectionService(),
    this.onContinue,
    this.onBack,
    super.key,
  });

  final HorseRegistrationDraft draft;
  final HorseRegistrationRepository? repository;
  final HorseMicrochipValidator? microchipValidator;
  final HorseRegistrationController? controller;
  final HorseImageSelectionService imageSelection;
  final HorseLimitationsCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<HorseLimitationsScreen> createState() => _HorseLimitationsScreenState();
}

class _HorseLimitationsScreenState extends State<HorseLimitationsScreen> {
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  Future<void> _addLimitation() async {
    final value = await showHorseTextEntryDialog(
      context,
      title: 'Adicionar limitação',
    );
    if (!mounted || value == null || value.isEmpty) return;
    if (widget.draft.physicalLimitations.length >= 30) {
      await showHorseRegistrationNotice(
        context,
        title: 'Limite atingido',
        message: 'São permitidos até 30 registros nesta seção.',
      );
    } else {
      setState(() => widget.draft.physicalLimitations.add(value));
    }
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
        builder: (context) => HorseHealthNotesScreen(
          draft: widget.draft,
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          controller: widget.controller,
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
    final items = widget.draft.physicalLimitations;

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
                              currentStep: 9,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Limitações físicas',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Informe se seu animal possui alguma lesão que possa '
                              'impossibilitá-lo de realizar algum tipo de exercício.\n'
                              'Você pode preencher isso mais tarde, se preferir.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            AppAddItemButton(
                              buttonKey: const Key(
                                'horse-add-limitation-button',
                              ),
                              label: 'Adicionar limitação',
                              onPressed: _addLimitation,
                            ),
                            if (items.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              for (
                                var index = 0;
                                index < items.length;
                                index++
                              ) ...[
                                AppRemovableItemTile(
                                  key: ValueKey('horse-note-$index'),
                                  icon: Symbols.do_not_touch,
                                  iconColor: AppColors.seaGreen,
                                  label: items[index],
                                  maxLines: null,
                                  removeKey: ValueKey(
                                    'remove-horse-note-$index',
                                  ),
                                  onRemove: () => setState(
                                    () => items.removeAt(index),
                                  ),
                                ),
                                if (index < items.length - 1)
                                  const SizedBox(height: 12),
                              ],
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
