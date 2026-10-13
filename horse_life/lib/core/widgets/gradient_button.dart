// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do botão reutilizável com gradiente da identidade visual
// do HorseLife e estado de carregamento.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  static const _gradient = LinearGradient(
    colors: [Color(0xFF009373), Color(0xFF027068)],
  );

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    // Usa Material sobre o gradiente para preservar feedback de toque.
    return Semantics(
      button: true,
      enabled: isEnabled,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.65,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: _gradient,
            borderRadius: BorderRadius.all(Radius.circular(32)),
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
                      ? const SizedBox.square(
                          dimension: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Urbanist',
                          ),
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
