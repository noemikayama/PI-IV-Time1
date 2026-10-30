// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do suporte a ícone e dos estados do componente.
//
// Data: 28/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão de ícone opcional ao lado do rótulo, preservando os
// estados de carregamento e desabilitado do botão.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Migração do gradiente, conteúdo e indicador de progresso para as
// cores semânticas e a tipografia fornecidas pelo tema.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do botão reutilizável com gradiente da identidade visual
// do HorseLife e estado de carregamento.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// Botão principal reutilizável com gradiente da identidade visual.
///
/// Aceita um [icon] opcional e representa ações desabilitadas ou em
/// processamento sem permitir novos toques.
class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  // Conteúdo e estado fornecidos pela tela consumidora.
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Ícone exibido antes do rótulo quando informado.
  final IconData? icon;

  // Composição visual, semântica e interação por toque.
  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Usa Material sobre o gradiente para preservar feedback de toque.
    return Semantics(
      button: true,
      enabled: isEnabled,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.65,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
            borderRadius: const BorderRadius.all(Radius.circular(32)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(32)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: isEnabled ? onPressed : null,
              child: SizedBox(
                height: 60,
                child: Center(
                  child: isLoading
                      ? SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(
                            color: colorScheme.onPrimary,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (icon != null) ...[
                              Icon(icon, color: colorScheme.onPrimary),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              label,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
