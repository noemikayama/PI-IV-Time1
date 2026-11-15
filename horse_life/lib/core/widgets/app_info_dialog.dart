// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do diálogo informativo padronizado AppInfoDialog em
// core/widgets para reutilização entre o fluxo de exercícios e o cadastro
// de cavalos.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

import 'auth_next_button.dart';

/// Exibe um diálogo informativo padronizado com título, mensagem e botão de confirmação.
Future<void> showAppInfoDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ok',
  Key? dialogKey,
  Key? confirmButtonKey,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AppInfoDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      dialogKey: dialogKey,
      confirmButtonKey: confirmButtonKey,
    ),
  );
}

/// Modal informativo reutilizável com identidade visual oficial do HorseLife.
class AppInfoDialog extends StatelessWidget {
  const AppInfoDialog({
    required this.title,
    required this.message,
    this.confirmLabel = 'Ok',
    this.dialogKey,
    this.confirmButtonKey,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final Key? dialogKey;
  final Key? confirmButtonKey;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      key: dialogKey,
      backgroundColor: AppColors.whiteSmoke,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.displaySmall?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                message,
                textAlign: TextAlign.left,
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: 20,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              AuthNextButton(
                buttonKey: confirmButtonKey,
                label: confirmLabel,
                showArrow: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
