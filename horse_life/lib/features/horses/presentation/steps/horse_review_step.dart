// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Resumo de cadastro e botões editar isolados em uma etapa.
// -----------------------------------------------------------------------------

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:horse_life/app/theme/app_colors.dart';

import '../../application/states/horse_registration_step.dart';
import '../../data/models/horse_registration_draft.dart';
import '../utils/horse_date_format.dart';
import '../widgets/horse_registration_entry_tile.dart';
import '../widgets/horse_registration_pictogram.dart';
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
    // Os componentes de revisão já usados pela Home recebem índices das etapas.
    void edit(int index) => onEdit(HorseRegistrationStep.values[index]);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HorseRegistrationReviewField('Relação', draft.relationship.label, 0, onEdit: edit),
        HorseRegistrationReviewField('Nome', draft.name, 1, onEdit: edit),
        HorseRegistrationReviewField('Microchip', draft.microchip, 2, onEdit: edit),
        HorseRegistrationReviewField('Nascimento', formatHorseDate(draft.birthDate), 3, onEdit: edit),
        HorseRegistrationReviewField('Raça', draft.breed, 4, onEdit: edit),
        HorseRegistrationReviewField('Pelagem', draft.coat, 5, onEdit: edit),
        HorseRegistrationReviewField('Sexo', draft.sex.label, 6, onEdit: edit),
        HorseRegistrationReviewField('Modalidade', draft.modality?.name ?? 'Sem modalidade', 8, onEdit: edit),
        const SizedBox(height: 26),
        Text('Informações adicionadas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        HorseRegistrationReviewSectionTitle('Imagens', 7, onEdit: edit),
        for (final file in List<XFile>.of(draft.images))
          HorseRegistrationEntryTile(file.name,
            const Icon(Symbols.image, size: 24, color: AppColors.blueSpruce),
            () => onRemoveImage(file)),
        HorseRegistrationReviewSectionTitle('Limitações físicas', 9, onEdit: edit),
        for (final item in List<String>.of(draft.physicalLimitations))
          HorseRegistrationEntryTile(item,
            const Icon(Symbols.do_not_touch, size: 24, color: AppColors.blueSpruce),
            () => onRemoveLimitation(item)),
        HorseRegistrationReviewSectionTitle('Observações de saúde', 10, onEdit: edit),
        for (final item in List<String>.of(draft.healthNotes))
          HorseRegistrationEntryTile(item,
            const HorseRegistrationPictogram(kind: HorsePictogram.health),
            () => onRemoveHealth(item)),
        HorseRegistrationReviewSectionTitle('Histórico de lesões', 11, onEdit: edit),
        for (final injury in List<HorseInjury>.of(draft.injuries))
          HorseRegistrationEntryTile('${formatHorseDate(injury.date)} • ${injury.description}',
            const HorseRegistrationPictogram(kind: HorsePictogram.injury),
            () => onRemoveInjury(injury)),
      ],
    );
  }
}
