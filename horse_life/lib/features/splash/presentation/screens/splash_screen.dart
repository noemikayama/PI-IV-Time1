// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da splash Flutter com a logo completa do HorseLife,
// mensagem de falha e ação para realizar uma nova tentativa.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  // Cria a variação exibida durante o carregamento normal.
  const SplashScreen({super.key}) : onRetry = null;

  // Cria a variação de falha com uma ação de nova tentativa.
  const SplashScreen.failed({required this.onRetry, super.key});

  // Centraliza as cores usadas pelos estados da splash.
  static const _backgroundColor = Color(0xFFFAFAFA);
  static const _brandGreen = Color(0xFF009B7A);

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    // A presença do callback determina se a inicialização falhou.
    final hasFailed = onRetry != null;

    // Compõe a logo completa e, quando necessário, os controles de
    // recuperação.
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Semantics(
          container: true,
          label: hasFailed ? null : 'Carregando HorseLife',
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Exibe a marca sem o recorte aplicado pelas telas nativas.
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Image.asset(
                      'assets/Logo_HorseLife.png',
                      width: MediaQuery.sizeOf(context).width * 0.48,
                      fit: BoxFit.contain,
                      semanticLabel: 'HorseLife',
                    ),
                  ),
                  // Acrescenta mensagem e botão somente no estado de falha.
                  if (hasFailed) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Não foi possível conectar ao HorseLife.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF002646),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: _brandGreen,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
