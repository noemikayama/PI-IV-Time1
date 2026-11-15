// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Desacoplamento da persistência e estado com HorseRegistrationController,
// repassando o rascunho e o controlador através da navegação para a revisão final.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela autônoma de histórico de lesões do cavalo (etapa 11 de 12),
// integrando FormProgressIndicator, AuthHeader, AppAddItemButton, AppRemovableItemTile
// com ícone Symbols.rheumatology e botão Seguinte.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';
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
import '../widgets/horse_injury_dialog.dart';
import '../widgets/horse_registration_alert.dart';
import 'horse_review_screen.dart';

typedef HorseInjuriesCallback = void Function(HorseRegistrationDraft draft);

/// Etapa 11 de 12: Inclusão e listagem do histórico de lesões do cavalo.
class HorseInjuriesScreen extends StatefulWidget {
  const HorseInjuriesScreen({
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
  final HorseInjuriesCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<HorseInjuriesScreen> createState() => _HorseInjuriesScreenState();
}

class _HorseInjuriesScreenState extends State<HorseInjuriesScreen> {
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  Future<void> _addInjury() async {
    final injury = await showHorseInjuryDialog(
      context: context,
      birthDate: widget.draft.birthDate,
    );
    if (!mounted || injury == null) return;
    if (widget.draft.injuries.length >= 50) {
      await showHorseRegistrationNotice(
        context,
        title: 'Limite atingido',
        message: 'São permitidas até 50 lesões.',
      );
    } else {
      setState(() => widget.draft.injuries.add(injury));
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
        builder: (context) => HorseReviewScreen(
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final injuries = widget.draft.injuries;

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
                              currentStep: 11,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Histórico de lesões',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Adicione informações das lesões que este animal já sofreu.\n'
                              'Você pode preencher isso mais tarde, se preferir.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            AppAddItemButton(
                              buttonKey: const Key('horse-add-injury-button'),
                              label: 'Adicionar lesão',
                              onPressed: _addInjury,
                            ),
                            if (injuries.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              for (
                                var index = 0;
                                index < injuries.length;
                                index++
                              ) ...[
                                AppRemovableItemTile(
                                  key: ValueKey('horse-injury-$index'),
                                  icon: Symbols.rheumatology,
                                  iconColor: AppColors.seaGreen,
                                  removeKey: ValueKey(
                                    'remove-horse-injury-$index',
                                  ),
                                  onRemove: () => setState(
                                    () => injuries.removeAt(index),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        formatAppDate(injuries[index].date),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontSize: 15,
                                              color: AppColors.text,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        injuries[index].description,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.text,
                                            ),
                                      ),
                                      if (injuries[index].prescription !=
                                              null &&
                                          injuries[index].prescription!
                                              .trim()
                                              .isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          injuries[index].prescription!.trim(),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontSize: 15,
                                                color: AppColors.text,
                                              ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (index < injuries.length - 1)
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
