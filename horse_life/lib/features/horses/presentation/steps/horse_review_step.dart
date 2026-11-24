// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Reestruturação visual da etapa de revisão para alinhar aos protótipos:
// campos Nome, Microchip, Data (com ícone de evento), Raça, Pelagem, Sexo e
// Modalidade com atalhos de edição, seguidos por "Informações adicionadas" e
// seções modulares usando AppReviewSection e AppRemovableItemTile.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Resumo de cadastro e botões editar isolados em uma etapa.
// -----------------------------------------------------------------------------

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';
import 'package:horse_life/core/widgets/app_item_list_widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../application/states/horse_registration_step.dart';
import '../../data/models/horse_registration_draft.dart';
import '../widgets/horse_registration_review_widgets.dart';

class HorseReviewStep extends StatelessWidget {
  const HorseReviewStep({
    required this.draft,
    required this.onEdit,
    required this.onRemoveImage,
    required this.onRemoveLimitation,
    required this.onRemoveHealth,
    required this.onRemoveInjury,
    super.key,
  });

  final HorseRegistrationDraft draft;
  final ValueChanged<HorseRegistrationStep> onEdit;
  final ValueChanged<XFile> onRemoveImage;
  final ValueChanged<String> onRemoveLimitation;
  final ValueChanged<String> onRemoveHealth;
  final ValueChanged<HorseInjury> onRemoveInjury;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void edit(int index) => onEdit(HorseRegistrationStep.values[index]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          value: draft.birthDate == null ? '' : formatAppDate(draft.birthDate),
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
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 20),
        AppReviewSection(
          title: 'Imagens',
          emptyMessage: 'Nenhuma imagem adicionada.',
          children: [
            for (final file in List<XFile>.of(draft.images))
              AppRemovableItemTile(
                key: ValueKey('review-horse-image-${file.name}'),
                icon: Symbols.image,
                iconColor: AppColors.seaGreen,
                label: file.name,
                removeKey: ValueKey('remove-review-horse-image-${file.name}'),
                onRemove: () => onRemoveImage(file),
              ),
          ],
        ),
        const SizedBox(height: 24),
        AppReviewSection(
          title: 'Limitações físicas',
          emptyMessage: 'Nenhuma limitação física adicionada.',
          children: [
            for (var index = 0;
                index < draft.physicalLimitations.length;
                index++)
              AppRemovableItemTile(
                key: ValueKey('review-horse-limitation-$index'),
                icon: Symbols.do_not_touch,
                iconColor: AppColors.seaGreen,
                label: draft.physicalLimitations[index],
                maxLines: null,
                removeKey: ValueKey('remove-review-horse-limitation-$index'),
                onRemove: () =>
                    onRemoveLimitation(draft.physicalLimitations[index]),
              ),
          ],
        ),
        const SizedBox(height: 24),
        AppReviewSection(
          title: 'Observações de saúde',
          emptyMessage: 'Nenhuma observação de saúde adicionada.',
          children: [
            for (var index = 0; index < draft.healthNotes.length; index++)
              AppRemovableItemTile(
                key: ValueKey('review-horse-health-$index'),
                icon: Symbols.health_metrics,
                iconColor: AppColors.seaGreen,
                label: draft.healthNotes[index],
                maxLines: null,
                removeKey: ValueKey('remove-review-horse-health-$index'),
                onRemove: () => onRemoveHealth(draft.healthNotes[index]),
              ),
          ],
        ),
        const SizedBox(height: 24),
        AppReviewSection(
          title: 'Histórico de lesões',
          emptyMessage: 'Nenhum histórico de lesão adicionado.',
          children: [
            for (var index = 0; index < draft.injuries.length; index++)
              AppRemovableItemTile(
                key: ValueKey('review-horse-injury-$index'),
                icon: Symbols.rheumatology,
                iconColor: AppColors.seaGreen,
                removeKey: ValueKey('remove-review-horse-injury-$index'),
                onRemove: () => onRemoveInjury(draft.injuries[index]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatAppDate(draft.injuries[index].date),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      draft.injuries[index].description,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    if (draft.injuries[index].prescription != null &&
                        draft.injuries[index].prescription!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        draft.injuries[index].prescription!.trim(),
                        style: theme.textTheme.bodyMedium?.copyWith(
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
      ],
    );
  }
}
