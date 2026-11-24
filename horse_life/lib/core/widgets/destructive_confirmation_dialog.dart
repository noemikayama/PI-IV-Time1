// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do contrato assíncrono, conteúdo e ações do modal
// reutilizável de confirmação destrutiva.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do modal reutilizável para confirmação de ações
// destrutivas, com cancelamento preenchido e confirmação contornada conforme
// o padrão visual do protótipo.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/gradient_button.dart';

/// Exibe uma decisão destrutiva e devolve `true` somente quando a confirmação
/// explícita for escolhida; fechamento externo e cancelamento devolvem `false`.
Future<bool> showDestructiveConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'Cancelar',
  String confirmLabel = 'Sim',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        key: const Key('destructive-confirmation-dialog'),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.25),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: GradientButton(
                        key: const Key('destructive-dialog-cancel-button'),
                        label: cancelLabel,
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _OutlinedDialogActionButton(
                        key: const Key('destructive-dialog-confirm-button'),
                        label: confirmLabel,
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ) ??
    false;

/// Ação secundária contornada que diferencia a confirmação do cancelamento
/// preenchido usado pelo padrão visual do modal.
class _OutlinedDialogActionButton extends StatelessWidget {
  const _OutlinedDialogActionButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.seaGreen,
        side: const BorderSide(color: AppColors.seaGreen, width: 2),
        shape: const StadiumBorder(),
        textStyle: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    ),
  );
}
