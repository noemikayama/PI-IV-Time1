// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 01/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Navegação Home ↔ Dashboard por perfil com repository injetável.
//
// Data: 29/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Dashboard Guardian modular.
//
// Data: 29/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Mock relacional, filtros por cavalo/período e listas horizontais.
//
// Data: 30/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Ajustes de proporções, espaçamento e alinhamento ao Figma.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Remoção do modo mock; dashboard passa a exigir repository para consultar dados reais.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/core/widgets/guardian_sidebar.dart';
import 'package:horse_life/features/home/data/models/guardian_home_data.dart';
import '../../widgets/dashboard_text_styles.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../widgets/dashboard_live_training_content.dart';

/// Dashboard de treinos do responsável; utiliza o repository autenticado e
/// compartilha os widgets visuais com o painel de cavalos do treinador.
class GuardianDashboardScreen extends StatelessWidget {
  const GuardianDashboardScreen({
    super.key,
    required this.onLogout,
    this.onHome,
    required this.repository,
    this.homeFuture,
  });
  final Future<void> Function() onLogout;
  final VoidCallback? onHome;
  final DashboardRepository repository;
  final Future<GuardianHomeData>? homeFuture;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: const HomeAppBar(),
    drawer: GuardianSidebar(onLogout: onLogout, homeFuture: homeFuture),
    bottomNavigationBar: HomeBottomNavBar(
      selectedIndex: 3,
      onItemSelected: (index) {
        if (index == 0) {
          if (onHome != null) {
            onHome!();
          } else {
            Navigator.of(context).maybePop();
          }
        }
      },
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
              style: DashboardTextStyles.pageTitle(context),
            ),
            const SizedBox(height: 24),
            DashboardLiveTrainingContent(repository: repository),
          ],
        ),
      ),
    ),
  );
}
