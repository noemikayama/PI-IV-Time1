// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Desacoplamento da persistência e estado com HorseRegistrationController,
// repassando o rascunho e o controlador através da navegação para as lesões.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela autônoma de observações de saúde do cavalo (etapa 10 de 12),
// integrando FormProgressIndicator, AuthHeader, AppAddItemButton, AppRemovableItemTile
// com ícone Symbols.health_metrics e botão Seguinte.
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
import 'horse_injuries_screen.dart';

typedef HorseHealthNotesCallback = void Function(HorseRegistrationDraft draft);

/// Etapa 10 de 12: Inclusão e listagem de observações de saúde do cavalo.
class HorseHealthNotesScreen extends StatefulWidget {
  const HorseHealthNotesScreen({
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
  final HorseHealthNotesCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<HorseHealthNotesScreen> createState() => _HorseHealthNotesScreenState();
}

class _HorseHealthNotesScreenState extends State<HorseHealthNotesScreen> {
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  Future<void> _addHealthNote() async {
    final value = await showHorseTextEntryDialog(
      context,
      title: 'Adicionar observação',
    );
    if (!mounted || value == null || value.isEmpty) return;
    if (widget.draft.healthNotes.length >= 30) {
      await showHorseRegistrationNotice(
        context,
        title: 'Limite atingido',
        message: 'São permitidos até 30 registros nesta seção.',
      );
    } else {
      setState(() => widget.draft.healthNotes.add(value));
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
        builder: (context) => HorseInjuriesScreen(
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
    final items = widget.draft.healthNotes;

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
                              currentStep: 10,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Observações de saúde',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Adicione informações importantes para quem for '
                              'treinar este animal saber como manuseá-lo de forma correta.\n'
                              'Você pode preencher isso mais tarde, se preferir.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            AppAddItemButton(
                              buttonKey: const Key('horse-add-health-button'),
                              label: 'Adicionar observação',
                              onPressed: _addHealthNote,
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
                                  icon: Symbols.health_metrics,
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
