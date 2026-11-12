// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Campo de sexo isolado e dropdown compartilhado preservado.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../data/models/horse_registration_draft.dart';
import '../widgets/horse_choice_field.dart';

class HorseSexStep extends StatelessWidget {
  const HorseSexStep({required this.value, required this.onChanged, super.key});

  final HorseSex value;
  final ValueChanged<HorseSex> onChanged;

  @override
  Widget build(BuildContext context) => HorseChoiceField<HorseSex>(
    label: 'Sexo',
    value: value,
    options: HorseSex.values,
    name: (item) => item.label,
    onChanged: onChanged,
  );
}
