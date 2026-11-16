// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Substituição do seletor local pelo componente padronizado
// AppDatePickerField proveniente de core/widgets.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Seletor de nascimento separado do coordenador.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';

class HorseBirthDateStep extends StatelessWidget {
  const HorseBirthDateStep({
    required this.value,
    required this.onSelect,
    super.key,
  });

  final DateTime? value;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => AppDatePickerField(
    key: const ValueKey('horse-birth-date'),
    value: value,
    hintText: 'DD/MM/AAAA',
    onTap: onSelect,
  );
}
