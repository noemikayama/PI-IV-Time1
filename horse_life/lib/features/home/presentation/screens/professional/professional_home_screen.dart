// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação da Home do Profissional com AppBar e navegação
// compartilhadas, Sidebar exclusiva, Mock API e três cenários de testes.
// -----------------------------------------------------------------------------
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração ao mesmo fluxo de Repository/Service usado no Guardian,
// com Firebase por padrão e cenários mock explícitos para testes.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../../data/models/professional_home_data.dart';
import '../../../data/services/mock_professional_home_service.dart';
import '../../../data/services/professional_home_service.dart';
import '../../../data/repositories/professional_repository.dart';
import '../../widgets/home_app_bar.dart';
import '../../widgets/home_bottom_nav_bar.dart';
import '../../widgets/professional_home_content.dart';
import '../../widgets/professional_sidebar.dart';

class ProfessionalHomeScreen extends StatefulWidget {
  const ProfessionalHomeScreen({
    super.key,
    required this.onLogout,
    this.mockScenario,
    this.repository,
    this.onViewTraining,
    this.onSelectHorse,
    this.onSelectClient,
    this.onShowAllTrainings,
    this.onShowAllHorses,
    this.onShowAllClients,
    this.onNavigationSelected,
  });

  /// null: Firebase real; 'normal', 'empty' ou 'error': Mock API.
  final String? mockScenario;
  /// Injeção opcional de repositório (por exemplo, em testes).
  final ProfessionalRepository? repository;
  final Future<void> Function() onLogout;
  final ValueChanged<ProfessionalTraining>? onViewTraining;
  final ValueChanged<ProfessionalHorse>? onSelectHorse;
  final ValueChanged<ProfessionalClient>? onSelectClient;
  final VoidCallback? onShowAllTrainings;
  final VoidCallback? onShowAllHorses;
  final VoidCallback? onShowAllClients;
  final ValueChanged<int>? onNavigationSelected;

  @override
  State<ProfessionalHomeScreen> createState() => _ProfessionalHomeScreenState();
}

class _ProfessionalHomeScreenState extends State<ProfessionalHomeScreen> {
  late Future<ProfessionalHomeData> _homeFuture;
  int _selectedIndex = 0;

  /// A sidebar e o conteúdo consomem a mesma Future; não duplica getHome.
  Future<ProfessionalHomeData> _fetchHome() {
    if (widget.mockScenario != null) {
      return const MockProfessionalHomeService().fetchHome(
        scenario: widget.mockScenario!,
      );
    }
    return ProfessionalHomeService(
      widget.repository ?? FirebaseProfessionalRepository(),
    ).fetchHome();
  }

  @override
  void initState() {
    super.initState();
    _homeFuture = _fetchHome();
  }

  void _retry() => setState(() => _homeFuture = _fetchHome());

  @override
  void didUpdateWidget(covariant ProfessionalHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mockScenario != oldWidget.mockScenario ||
        widget.repository != oldWidget.repository) {
      _homeFuture = _fetchHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const HomeAppBar(),
      drawer: ProfessionalSidebar(
        onLogout: widget.onLogout,
        homeFuture: _homeFuture,
      ),
      body: ProfessionalHomeContent(
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
        onItemSelected: (index) {
          setState(() => _selectedIndex = index);
          widget.onNavigationSelected?.call(index);
        },
      ),
    );
  }
}
