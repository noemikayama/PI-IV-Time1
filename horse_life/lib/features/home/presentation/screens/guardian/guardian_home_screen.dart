import 'package:flutter/material.dart';

import '../../widgets/home_app_bar.dart';
import '../../widgets/home_bottom_nav_bar.dart';
import '../../widgets/guardian_sidebar.dart';

class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({required this.onLogout, super.key});

  // A operação de logout é recebida externamente.
  final Future<void> Function() onLogout;
  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  // Estado local da navegação inferior.
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Utiliza o fundo oficial do tema.
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Barra superior.
      appBar: const HomeAppBar(),
      // Menu lateral do responsável.
      drawer: GuardianSidebar(onLogout: widget.onLogout),
      // Área reservada aos cards futuros.
      body: const SizedBox.expand(),
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
