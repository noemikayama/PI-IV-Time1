// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Ponto de entrada isolado para testar o cenário empty da Home.
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';
import '../app/theme/app_theme.dart';
import '../features/home/presentation/screens/guardian/guardian_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GuardianPreviewApp());
}

class GuardianPreviewApp extends StatelessWidget {
  const GuardianPreviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: GuardianHomeScreen(mockScenario: 'empty', onLogout: _previewLogout),
  );
}

Future<void> _previewLogout() async {
  debugPrint('Logout simulado no teste da Home.');
}
