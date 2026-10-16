// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da tela inicial do HorseLife com fotografia, sobreposição
// Alabaster Gray, marca e acesso à tela de login.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'login_screen.dart';
import '../widgets/welcome_action_panel.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({this.onCreateAccount, super.key});

  final VoidCallback? onCreateAccount;

  void _openLogin(BuildContext context) {
    // Abre o login diretamente pela camada de apresentação, conforme o padrão
    // de navegação definido para o projeto.
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final cacheWidth = (mediaQuery.size.width * mediaQuery.devicePixelRatio)
        .ceil();

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // A largura de cache limita a memória de decodificação da fotografia
          // original sem alterar seu arquivo-fonte.
          Image.asset(
            'assets/foto_cavalo_tela_inicial.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            cacheWidth: cacheWidth,
            semanticLabel: 'Cavalo em um campo',
          ),
          ColoredBox(
            key: const Key('welcome-photo-overlay'),
            color: AppColors.alabasterGray.withValues(alpha: 0.47),
          ),
          Positioned(
            top: mediaQuery.padding.top + 90,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/Logo_HorseLife.png',
                width: 160,
                fit: BoxFit.contain,
                semanticLabel: 'HorseLife',
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: WelcomeActionPanel(
              onAccessAccount: () => _openLogin(context),
              onCreateAccount: onCreateAccount ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}
