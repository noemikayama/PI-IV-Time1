// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Etapa de vínculo extraída da tela principal.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

import '../../data/models/horse_registration_draft.dart';
import '../widgets/horse_choice_field.dart';

class HorseRelationshipStep extends StatelessWidget {
  const HorseRelationshipStep({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final HorseRelationship value;
  final ValueChanged<HorseRelationship> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      HorseChoiceField<HorseRelationship>(
        label: 'Relação com o cavalo',
        value: value,
        options: HorseRelationship.values,
        name: (item) => item.label,
        onChanged: onChanged,
      ),
      const SizedBox(height: 28),
      const _RelationshipInfo('Proprietários são capazes de cadastrar e gerenciar os dados dos cavalos e seus treinos, mas não podem executá-los.'),
      const _RelationshipInfo('Atletas não têm permissão de cadastro ou edição dos dados do animal, mas podem executar os treinos prescritos para ele.'),
      const _RelationshipInfo('Proprietários que também são atletas possuem ambos os privilégios dos relacionamentos citados acima.'),
    ],
  );
}

class _RelationshipInfo extends StatelessWidget {
  const _RelationshipInfo(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: AppColors.seaGreen),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}
