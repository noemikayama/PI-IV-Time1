// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação da estrutura inicial da Home do Responsável,
// seguindo a arquitetura e os padrões visuais oficiais do HorseLife.
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';
import '../../widgets/home_app_bar.dart';
import '../../widgets/home_bottom_nav_bar.dart';
import '../../widgets/guardian_sidebar.dart';
import '../../widgets/guardian_home_content.dart';
import '../../../data/models/guardian_home_data.dart';
import '../../../data/services/mock_guardian_home_service.dart';

class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({required this.onLogout, this.mockScenario = 'normal', super.key});

  // Para testes: normal, empty ou completed.
  final String mockScenario;

  // A operação de logout é recebida externamente.
  final Future<void> Function() onLogout;
  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  // Estado local da navegação inferior.
  int _selectedIndex = 0;
  late final Future<GuardianHomeData> _homeFuture;

  @override
  void initState() {
    super.initState();
    _homeFuture = const MockGuardianHomeService().fetchHome(scenario: widget.mockScenario);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Utiliza o fundo oficial do tema.
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Barra superior.
      appBar: const HomeAppBar(),
      // Menu lateral do responsável.
      drawer: GuardianSidebar(onLogout: widget.onLogout, homeFuture: _homeFuture),
      // Área reservada aos cards futuros.
      body: GuardianHomeContent(homeFuture: _homeFuture),
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
