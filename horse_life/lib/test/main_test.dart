import 'package:flutter/material.dart';

import 'app/theme/app_theme.dart';
import 'features/home/presentation/screens/guardian/guardian_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const HorseLifeTestApp());
}

class HorseLifeTestApp extends StatelessWidget {
  const HorseLifeTestApp({super.key});

  // Simulação de logout para o ambiente de testes.
  Future<void> _handleTestLogout() async {
    debugPrint('Logout simulado no ambiente de testes.');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HorseLife - Teste',
      debugShowCheckedModeBanner: false,

      // Utiliza o tema oficial do projeto.
      theme: AppTheme.light,

      // Tela inicial do Responsável.
      home: GuardianHomeScreen(onLogout: _handleTestLogout),
    );
  }
}
