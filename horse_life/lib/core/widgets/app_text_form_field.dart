// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Inclusão do parâmetro opcional inputFormatters para suportar
// restrições de entrada como campos exclusivamente numéricos.
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de configuração e montagem do campo.
//
// Data: 04/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão de FocusNode e do modo somente leitura para permitir o
// controle de foco e a exibição de campos não editáveis.
//
// Data: 02/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão do labelText no InputDecoration para exibir o hintText
// como rótulo do campo.
//
// Data: 16/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Substituição de ValueChanged<String> pelos typedefs
// AppTextFormFieldChangedCallback e AppTextFormFieldSubmittedCallback.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão do callback reativo onChanged para validação de senha.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Remoção dos estilos locais e adoção de TextTheme, ColorScheme e
// InputDecorationTheme para todos os estados visuais do campo.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do campo de formulário reutilizável com identidade visual
// do HorseLife e suporte a validação e diferentes tipos de entrada.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horse_life/app/theme/app_colors.dart';

// --- Contratos de eventos ----------------------------------------------------
// Os aliases deixam explícito o valor entregue durante a digitação e o envio.
typedef AppTextFormFieldChangedCallback = void Function(String value);
typedef AppTextFormFieldSubmittedCallback = void Function(String value);

/// Campo reutilizável que centraliza comportamento e identidade visual.
class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    required this.controller,
    required this.hintText,
    this.autofillHints,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.readOnly = false,
    this.suffixIcon,
    this.textInputAction,
    this.validator,
    super.key,
  });

  // --- Configuração do campo -------------------------------------------------
  final TextEditingController controller;
  final String hintText;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;

  /// Notifica a tela enquanto o conteúdo é alterado.
  final AppTextFormFieldChangedCallback? onChanged;

  /// Notifica a tela quando o usuário conclui a edição pelo teclado.
  final AppTextFormFieldSubmittedCallback? onFieldSubmitted;

  /// Permite que a tela mova o foco programaticamente para este campo.
  final FocusNode? focusNode;

  /// Mantém o conteúdo visível e selecionável, mas impede sua edição.
  final bool readOnly;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;

  // --- Composição visual -----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Encaminha as opções funcionais e aplica o estilo compartilhado do app.
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      autofillHints: autofillHints,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      obscuringCharacter: '•',
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      textInputAction: textInputAction,
      validator: validator,
      cursorColor: theme.colorScheme.primary,
      style: theme.textTheme.headlineSmall,
      decoration: InputDecoration(
        labelText: hintText,
        hintStyle: theme.textTheme.headlineSmall?.copyWith(
          color: AppColors.grey,
        ),
        contentPadding: const EdgeInsets.only(top: 14, bottom: 12),
        suffixIcon: suffixIcon,
        suffixIconColor: theme.colorScheme.primary,
      ),
    );
  }
}
