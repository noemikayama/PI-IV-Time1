// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Adoção da RegistrationFlowRoute e remoção do controller de
// cadastro da interface da tela.
//
// Data: 16/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Substituição de ValueChanged<UserType> pelo typedef
// ProfileSelectionCallback no callback de seleção de perfil.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Conexão da abertura de conta à seleção de perfil e ao controller
// injetável do fluxo de cadastro.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da tela inicial do HorseLife com fotografia, sobreposição
// Alabaster Gray, marca e acesso à tela de login.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../routes/registration_flow_route.dart';
import '../widgets/welcome_action_panel.dart';
import 'login_screen.dart';
import 'profile_selection_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    this.onCreateAccount,
    this.onUserTypeSelected,
    super.key,
  });

  // Pontos de extensão para testes, seleção de fluxo e futura submissão.
  final VoidCallback? onCreateAccount;
  final ProfileSelectionCallback? onUserTypeSelected;

  void _openLogin(BuildContext context) {
    // Abre o login diretamente pela camada de apresentação, conforme o padrão
    // de navegação definido para o projeto.
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
    );
  }

  void _openProfileSelection(BuildContext context) {
    // Delega a composição e a abertura ao módulo do fluxo de cadastro.
    Navigator.push(
      context,
      RegistrationFlowRoute.build(onContinue: onUserTypeSelected),
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
          // Painel de entrada para login ou início do cadastro.
          Align(
            alignment: Alignment.bottomCenter,
            child: WelcomeActionPanel(
              onAccessAccount: () => _openLogin(context),
              onCreateAccount:
                  onCreateAccount ?? () => _openProfileSelection(context),
            ),
          ),
        ],
      ),
    );
  }
}
