// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Seletor de nascimento separado do coordenador.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import '../utils/horse_date_format.dart';

class HorseBirthDateStep extends StatelessWidget {
  const HorseBirthDateStep({
    required this.value,
    required this.onSelect,
    super.key,
  });

  final DateTime? value;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const ValueKey('horse-birth-date'),
    onTap: onSelect,
    child: InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Data de nascimento',
        suffixIcon: Icon(Symbols.event, color: AppColors.seaGreen),
      ),
      child: Text(formatHorseDate(value)),
    ),
  );
}
