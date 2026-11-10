// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.value),
      displayStringForOption: (item) => item,
      optionsBuilder: (value) =>
          MockHorseCatalog.search(widget.options, value.text),
      onSelected: (selected) {
        widget.onSelected(selected);
        FocusScope.of(context).unfocus();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // O Flutter gerencia o TextEditingController do Autocomplete.
        // Alterações digitadas invalidam a seleção anterior até novo clique.
        return TextFormField(
          key: ValueKey<String>('horse-search-${widget.label}'),
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: 'Digite para buscar',
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (value) {
            if (value != widget.value) widget.onSelected('');
          },
          validator: (_) =>
              widget.value.isEmpty ? 'Selecione uma opção da lista.' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(10),
          color: AppColors.whiteSmoke,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 450),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);
                return ListTile(
                  dense: true,
                  title: Text(option),
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
