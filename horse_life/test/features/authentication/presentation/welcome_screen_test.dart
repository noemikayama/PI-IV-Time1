// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da navegação da abertura de conta para a seleção de
// perfil.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes da tela inicial, incluindo composição visual,
// callback de cadastro e navegação para o login.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/core/widgets/gradient_button.dart';
import 'package:horse_life/features/authentication/presentation/screens/login_screen.dart';
import 'package:horse_life/features/authentication/presentation/screens/profile_selection_screen.dart';
import 'package:horse_life/features/authentication/presentation/screens/welcome_screen.dart';
import 'package:horse_life/features/authentication/presentation/widgets/welcome_action_panel.dart';

void main() {
  // Montagem compartilhada com o tema real da aplicação.
  Widget buildApp(Widget home) {
    return MaterialApp(theme: AppTheme.light, home: home);
  }

  // Composição visual e uso dos tokens institucionais.
  testWidgets('shows the branded welcome composition', (tester) async {
    await tester.pumpWidget(buildApp(const WelcomeScreen()));

    expect(find.bySemanticsLabel('Cavalo em um campo'), findsOneWidget);
    expect(find.bySemanticsLabel('HorseLife'), findsOneWidget);
    expect(find.text('É bom te ter no HorseLife'), findsOneWidget);
    expect(find.text('Acessar conta'), findsOneWidget);
    expect(find.text('Abrir uma nova conta'), findsOneWidget);
    expect(find.byType(GradientButton), findsOneWidget);

    final overlay = tester.widget<ColoredBox>(
      find.byKey(const Key('welcome-photo-overlay')),
    );
    expect(overlay.color, AppColors.alabasterGray.withValues(alpha: 0.47));

    final panel = tester.widget<Container>(
      find.byKey(const Key('welcome-action-panel')),
    );
    expect(panel.constraints?.maxHeight, WelcomeActionPanel.height);
  });

  // Rota de acesso para pessoas que já possuem conta.
  testWidgets('opens the login from the primary action', (tester) async {
    await tester.pumpWidget(buildApp(const WelcomeScreen()));

    await tester.tap(find.text('Acessar conta'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  // Contrato injetável que permite coordenação externa do cadastro.
  testWidgets('runs the create-account action', (tester) async {
    var wasCalled = false;

    await tester.pumpWidget(
      buildApp(WelcomeScreen(onCreateAccount: () => wasCalled = true)),
    );

    await tester.tap(find.text('Abrir uma nova conta'));
    await tester.pump();

    expect(wasCalled, isTrue);
  });

  // Fluxo padrão de abertura de conta quando não há callback injetado.
  testWidgets('opens profile selection from the create-account action', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const WelcomeScreen()));

    await tester.tap(find.text('Abrir uma nova conta'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSelectionScreen), findsOneWidget);
    expect(find.text('Seleção de perfil'), findsOneWidget);
  });
}
