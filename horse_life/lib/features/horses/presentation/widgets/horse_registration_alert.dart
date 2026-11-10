// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Diálogos de confirmação e aviso centralizados.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

Future<void> showHorseRegistrationNotice(
  BuildContext context, {
  required String title,
  required String message,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    backgroundColor: AppColors.whiteSmoke,
    title: Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.prussianBlue,
      ),
    ),
    content: Text(message, textAlign: TextAlign.center),
    actionsAlignment: MainAxisAlignment.center,
    actions: [
      OutlinedButton(
        onPressed: () => Navigator.pop(dialogContext),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.seaGreen,
          side: const BorderSide(color: AppColors.seaGreen),
          minimumSize: const Size(220, 44),
        ),
        child: const Text('Ok'),
      ),
    ],
  ),
);

Future<bool> confirmHorseRegistrationExit(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sair do cadastro?'),
        content: const Text('Os dados preenchidos ainda não foram salvos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continuar cadastro'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    ) ?? false;
