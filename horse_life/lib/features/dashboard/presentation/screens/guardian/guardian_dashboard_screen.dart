// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Integração da barra de navegação tipada com callback de destino
// para permitir navegação para todas as abas (Home, Treinos, Cavalos, Perfil) e
// integração das ações da lista de treinos recentes.
//
// Data: 11/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Uso direto do tema para o título Evolução, preservando o estilo do Figma.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/core/widgets/guardian_sidebar.dart';
import 'package:horse_life/features/home/data/models/guardian_home_data.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../widgets/dashboard_live_training_content.dart';

/// Dashboard de treinos do responsável; utiliza o repository autenticado e
/// compartilha os widgets visuais com o painel de cavalos do treinador.
class GuardianDashboardScreen extends StatelessWidget {
  const GuardianDashboardScreen({
    super.key,
    required this.onLogout,
    this.onHome,
    this.onNavigationSelected,
    required this.repository,
    this.homeFuture,
  });
  final Future<void> Function() onLogout;
  final VoidCallback? onHome;
  final ValueChanged<HomeNavigationDestination>? onNavigationSelected;
  final DashboardRepository repository;
  final Future<GuardianHomeData>? homeFuture;

  void _onDestinationSelected(BuildContext context, HomeNavigationDestination destination) {
    if (destination == HomeNavigationDestination.dashboard) return;
    if (destination == HomeNavigationDestination.home) {
      if (onHome != null) {
        onHome!();
      } else {
        Navigator.of(context).pop();
      }
      return;
    }
    if (onNavigationSelected != null) {
      onNavigationSelected!(destination);
    } else {
      Navigator.of(context).pop(destination);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: const HomeAppBar(),
    drawer: GuardianSidebar(onLogout: onLogout, homeFuture: homeFuture),
    bottomNavigationBar: HomeBottomNavBar(
      selectedDestination: HomeNavigationDestination.dashboard,
      onDestinationSelected: (destination) =>
          _onDestinationSelected(context, destination),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Evolução',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall!.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 24),
            DashboardLiveTrainingContent(
              repository: repository,
              onShowAllTrainings: () =>
                  _onDestinationSelected(context, HomeNavigationDestination.trainings),
            ),
          ],
        ),
      ),
    ),
  );
}
