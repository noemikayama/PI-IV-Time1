// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 09/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Reutilização do AppDropdownField compartilhado com o treinador.
// Mantidos a API e o estilo da feature para não alterar as demais telas.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Seleção reutilizável com destaque verde e check do protótipo.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_dropdown_field.dart';

/// Adaptador que mantém a assinatura usada no cadastro de cavalos.
class HorseChoiceField<T> extends StatelessWidget {
  const HorseChoiceField({
    required this.label,
    required this.value,
    required this.options,
    required this.name,
    required this.onChanged,
    super.key,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T) name;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => AppDropdownField<T>(
    label: label,
    dropdownKey: ValueKey('horse-select-$label'),
    value: value,
    options: options,
    labelFor: name,
    onChanged: onChanged,
  );
}
