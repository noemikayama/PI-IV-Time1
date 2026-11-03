// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// 01/11/2026 - Navegação Home ↔ Dashboard por perfil com repository injetável.
//
// Data: 30/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do carregamento e das ações do perfil do responsável.
//
// Data: 28/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração do perfil do responsável à navegação inferior, com
// carregamento real ou injetável e ações externas de perfil e cavalos.
//
// Data: 27/10/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Atualização das importações de HomeAppBar, HomeBottomNavBar e
// GuardianSidebar movidos para core/widgets/.
//
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Injeção de HomeLoader; acesso a Firebase saiu da screen.
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do GuardianRepository e dos modelos com as Cloud
// Functions; documentação das responsabilidades e lógicas principais,
// preservando o comportamento anterior da interface.
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão de compatibilidade da Home com os cards e cenários simulados; estrutura e comportamentos existentes preservados.
//
// Data: 13/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação da estrutura inicial da Home do Responsável,
// seguindo a arquitetura e os padrões visuais oficiais do HorseLife.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Dashboard acessado pela Home passa a utilizar repository real,
// independentemente do modo de teste da Home.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/features/dashboard/dashboard_composition.dart';
import 'package:horse_life/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:horse_life/features/dashboard/presentation/screens/guardian/guardian_dashboard_screen.dart';
import 'package:horse_life/core/widgets/guardian_sidebar.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/features/profile/data/models/guardian_profile_data.dart';
import 'package:horse_life/features/profile/data/repositories/guardian_profile_repository.dart';
import 'package:horse_life/features/profile/presentation/screens/guardian_profile_screen.dart';
import '../../../application/controllers/home_loader.dart';
import '../../../data/models/guardian_home_data.dart';
import '../../../home_composition.dart';
import '../../widgets/guardian_home_content.dart';

/// Coordena fonte de dados, estado de navegação e compartilhamento da Future entre corpo e sidebar.
class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({
    required this.onLogout,
    this.mockScenario,
    this.loader,
    this.onRegisterHorse,
    this.dashboardRepository,
    this.guardianProfileLoader,
    this.onEditGuardianProfile,
    this.onShowAllGuardianHorses,
    super.key,
  });

  // Informe normal, empty ou completed apenas em testes.
  // Null ativa as Cloud Functions reais.
  final String? mockScenario;

  /// Dependência injetada pela raiz. Se ausente, aplica composição legada.
  final HomeLoader<GuardianHomeData>? loader;

  // Navegação futura para o cadastro de cavalos.
  final VoidCallback? onRegisterHorse;

  /// Injete um repository fake em testes; no aplicativo usa Firebase.
  final DashboardRepository? dashboardRepository;
  /// Fonte injetável do perfil, usada principalmente em testes e composições.
  final GuardianProfileLoader? guardianProfileLoader;

  /// Ações de navegação disponibilizadas pela tela de perfil.
  final VoidCallback? onEditGuardianProfile;
  final VoidCallback? onShowAllGuardianHorses;

  // A operação de logout é recebida externamente.
  final Future<void> Function() onLogout;
  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  // A fonte real é usada por padrão; cenários mock ficam restritos aos testes.

  // Estado local da navegação inferior.
  int _selectedIndex = 0;
  late Future<GuardianHomeData> _homeFuture;

  late HomeLoader<GuardianHomeData> _loader;
  FirebaseGuardianProfileRepository? _guardianProfileRepository;

  Future<GuardianHomeData> _fetchHome() => _loader.fetchHome();

  // Reutiliza o repositório real entre reconstruções quando não há injeção.
  Future<GuardianProfileData> _fetchGuardianProfile() {
    final injectedLoader = widget.guardianProfileLoader;
    if (injectedLoader != null) return injectedLoader();
    _guardianProfileRepository ??= FirebaseGuardianProfileRepository();
    return _guardianProfileRepository!.getGuardianProfile();
  }

  void _configureLoader() {
    _loader =
        widget.loader ??
        HomeComposition.guardian(mockScenario: widget.mockScenario);
  }

  void _retryHome() {
    setState(() => _homeFuture = _fetchHome());
  }

  @override
  void initState() {
    super.initState();
    _configureLoader();
    _homeFuture = _fetchHome();
  }

  @override
  void didUpdateWidget(covariant GuardianHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mockScenario != widget.mockScenario ||
        oldWidget.loader != widget.loader) {
      _configureLoader();
      _homeFuture = _fetchHome();
    }
  }

  void _onNavigationSelected(int index) {
    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GuardianDashboardScreen(
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
    // As demais rotas serão integradas pelas respectivas features.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Utiliza o fundo oficial do tema.
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Barra superior.
      appBar: const HomeAppBar(),
      // Menu lateral do responsável.
      drawer: GuardianSidebar(
        onLogout: widget.onLogout,
        homeFuture: _homeFuture,
      ),
      // Área reservada aos cards futuros.
      body: _selectedIndex == 4
          ? GuardianProfileScreen(
              loadGuardianProfile: _fetchGuardianProfile,
              onLogout: widget.onLogout,
              onEditGuardianProfile: widget.onEditGuardianProfile,
              onShowAllGuardianHorses: widget.onShowAllGuardianHorses,
              onRegisterGuardianHorse: widget.onRegisterHorse,
            )
          : GuardianHomeContent(
              homeFuture: _homeFuture,
              onRetry: _retryHome,
              onRegisterHorse: widget.onRegisterHorse,
            ),
      // Barra inferior de navegação.
      bottomNavigationBar: HomeBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onNavigationSelected,
      ),
    );
  }
}
