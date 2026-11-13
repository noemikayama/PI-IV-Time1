// AUTORA: Gabriela Sichiroli Ferrari
// PROJETO: HorseLife
// CRIAÇÃO: 07/11/2026
// HISTÓRICO:
// - 07/11/2026: Campo de busca e botão de ordenação conforme protótipo.
// - 12/11/2026: Usa AppColors.alabasterGray do tema existente.

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

class HorseListSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSortPressed;

  const HorseListSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSortPressed,
  });

  @override
  Widget build(BuildContext context) {
    const inputColor = AppColors.alabasterGray;

    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            maxLength: 80,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            decoration: InputDecoration(
              hintText: 'Buscar...',
              hintStyle: const TextStyle(fontWeight: FontWeight.w400),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.black87),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar busca',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    ),
              isDense: true,
              filled: true,
              fillColor: inputColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: inputColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onSortPressed,
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(
              width: 50,
              height: 50,
              child: Tooltip(
                message: 'Ordenar resultados',
                child: Icon(Icons.sort_rounded, color: Colors.black, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
