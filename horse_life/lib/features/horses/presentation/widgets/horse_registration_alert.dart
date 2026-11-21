// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Delegação do modal de aviso para o componente reutilizável
// showAppInfoDialog em core/widgets.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Diálogos de confirmação e aviso centralizados.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_info_dialog.dart';

Future<void> showHorseRegistrationNotice(
  BuildContext context, {
  required String title,
  required String message,
}) => showAppInfoDialog(
  context,
  title: title,
  message: message,
  dialogKey: const Key('horse-registration-notice-dialog'),
  confirmButtonKey: const Key('confirm-horse-registration-notice'),
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
    ) ??
    false;
