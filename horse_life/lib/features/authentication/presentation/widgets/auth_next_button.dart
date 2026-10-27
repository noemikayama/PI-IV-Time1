// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Extração do botão de avanço compartilhado pela autenticação.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

// Ação padronizada usada para avançar entre as etapas da autenticação.
class AuthNextButton extends StatelessWidget {
  const AuthNextButton({
    required this.onPressed,
    this.buttonKey,
    this.isLoading = false,
    this.label = 'Seguinte',
    this.showArrow = true,
    super.key,
  });

  // Ação, identificação de teste e variações visuais do mesmo componente.
  final VoidCallback? onPressed;
  final Key? buttonKey;
  final bool isLoading;
  final String label;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Mantém dimensões e contorno consistentes em todas as etapas.
    return SizedBox(
      height: 60,
      child: OutlinedButton(
        key: buttonKey,
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 3),
          shape: const StadiumBorder(),
          textStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 22),
        ),
        // O conteúdo alterna entre progresso e rótulo sem mudar o tamanho.
        child: isLoading
            ? SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  color: colorScheme.primary,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (showArrow) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 26),
                  ],
                ],
              ),
      ),
    );
  }
}
