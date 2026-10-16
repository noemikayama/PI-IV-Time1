// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Adoção da cor primária do ColorScheme para a ação de retorno.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do cabeçalho compartilhável das telas de autenticação,
// com ação de retorno e símbolo do HorseLife.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

// Cabeçalho temático das telas de autenticação, responsável pela navegação de
// retorno e pela exibição compacta da marca.
class AuthHeader extends StatelessWidget {
  const AuthHeader({required this.onBack, super.key});

  // A tela define o destino do retorno para manter o widget reutilizável.
  final VoidCallback onBack;

  // Distribuição dos controles nas extremidades do cabeçalho.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Distribui os controles nas extremidades como definido no layout.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onBack,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          tooltip: 'Voltar',
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.primary,
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
