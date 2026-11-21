// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do processamento e do tratamento de falha no logout.
//
// Data: 30/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Ajuste do ícone do botão de saída para o tamanho 26.
//
// Data: 28/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do botão de saída com bloqueio de solicitações duplicadas,
// indicador de progresso e mensagem de erro.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Botão de saída que controla localmente o processamento da operação.
class RedSignOutButton extends StatefulWidget {
  const RedSignOutButton({required this.onLogout, super.key});

  final Future<void> Function() onLogout;

  @override
  State<RedSignOutButton> createState() => _RedSignOutButtonState();
}

class _RedSignOutButtonState extends State<RedSignOutButton> {
  bool _isLoggingOut = false;

  // Impede chamadas concorrentes e restaura o botão quando a saída falha.
  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await widget.onLogout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível sair. Tente novamente.'),
        ),
      );
      setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilledButton.icon(
      key: const Key('red-sign-out-button'),
      onPressed: _isLoggingOut ? null : _logout,
      icon: _isLoggingOut
          ? const SizedBox.square(
              dimension: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.logout_rounded, size: 24),
      label: Text(
        _isLoggingOut ? 'Saindo...' : 'Sair',
        style: theme.textTheme.labelLarge?.copyWith(
          color: AppColors.whiteSmoke,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFC00000),
        disabledBackgroundColor: const Color(0xFFC00000),
        minimumSize: const Size.fromHeight(54),
        textStyle: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
