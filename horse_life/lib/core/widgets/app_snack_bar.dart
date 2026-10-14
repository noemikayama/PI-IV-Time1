// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Adaptação das cores de primeiro plano e da tipografia para os
// valores fornecidos pelo SnackBarTheme e pelo ColorScheme do aplicativo.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da SnackBar reutilizável para diferentes situações, com
// cor, ícone e mensagem configuráveis, bordas arredondadas e ação de fechar.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

// Centraliza o comportamento das mensagens temporárias, permitindo que cada
// situação forneça cor, ícone e texto sem duplicar a aparência definida no
// tema global.
abstract final class AppSnackBar {
  // Aparência compartilhada por todas as SnackBars da aplicação.
  static const borderRadius = BorderRadius.all(Radius.circular(12));

  // Exibe uma nova mensagem e substitui qualquer SnackBar ainda visível.
  static void show(
    BuildContext context, {
    required Color backgroundColor,
    required IconData icon,
    required String message,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final contentTextStyle = theme.snackBarTheme.contentTextStyle;
    final foregroundColor =
        contentTextStyle?.color ?? theme.colorScheme.onPrimary;

    // Composição do conteúdo e dos controles da mensagem.
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          closeIconColor: foregroundColor,
          content: Row(
            children: [
              Icon(icon, color: foregroundColor),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: contentTextStyle)),
            ],
          ),
          shape: const RoundedRectangleBorder(borderRadius: borderRadius),
          showCloseIcon: true,
        ),
      );
  }
}
