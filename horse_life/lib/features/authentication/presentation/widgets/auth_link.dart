// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do link reutilizável para ações das telas de autenticação.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

// Link textual reutilizável para ações secundárias da autenticação.
class AuthLink extends StatelessWidget {
  const AuthLink({required this.label, required this.onPressed, super.key});

  // Cor que identifica visualmente as ações interativas da feature.
  static const _brandGreen = Color(0xFF009373);

  // Conteúdo e ação definidos pela tela que utiliza o link.
  final String label;
  final VoidCallback onPressed;

  // Configuração visual e área mínima de interação.
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
