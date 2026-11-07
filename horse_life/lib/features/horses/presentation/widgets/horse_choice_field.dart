// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Seleção reutilizável com destaque verde e check do protótipo.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Mantém a mesma seleção visual para relação, sexo e modalidade.
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
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      highlightColor: Colors.transparent,
      splashColor: AppColors.pearlAqua.withValues(alpha: 0.18),
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
    ),
    child: DropdownButtonFormField<T>(
      key: ValueKey('horse-select-$label'),
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppColors.whiteSmoke,
      borderRadius: BorderRadius.circular(10),
      menuMaxHeight: 370,
      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.prussianBlue),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.alabasterGray.withValues(alpha: 0.35),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.seaGreen, width: 2),
        ),
      ),
      selectedItemBuilder: (context) => [
        for (final item in options)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(name(item), overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.prussianBlue,
                fontWeight: FontWeight.w600)),
          ),
      ],
      items: [
        for (final item in options)
          DropdownMenuItem<T>(
            value: item,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: item == value ? AppColors.seaGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(children: [
                if (item == value) ...[
                  const Icon(Icons.check, color: Colors.white, size: 19),
                  const SizedBox(width: 5),
                ],
                Expanded(child: Text(name(item),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: item == value ? FontWeight.w700 : FontWeight.w500,
                    color: item == value ? Colors.white : AppColors.prussianBlue,
                  ),
                )),
              ]),
            ),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) onChanged(selected);
      },
    ),
  );
}
