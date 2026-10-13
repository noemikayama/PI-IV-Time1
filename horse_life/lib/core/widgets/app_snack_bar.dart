// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da SnackBar reutilizável para diferentes situações, com
// cor, ícone e mensagem configuráveis, bordas arredondadas e ação de fechar.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

abstract final class AppSnackBar {
  static const borderRadius = BorderRadius.all(Radius.circular(12));

  static void show(
    BuildContext context, {
    required Color backgroundColor,
    required IconData icon,
    required String message,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          closeIconColor: Colors.white,
          content: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Urbanist',
                  ),
                ),
              ),
            ],
          ),
          shape: const RoundedRectangleBorder(borderRadius: borderRadius),
          showCloseIcon: true,
        ),
      );
  }
}
