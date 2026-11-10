// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Histórico de lesões separado do coordenador do cadastro.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../data/models/horse_registration_draft.dart';
import '../utils/horse_date_format.dart';
import '../widgets/horse_add_button.dart';
import '../widgets/horse_registration_entry_tile.dart';
import '../widgets/horse_registration_pictogram.dart';

class HorseInjuriesStep extends StatelessWidget {
  const HorseInjuriesStep({
    required this.injuries,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  final List<HorseInjury> injuries;
  final VoidCallback onAdd;
  final ValueChanged<HorseInjury> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HorseAddButton(label: 'Adicionar lesão', onPressed: onAdd),
      const SizedBox(height: 14),
      for (final injury in List<HorseInjury>.of(injuries))
        HorseRegistrationEntryTile(
          '${formatHorseDate(injury.date)}\n${injury.description}'
          '${injury.prescription == null || injury.prescription!.isEmpty ? '' : '\n${injury.prescription}'}',
          const HorseRegistrationPictogram(kind: HorsePictogram.injury),
          () => onRemove(injury),
        ),
    ],
  );
}
