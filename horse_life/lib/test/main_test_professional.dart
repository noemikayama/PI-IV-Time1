// RESPONSÁVEL PELA IMPLEMENTAÇÃO FLUTTER: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Cenário normal da Home do Profissional, sem inicializar Firebase.
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';
import '../app/theme/app_theme.dart';
import '../features/home/presentation/screens/professional/professional_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProfessionalPreviewApp());
}

class ProfessionalPreviewApp extends StatelessWidget {
  const ProfessionalPreviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: ProfessionalHomeScreen(
          mockScenario: 'normal',
          onLogout: _previewLogout,
        ),
      );
}

Future<void> _previewLogout() async {
  debugPrint('Logout simulado no teste da Home Professional.');
}
