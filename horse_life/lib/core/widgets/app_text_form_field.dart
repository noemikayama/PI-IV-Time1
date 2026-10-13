// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do campo de formulário reutilizável com identidade visual
// do HorseLife e suporte a validação e diferentes tipos de entrada.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

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

  static const _brandGreen = Color(0xFF009373);
  static const _hintColor = Color(0xFF858585);

  final TextEditingController controller;
  final String hintText;
  final Iterable<String>? autofillHints;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
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
      cursorColor: _brandGreen,
      style: const TextStyle(
        fontSize: 20,
        color: Colors.black87,
        fontFamily: 'Urbanist',
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: _hintColor,
          fontSize: 20,
          fontWeight: FontWeight.w400,
          fontFamily: 'Urbanist',
        ),
        contentPadding: const EdgeInsets.only(top: 14, bottom: 12),
        suffixIcon: suffixIcon,
        suffixIconColor: _brandGreen,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _brandGreen, width: 2),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: _brandGreen, width: 2.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 2.5),
        ),
      ),
    );
  }
}
