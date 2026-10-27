// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação da estrutura inicial da Home do Responsável,
// seguindo a arquitetura e os padrões visuais oficiais do HorseLife.
// -----------------------------------------------------------------------------
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão de compatibilidade da Home com os cards e cenários simulados; estrutura e comportamentos existentes preservados.
// -----------------------------------------------------------------------------
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do GuardianRepository e dos modelos com as Cloud
// Functions; documentação das responsabilidades e lógicas principais,
// preservando o comportamento anterior da interface.
// -----------------------------------------------------------------------------

// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Injeção de HomeLoader; acesso a Firebase saiu da screen.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../widgets/home_app_bar.dart';
import '../../widgets/home_bottom_nav_bar.dart';
import '../../widgets/guardian_sidebar.dart';
import '../../widgets/guardian_home_content.dart';
import '../../../data/models/guardian_home_data.dart';
import '../../../application/controllers/home_loader.dart';
import '../../../home_composition.dart';

/// Coordena fonte de dados, estado de navegação e compartilhamento da Future entre corpo e sidebar.
class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({
    required this.onLogout,
    this.mockScenario,
    this.loader,
    this.onRegisterHorse,
    super.key,
  });

  // Informe normal, empty ou completed apenas em testes.
  // Null ativa as Cloud Functions reais.
  final String? mockScenario;

  /// Dependência injetada pela raiz. Se ausente, aplica composição legada.
  final HomeLoader<GuardianHomeData>? loader;

  // Navegação futura para o cadastro de cavalos.
  final VoidCallback? onRegisterHorse;

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

  Future<GuardianHomeData> _fetchHome() => _loader.fetchHome();

  void _configureLoader() {
    _loader = widget.loader ??
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
      body: GuardianHomeContent(
        homeFuture: _homeFuture,
        onRetry: _retryHome,
        onRegisterHorse: widget.onRegisterHorse,
      ),
      // Barra inferior de navegação.
      bottomNavigationBar: HomeBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
