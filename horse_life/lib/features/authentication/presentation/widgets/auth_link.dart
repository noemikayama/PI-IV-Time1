// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Substituição da cor e tipografia locais por TextButtonTheme,
// TextTheme e ColorScheme.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do link reutilizável para ações das telas de autenticação.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

// Link textual reutilizável que herda do tema as ações secundárias da
// autenticação.
class AuthLink extends StatelessWidget {
  const AuthLink({required this.label, required this.onPressed, super.key});

  // Conteúdo e ação definidos pela tela que utiliza o link.
  final String label;
  final VoidCallback onPressed;

  // Configuração visual e área mínima de interação.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: theme.textTheme.bodyLarge?.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: theme.colorScheme.primary,
        ),
      ),
      child: Text(label),
    );
  }
}
