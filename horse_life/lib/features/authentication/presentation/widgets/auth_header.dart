// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do cabeçalho compartilhável das telas de autenticação,
// com ação de retorno e símbolo do HorseLife.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({required this.onBack, super.key});

  static const _brandGreen = Color(0xFF009373);

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // Distribui os controles nas extremidades como definido no layout.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          tooltip: 'Voltar',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _brandGreen,
            size: 32,
          ),
        ),
        Image.asset(
          'assets/Logo_somente_simbolo.png',
          width: 56,
          height: 56,
          fit: BoxFit.contain,
          semanticLabel: 'Símbolo HorseLife',
        ),
      ],
    );
  }
}
