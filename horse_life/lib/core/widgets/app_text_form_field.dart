// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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

// Campo de formulário configurável que herda a identidade visual do tema em
// diferentes tipos de entrada.
class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    required this.controller,
    required this.hintText,
    this.autofillHints,
    this.keyboardType,
    this.obscureText = false,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.textInputAction,
    this.validator,
    super.key,
  });

  // Contrato de conteúdo, comportamento e validação recebido pela tela.
  final TextEditingController controller;
  final String hintText;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;

  // Montagem do campo e de seus estados visuais.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mantém o comportamento do campo configurável sem repetir seu estilo.
    return TextFormField(
      controller: controller,
      autofillHints: autofillHints,
      keyboardType: keyboardType,
      obscureText: obscureText,
      obscuringCharacter: '•',
      onFieldSubmitted: onFieldSubmitted,
      textInputAction: textInputAction,
      validator: validator,
      cursorColor: theme.colorScheme.primary,
      style: theme.textTheme.headlineSmall,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: theme.textTheme.headlineSmall?.copyWith(
          color: theme.inputDecorationTheme.hintStyle?.color,
        ),
        contentPadding: const EdgeInsets.only(top: 14, bottom: 12),
        suffixIcon: suffixIcon,
        suffixIconColor: theme.colorScheme.primary,
      ),
    );
  }
}
