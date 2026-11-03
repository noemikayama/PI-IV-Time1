// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// 01/11/2026 - Navegação Home ↔ Dashboard por perfil com repository injetável.
//
// Data: 27/10/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Atualização das importações de HomeAppBar, HomeBottomNavBar e
// TrainerSidebar movidos para core/widgets/.
//
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Movido para screens/trainer conforme arquitetura e injeção de HomeLoader.
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração ao mesmo fluxo de Repository/Service usado no Guardian,
// com Firebase por padrão e cenários mock explícitos para testes.
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação da Home do Profissional com AppBar e navegação
// compartilhadas, Sidebar exclusiva, Mock API e três cenários de testes.
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Dashboard acessado pela Home passa a utilizar repository real,
// independentemente do modo de teste da Home.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/features/dashboard/dashboard_composition.dart';
import 'package:horse_life/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:horse_life/features/dashboard/presentation/screens/trainer/trainer_dashboard_screen.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/core/widgets/trainer_sidebar.dart';
import '../../../application/controllers/home_loader.dart';
import '../../../data/models/trainer_home_data.dart';
import '../../../data/repositories/trainer_repository.dart';
import '../../../home_composition.dart';
import '../../widgets/trainer_home_content.dart';

class TrainerHomeScreen extends StatefulWidget {
  const TrainerHomeScreen({
    super.key,
    required this.onLogout,
    this.mockScenario,
    this.loader,
    this.repository,
    this.onViewTraining,
    this.onSelectHorse,
    this.onSelectClient,
    this.onShowAllTrainings,
    this.onShowAllHorses,
    this.onShowAllClients,
    this.onNavigationSelected,
    this.dashboardRepository,
  });

  /// null: Firebase real; 'normal', 'empty' ou 'error': Mock API.
  final String? mockScenario;

  /// Preferencialmente injetado pela raiz do aplicativo.
  final HomeLoader<TrainerHomeData>? loader;

  /// Injeção opcional de repositório (por exemplo, em testes).
  final TrainerRepository? repository;
  final Future<void> Function() onLogout;
  final ValueChanged<TrainerTraining>? onViewTraining;
  final ValueChanged<TrainerHorse>? onSelectHorse;
  final ValueChanged<TrainerClient>? onSelectClient;
  final VoidCallback? onShowAllTrainings;
  final VoidCallback? onShowAllHorses;
  final VoidCallback? onShowAllClients;
  final ValueChanged<int>? onNavigationSelected;

  /// Repository opcional para testes de navegação.
  final DashboardRepository? dashboardRepository;

  @override
  State<TrainerHomeScreen> createState() => _TrainerHomeScreenState();
}

class _TrainerHomeScreenState extends State<TrainerHomeScreen> {
  late Future<TrainerHomeData> _homeFuture;
  int _selectedIndex = 0;

  late HomeLoader<TrainerHomeData> _loader;

  /// A sidebar e o conteúdo usam uma única Future, evitando chamadas duplicadas.
  Future<TrainerHomeData> _fetchHome() => _loader.fetchHome();

  void _configureLoader() {
    _loader =
        widget.loader ??
        HomeComposition.trainer(
          mockScenario: widget.mockScenario,
          repository: widget.repository,
        );
  }

  @override
  void initState() {
    super.initState();
    _configureLoader();
    _homeFuture = _fetchHome();
  }

  void _retry() => setState(() => _homeFuture = _fetchHome());

  @override
  void didUpdateWidget(covariant TrainerHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mockScenario != oldWidget.mockScenario ||
        widget.repository != oldWidget.repository ||
        widget.loader != oldWidget.loader) {
      _configureLoader();
      _homeFuture = _fetchHome();
    }
  }

  void _onNavigationSelected(int index) {
    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TrainerDashboardScreen(
            onLogout: widget.onLogout,
            onHome: () => Navigator.of(context).pop(),
            homeFuture: _homeFuture,
            // Dashboard sempre usa dados reais (o mock da Home é independente).
            repository:
                widget.dashboardRepository ?? DashboardComposition.production(),
          ),
        ),
      );
      return;
    }
    widget.onNavigationSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const HomeAppBar(),
      drawer: TrainerSidebar(
        onLogout: widget.onLogout,
        homeFuture: _homeFuture,
      ),
      body: TrainerHomeContent(
        homeFuture: _homeFuture,
        onRetry: _retry,
        onViewTraining: widget.onViewTraining,
        onSelectHorse: widget.onSelectHorse,
        onSelectClient: widget.onSelectClient,
        onShowAllTrainings: widget.onShowAllTrainings,
        onShowAllHorses: widget.onShowAllHorses,
        onShowAllClients: widget.onShowAllClients,
      ),
      bottomNavigationBar: HomeBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onNavigationSelected,
      ),
    );
  }
}
