// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do campo de texto de múltiplas linhas reutilizável em
// core/widgets, padronizando a estilização arredondada utilizada na descrição do
// exercício e na adição de orientações.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Campo de formulário de múltiplas linhas com identidade visual padronizada do app.
class AppMultilineTextFormField extends StatelessWidget {
  const AppMultilineTextFormField({
    required this.controller,
    required this.hintText,
    this.fieldKey,
    this.minLines = 4,
    this.maxLines = 6,
    this.autofocus = false,
    this.focusNode,
    this.validator,
    this.textInputAction = TextInputAction.newline,
    this.keyboardType = TextInputType.multiline,
    this.inputFormatters,
    this.onChanged,
    this.onFieldSubmitted,
    this.readOnly = false,
    this.fillColor = AppColors.alabasterGray,
    this.contentPadding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    super.key,
  });

  final Key? fieldKey;
  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int? maxLines;
  final bool autofocus;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final bool readOnly;
  final Color fillColor;
  final EdgeInsetsGeometry contentPadding;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      key: fieldKey ?? key,
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      readOnly: readOnly,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      cursorColor: theme.colorScheme.primary,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontSize: 20,
        height: 1.2,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: theme.textTheme.headlineSmall?.copyWith(
          color: AppColors.grey,
          fontSize: 20,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: contentPadding,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    );
  }
}
