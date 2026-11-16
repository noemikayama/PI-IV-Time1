// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adequação estética do campo de busca autocomplete aos protótipos
// de Raça e Pelagem: visual underline padrão, card de sugestões suspenso com
// cantos inferiores arredondados e realce no item ativo/hover.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Autocomplete reutilizável de raças e pelagens com mocks locais.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import '../../data/mocks/mock_horse_catalog.dart';

/// O campo só é considerado válido após a seleção de um item existente.
/// A pesquisa não faz requisições remotas; tolera letras acentuadas.
class HorseSearchField extends StatefulWidget {
  const HorseSearchField({
    required this.label,
    required this.options,
    required this.value,
    required this.onSelected,
    super.key,
  });

  final String label;
  final List<String> options;
  final String value;
  final ValueChanged<String> onSelected;

  @override
  State<HorseSearchField> createState() => _HorseSearchFieldState();
}

class _HorseSearchFieldState extends State<HorseSearchField> {
  double? _fieldWidth;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.value),
      displayStringForOption: (item) => item,
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.trim().isEmpty) {
          return const Iterable<String>.empty();
        }
        return MockHorseCatalog.search(widget.options, textEditingValue.text);
      },
      onSelected: (selected) {
        widget.onSelected(selected);
        FocusScope.of(context).unfocus();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return LayoutBuilder(
          builder: (context, constraints) {
            _fieldWidth = constraints.maxWidth;
            return TextFormField(
              key: ValueKey<String>('horse-search-${widget.label}'),
              controller: controller,
              focusNode: focusNode,
              cursorColor: AppColors.seaGreen,
              style: Theme.of(context).textTheme.headlineSmall,
              decoration: InputDecoration(
                hintText: widget.label,
                hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.grey,
                ),
                contentPadding: const EdgeInsets.only(top: 14, bottom: 12),
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                if (value != widget.value) {
                  widget.onSelected('');
                }
              },
              validator: (_) =>
                  widget.value.isEmpty ? 'Selecione uma opção da lista.' : null,
            );
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        int highlightIndex = 0;
        try {
          highlightIndex = AutocompleteHighlightedOption.of(context);
        } catch (_) {
          highlightIndex = 0;
        }

        final width = _fieldWidth ?? 560.0;

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Colors.white,
            elevation: 4,
            shadowColor: Colors.black26,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Container(
              width: width,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: const Color(0xFFD9D9D9),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      final isHighlighted = highlightIndex == index;

                      return InkWell(
                        key: ValueKey<String>('horse-option-$option'),
                        onTap: () => onSelected(option),
                        child: Container(
                          width: double.infinity,
                          color: isHighlighted
                              ? const Color(0xFFE9E9E9)
                              : Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Text(
                            option,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall?.copyWith(
                              fontSize: 18,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
