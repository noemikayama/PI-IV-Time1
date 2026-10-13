// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do link reutilizável para ações das telas de autenticação.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class AuthLink extends StatelessWidget {
  const AuthLink({required this.label, required this.onPressed, super.key});

  static const _brandGreen = Color(0xFF009373);

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: _brandGreen,
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
          decorationColor: _brandGreen,
          fontFamily: 'Urbanist',
        ),
      ),
      child: Text(label),
    );
  }
}
