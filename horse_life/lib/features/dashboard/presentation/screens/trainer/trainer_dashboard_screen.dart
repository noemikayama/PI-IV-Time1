// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Dashboard Trainer com alternância entre cavalos próprios e painel profissional.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Remoção dos painéis simulados e fallback fictício da Sidebar; dados reais obrigatórios.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários pontuais sobre a responsabilidade do arquivo.
//
// Data: 11/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Uso direto do tema para o título Evolução, sem classe tipográfica extra.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/core/widgets/trainer_sidebar.dart';
import 'package:horse_life/features/home/data/models/trainer_home_data.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../widgets/dashboard_live_training_content.dart';
import '../../widgets/dashboard_live_professional_content.dart';

/// Alterna o painel de cavalos próprios e os indicadores profissionais do Trainer.
class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({
    super.key,
    required this.onLogout,
    this.onHome,
    required this.homeFuture,
    required this.repository,
  });
  final Future<void> Function() onLogout;
  final VoidCallback? onHome;
  final Future<TrainerHomeData> homeFuture;
  final DashboardRepository repository;
  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  bool _professional = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    appBar: const HomeAppBar(),
    drawer: TrainerSidebar(
      onLogout: widget.onLogout,
      homeFuture: widget.homeFuture,
    ),
    bottomNavigationBar: HomeBottomNavBar(
      selectedIndex: 3,
      onItemSelected: (index) {
        if (index == 0) {
          if (widget.onHome != null) {
            widget.onHome!();
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
              style: Theme.of(context).textTheme.displaySmall!.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Switch(
                  value: _professional,
                  activeColor: Colors.white,
                  activeTrackColor: const Color(0xFF027068),
                  onChanged: (value) => setState(() => _professional = value),
                ),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Painel profissional',
                    style: TextStyle(fontFamily: 'Urbanist', fontSize: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_professional)
              DashboardLiveProfessionalContent(repository: widget.repository)
            else
              DashboardLiveTrainingContent(repository: widget.repository),
          ],
        ),
      ),
    ),
  );
}
