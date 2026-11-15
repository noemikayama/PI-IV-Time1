// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Desacoplamento da submissão com HorseRegistrationController,
// isolando completamente as regras de persistência e repositório da tela.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela autônoma de revisão final e submissão do cadastro de
// cavalos (etapa 12 de 12), integrando FormProgressIndicator, AuthHeader,
// campos de revisão com atalhos de edição, seções dinâmicas e botão "Cadastrar cavalo".
// -----------------------------------------------------------------------------

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';
import 'package:horse_life/core/widgets/app_item_list_widgets.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../application/controllers/horse_registration_controller.dart';
import '../../application/states/horse_registration_step.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../data/repositories/horse_registration_repository.dart';
import '../../horse_registration_composition.dart';
import '../services/horse_image_selection_service.dart';
import '../widgets/horse_registration_alert.dart';
import '../widgets/horse_registration_review_widgets.dart';
import 'horse_birth_date_screen.dart';
import 'horse_breed_screen.dart';
import 'horse_coat_screen.dart';
import 'horse_microchip_screen.dart';
import 'horse_modality_screen.dart';
import 'horse_name_screen.dart';
import 'horse_sex_screen.dart';

typedef HorseReviewSubmittedCallback =
    void Function(HorseRegistrationResult result);

/// Etapa 12 de 12: Revisão de todos os dados do animal e submissão do cadastro.
class HorseReviewScreen extends StatefulWidget {
  const HorseReviewScreen({
    required this.draft,
    this.controller,
    this.repository,
    this.microchipValidator,
    this.imageSelection = const HorseImageSelectionService(),
    this.onSubmitted,
    this.onBack,
    super.key,
  });

  final HorseRegistrationDraft draft;
  final HorseRegistrationController? controller;
  final HorseRegistrationRepository? repository;
  final HorseMicrochipValidator? microchipValidator;
  final HorseImageSelectionService imageSelection;
  final HorseReviewSubmittedCallback? onSubmitted;
  final VoidCallback? onBack;

  @override
  State<HorseReviewScreen> createState() => _HorseReviewScreenState();
}

class _HorseReviewScreenState extends State<HorseReviewScreen> {
  late final HorseRegistrationController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        HorseRegistrationComposition.productionController(
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          initialDraft: widget.draft,
        );
  }

  void _goBack() {
    if (_isSubmitting) return;
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  Future<void> _editStep(HorseRegistrationStep step) async {
    Widget buildTargetScreen() {
      return switch (step) {
        HorseRegistrationStep.name => HorseNameScreen(
          draft: widget.draft,
          controller: _controller,
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          imageSelection: widget.imageSelection,
          onContinue: (_) {
            Navigator.pop(context);
            setState(() {});
          },
        ),
        HorseRegistrationStep.microchip => HorseMicrochipScreen(
          draft: widget.draft,
          controller: _controller,
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          imageSelection: widget.imageSelection,
          onContinue: (_) {
            Navigator.pop(context);
            setState(() {});
          },
        ),
        HorseRegistrationStep.birthDate => HorseBirthDateScreen(
          draft: widget.draft,
          controller: _controller,
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          imageSelection: widget.imageSelection,
          onContinue: (_) {
            Navigator.pop(context);
            setState(() {});
          },
        ),
        HorseRegistrationStep.breed => HorseBreedScreen(
          draft: widget.draft,
          controller: _controller,
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          imageSelection: widget.imageSelection,
          onContinue: (_) {
            Navigator.pop(context);
            setState(() {});
          },
        ),
        HorseRegistrationStep.coat => HorseCoatScreen(
          draft: widget.draft,
          controller: _controller,
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          imageSelection: widget.imageSelection,
          onContinue: (_) {
            Navigator.pop(context);
            setState(() {});
          },
        ),
        HorseRegistrationStep.sex => HorseSexScreen(
          draft: widget.draft,
          controller: _controller,
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          imageSelection: widget.imageSelection,
          onContinue: (_) {
            Navigator.pop(context);
            setState(() {});
          },
        ),
        HorseRegistrationStep.modality => HorseModalityScreen(
          draft: widget.draft,
          controller: _controller,
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          imageSelection: widget.imageSelection,
          onContinue: (_) {
            Navigator.pop(context);
            setState(() {});
          },
        ),
        _ => const SizedBox.shrink(),
      };
    }

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => buildTargetScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final result = await _controller.register(widget.draft);
      if (!mounted) return;

      final onSubmitted = widget.onSubmitted;
      if (onSubmitted != null) {
        onSubmitted(result);
        return;
      }

      Navigator.pop(context, result);
    } on HorseRegistrationFailure catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await showHorseRegistrationNotice(
        context,
        title: 'Cadastro não realizado',
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await showHorseRegistrationNotice(
        context,
        title: 'Falha no cadastro',
        message:
            'Não foi possível concluir o cadastro. Verifique sua conexão e tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final draft = widget.draft;

    void edit(int index) => _editStep(HorseRegistrationStep.values[index]);

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
                    AuthHeader(onBack: _isSubmitting ? () {} : _goBack),
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
                              currentStep: 12,
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
                              'Confira se todas as informações estão corretas antes de continuar.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            HorseRegistrationReviewField(
                              label: 'Nome',
                              value: draft.name,
                              step: 1,
                              onEdit: edit,
                            ),
                            HorseRegistrationReviewField(
                              label: 'Microchip',
                              value: draft.microchip,
                              step: 2,
                              onEdit: edit,
                            ),
                            HorseRegistrationReviewField(
                              label: 'DD/MM/AAAA',
                              value: draft.birthDate == null
                                  ? ''
                                  : formatAppDate(draft.birthDate),
                              step: 3,
                              icon: Symbols.event,
                              onEdit: edit,
                            ),
                            HorseRegistrationReviewField(
                              label: 'Raça',
                              value: draft.breed,
                              step: 4,
                              onEdit: edit,
                            ),
                            HorseRegistrationReviewField(
                              label: 'Pelagem',
                              value: draft.coat,
                              step: 5,
                              onEdit: edit,
                            ),
                            HorseRegistrationReviewField(
                              label: 'Sexo',
                              value: draft.sex.label,
                              step: 6,
                              onEdit: edit,
                            ),
                            HorseRegistrationReviewField(
                              label: 'Modalidade',
                              value: draft.modality?.name ?? '',
                              step: 8,
                              onEdit: edit,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Informações adicionadas',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppReviewSection(
                              title: 'Imagens',
                              emptyMessage: 'Nenhuma imagem adicionada.',
                              children: [
                                for (final file in List<XFile>.of(draft.images))
                                  AppRemovableItemTile(
                                    key: ValueKey('review-image-${file.name}'),
                                    icon: Symbols.image,
                                    iconColor: AppColors.seaGreen,
                                    label: file.name,
                                    removeKey: ValueKey(
                                      'remove-review-image-${file.name}',
                                    ),
                                    onRemove: () => setState(
                                      () => draft.images.remove(file),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            AppReviewSection(
                              title: 'Limitações físicas',
                              emptyMessage:
                                  'Nenhuma limitação física adicionada.',
                              children: [
                                for (final item
                                    in List<String>.of(draft.physicalLimitations))
                                  AppRemovableItemTile(
                                    key: ValueKey('review-limitation-$item'),
                                    icon: Symbols.do_not_touch,
                                    iconColor: AppColors.seaGreen,
                                    label: item,
                                    removeKey: ValueKey(
                                      'remove-review-limitation-$item',
                                    ),
                                    onRemove: () => setState(
                                      () => draft.physicalLimitations.remove(item),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            AppReviewSection(
                              title: 'Observações de saúde',
                              emptyMessage:
                                  'Nenhuma observação de saúde adicionada.',
                              children: [
                                for (final item
                                    in List<String>.of(draft.healthNotes))
                                  AppRemovableItemTile(
                                    key: ValueKey('review-health-$item'),
                                    icon: Symbols.health_metrics,
                                    iconColor: AppColors.seaGreen,
                                    label: item,
                                    removeKey: ValueKey(
                                      'remove-review-health-$item',
                                    ),
                                    onRemove: () => setState(
                                      () => draft.healthNotes.remove(item),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            AppReviewSection(
                              title: 'Histórico de lesões',
                              emptyMessage: 'Nenhuma lesão adicionada.',
                              children: [
                                for (final injury
                                    in List<HorseInjury>.of(draft.injuries))
                                  AppRemovableItemTile(
                                    key: ValueKey(
                                      'review-injury-${injury.description}',
                                    ),
                                    icon: Symbols.rheumatology,
                                    iconColor: AppColors.seaGreen,
                                    removeKey: ValueKey(
                                      'remove-review-injury-${injury.description}',
                                    ),
                                    onRemove: () => setState(
                                      () => draft.injuries.remove(injury),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          formatAppDate(injury.date),
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                fontSize: 15,
                                                color: AppColors.text,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          injury.description,
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.text,
                                              ),
                                        ),
                                        if (injury.prescription != null &&
                                            injury.prescription!
                                                .trim()
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            injury.prescription!.trim(),
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
                              ],
                            ),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-horse-registration',
                              ),
                              label: 'Cadastrar cavalo',
                              isLoading: _isSubmitting,
                              onPressed: _isSubmitting ? null : _submit,
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
