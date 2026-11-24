// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição dos parâmetros opcionais inputFormatters, minLines e
// maxLines no componente compartilhado para reutilização na revisão do
// cadastro de treinamentos.
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos parâmetros e dos modos de leitura, edição e
// ação externa do campo compartilhado.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Migração do campo editável da autenticação para o core, permitindo
// seu reaproveitamento na edição de cavalos.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do campo editável usado na revisão de dados.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Campo que alterna entre leitura e edição sem trocar o layout.
///
/// O modo [externalEdit] mantém o texto somente para leitura e delega a ação
/// do ícone ao chamador, útil quando a edição acontece em um modal separado.
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

  // --- Conteúdo, controle e validação fornecidos pela tela ------------------
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

  // --- Campo visual e ação de alternância -----------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
