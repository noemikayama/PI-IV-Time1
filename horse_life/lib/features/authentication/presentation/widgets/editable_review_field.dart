// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação da finalidade deste adaptador de compatibilidade,
// que mantém o caminho antigo enquanto expõe o widget compartilhado do core.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Implementação movida para core/widgets; este arquivo preserva a
// importação anterior para compatibilidade com as telas de autenticação.
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Suporte opcional a inputFormatters e múltiplas linhas (minLines e
// maxLines) para reutilização do componente na revisão de cadastro de exercícios.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Extração do campo editável usado na revisão de dados.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';

// Campo de revisão que alterna entre leitura e edição ou delega a edição para
// outra tela quando `externalEdit` está habilitado.
class EditableReviewField extends StatelessWidget {
  const EditableReviewField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.isEditing,
    required this.onToggleEditing,
    required this.validator,
    required this.textInputAction,
    this.keyboardType,
    this.inputFormatters,
    this.minLines,
    this.maxLines = 1,
    this.obscureText = false,
    this.externalEdit = false,
    this.leadingAction,
    super.key,
  });

  // Configuração do campo, interação e validação fornecidas pela tela dona.
  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditing;
  final VoidCallback onToggleEditing;
  final FormFieldValidator<String> validator;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? minLines;
  final int? maxLines;
  final bool obscureText;
  final bool externalEdit;
  final Widget? leadingAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // O mesmo campo preserva valor e layout ao alternar leitura e edição.
    return TextFormField(
      key: fieldKey,
      controller: controller,
      focusNode: focusNode,
      readOnly: externalEdit || !isEditing,
      obscureText: obscureText,
      obscuringCharacter: '•',
      enableSuggestions: !obscureText,
      autocorrect: !obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      minLines: obscureText ? 1 : minLines,
      maxLines: obscureText ? 1 : maxLines,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: (_) => onToggleEditing(),
      style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          color: AppColors.grey,
          fontSize: 14,
        ),
        contentPadding: const EdgeInsets.only(top: 12, bottom: 8),
        suffixIconConstraints: const BoxConstraints(minWidth: 48),
        // Ações auxiliares podem preceder o controle padronizado de edição.
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?leadingAction,
            IconButton(
              onPressed: onToggleEditing,
              tooltip: isEditing && !externalEdit
                  ? 'Concluir edição de $label'
                  : 'Editar $label',
              icon: Icon(
                isEditing && !externalEdit
                    ? Icons.check_rounded
                    : Icons.edit_rounded,
                color: AppColors.seaGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
