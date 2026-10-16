import 'package:flutter/material.dart';
import 'app/theme/app_theme.dart';
import 'features/home/presentation/screens/guardian/guardian_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HorseLifeScenarioTestApp());
}

class HorseLifeScenarioTestApp extends StatelessWidget {
  const HorseLifeScenarioTestApp({super.key});

  Future<void> _fakeLogout() async {
    debugPrint('Logout simulado: cenário completed.');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HorseLife — teste completed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: GuardianHomeScreen(
        onLogout: _fakeLogout,
        mockScenario: 'completed',
      ),
    );
  }
}
