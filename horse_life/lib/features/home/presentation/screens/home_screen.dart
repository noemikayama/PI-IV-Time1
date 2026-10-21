// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da home temporária com a ação de encerramento da sessão.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_snack_bar.dart';
import '../../../authentication/presentation/messages/authentication_error_messages.dart';

typedef SignOutOperation = Future<void> Function();

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.signOut, super.key});

  final SignOutOperation signOut;

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
        message: AuthenticationErrorMessages.serverConnection,
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
