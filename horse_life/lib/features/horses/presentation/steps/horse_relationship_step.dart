// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adaptação visual da etapa para utilizar AppDropdownField com
// estilo arredondado e InformationRow compartilhados de core/widgets.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Etapa de vínculo extraída da tela principal.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_dropdown_field.dart';
import 'package:horse_life/core/widgets/information_row.dart';

import '../../data/models/horse_registration_draft.dart';

class HorseRelationshipStep extends StatefulWidget {
  const HorseRelationshipStep({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final HorseRelationship value;
  final ValueChanged<HorseRelationship> onChanged;

  @override
  State<HorseRelationshipStep> createState() => _HorseRelationshipStepState();
}

class _HorseRelationshipStepState extends State<HorseRelationshipStep> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDropdownField<HorseRelationship>(
          style: AppDropdownStyle.rounded,
          label: 'Selecionar relacionamento',
          dropdownKey: const ValueKey('horse-select-Relação com o cavalo'),
          value: widget.value,
          options: HorseRelationship.values,
          labelFor: (item) => item.label,
          isOpen: _isMenuOpen,
          onTap: () => setState(() => _isMenuOpen = true),
          onChanged: (value) {
            setState(() => _isMenuOpen = false);
            widget.onChanged(value);
          },
        ),
        const SizedBox(height: 36),
        const InformationRow(
          text:
              'Proprietários são capazes de cadastrar e gerenciar os dados dos '
              'cavalos e seus treinos, mas não podem executá-los.',
        ),
        const SizedBox(height: 24),
        const InformationRow(
          text:
              'Atletas não têm permissão de cadastro ou edição dos dados do '
              'animal, mas podem executar os treinos prescritos para ele.',
        ),
        const SizedBox(height: 24),
        const InformationRow(
          text:
              'Proprietários que também são atletas, por outro lado, possuem '
              'ambos os privilégios dos tipos de relacionamentos citados acima.',
        ),
      ],
    );
  }
}
