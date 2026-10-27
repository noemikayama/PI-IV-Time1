// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da home temporária com a ação de encerramento da sessão.
// -----------------------------------------------------------------------------

// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Removido acoplamento à camada interna de autenticação.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import 'package:horse_life/core/widgets/app_snack_bar.dart';

typedef SignOutOperation = Future<void> Function();

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.signOut,
    this.signOutErrorMessage = 'Não foi possível sair. Tente novamente.',
    super.key,
  });

  final SignOutOperation signOut;
  final String signOutErrorMessage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await widget.signOut();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        backgroundColor: Theme.of(context).colorScheme.error,
        icon: Icons.error,
        message: widget.signOutErrorMessage,
      );
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const Key('sign-out-button'),
          onPressed: _isSigningOut ? null : _signOut,
          child: _isSigningOut
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Sair'),
        ),
      ),
    );
  }
}
