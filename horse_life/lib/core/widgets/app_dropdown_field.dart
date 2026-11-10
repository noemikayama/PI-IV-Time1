// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 09/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Extração do dropdown reutilizável a partir dos seletores já
// existentes em cadastro de treinadores e cavalos. Mantém os dois estilos.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Aparência do campo. O conteúdo e a seleção são compartilhados.
enum AppDropdownStyle { underline, rounded }

/// Dropdown genérico para opções locais ou vindas do servidor.
/// Não busca dados: a tela recebe a lista pronta e decide o que salvar.
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    required this.value,
    required this.options,
    required this.labelFor,
    required this.onChanged,
    this.label,
    this.dropdownKey,
    this.style = AppDropdownStyle.underline,
    this.isOpen = false,
    this.onTap,
    super.key,
  });

  final T? value;
  final List<T> options;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;
  final String? label;
  final Key? dropdownKey;
  final AppDropdownStyle style;
  final bool isOpen;
  final VoidCallback? onTap;

  bool get _isRounded => style == AppDropdownStyle.rounded;

  // Usa a mesma opção visual nas duas telas: verde e check no item escolhido.
  DropdownMenuItem<T> _buildOption(T item) {
    final selected = item == value;
    return DropdownMenuItem<T>(
      value: item,
      child: Container(
        constraints: _isRounded ? const BoxConstraints(minHeight: 52) : null,
        width: _isRounded ? null : double.infinity,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(
          horizontal: _isRounded ? 12 : 8,
          vertical: _isRounded ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.seaGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(_isRounded ? 13 : 5),
        ),
        child: Row(
          children: [
            if (selected) ...[
              Icon(
                _isRounded ? Icons.check_rounded : Icons.check,
                size: _isRounded ? 28 : 19,
                color: Colors.white,
              ),
              SizedBox(width: _isRounded ? 12 : 5),
            ],
            Expanded(
              child: Text(
                labelFor(item),
                softWrap: _isRounded,
                overflow: _isRounded ? null : TextOverflow.ellipsis,
                style: _isRounded
                    ? TextStyle(color: selected ? Colors.white : AppColors.text)
                    : TextStyle(
                        color: selected ? Colors.white : AppColors.prussianBlue,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _selectedItems() => [
    for (final item in options)
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          labelFor(item),
          softWrap: _isRounded,
          overflow: _isRounded ? null : TextOverflow.ellipsis,
          style: _isRounded
              ? null
              : const TextStyle(
                  color: AppColors.prussianBlue,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isRounded) {
      // Conserva o visual do dropdown da etapa de modalidades do treinador.
      return InputDecorator(
        decoration: InputDecoration(
          labelText: isOpen ? label : null,
          labelStyle: const TextStyle(color: AppColors.seaGreen),
          filled: true,
          fillColor: const Color(0xFFE9E9E9),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 4,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isOpen ? AppColors.seaGreen : Colors.transparent,
              width: 2,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(18)),
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            key: dropdownKey,
            value: options.contains(value) ? value : null,
            isExpanded: true,
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            menuMaxHeight: 320,
            dropdownColor: Colors.white,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.text,
              size: 32,
            ),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.text,
              fontSize: 20,
            ),
            itemHeight: null,
            selectedItemBuilder: (_) => _selectedItems(),
            items: options.map(_buildOption).toList(),
            onTap: onTap,
            onChanged: (item) {
              if (item != null) onChanged(item);
            },
          ),
        ),
      );
    }

    // Conserva o visual dos campos do cadastro de cavalos.
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: AppColors.pearlAqua.withValues(alpha: 0.18),
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: DropdownButtonFormField<T>(
        key: dropdownKey,
        initialValue: options.contains(value) ? value : null,
        isExpanded: true,
        dropdownColor: AppColors.whiteSmoke,
        borderRadius: BorderRadius.circular(10),
        menuMaxHeight: 370,
        icon: const Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.prussianBlue,
        ),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.alabasterGray.withValues(alpha: 0.35),
          border: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.seaGreen, width: 2),
          ),
        ),
        selectedItemBuilder: (_) => _selectedItems(),
        items: options.map(_buildOption).toList(),
        onChanged: (item) {
          if (item != null) onChanged(item);
        },
      ),
    );
  }
}
