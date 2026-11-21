// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adaptação visual da seleção de sexo para utilizar o componente
// reutilizável AppDropdownField com estilo arredondado (AppDropdownStyle.rounded),
// rótulo flutuante "Selecionar sexo" e opções "Fêmea" e "Macho".
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Campo de sexo isolado e dropdown compartilhado preservado.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_dropdown_field.dart';

import '../../data/models/horse_registration_draft.dart';

class HorseSexStep extends StatefulWidget {
  const HorseSexStep({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final HorseSex value;
  final ValueChanged<HorseSex> onChanged;

  @override
  State<HorseSexStep> createState() => _HorseSexStepState();
}

class _HorseSexStepState extends State<HorseSexStep> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return AppDropdownField<HorseSex>(
      style: AppDropdownStyle.rounded,
      label: 'Selecionar sexo',
      dropdownKey: const ValueKey('horse-select-Sexo'),
      value: widget.value,
      options: HorseSex.values,
      labelFor: (item) => item.label,
      isOpen: _isMenuOpen,
      onTap: () => setState(() => _isMenuOpen = true),
      onChanged: (value) {
        setState(() => _isMenuOpen = false);
        widget.onChanged(value);
      },
    );
  }
}
