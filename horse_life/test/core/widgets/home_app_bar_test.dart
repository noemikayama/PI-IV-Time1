// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Validação de que o AppBar acompanha a cor de fundo da tela sem
// gradiente ou tonalização de superfície. Documentação do cenário e
// das expectativas visuais atualizadas.
//
// Data: 27/10/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes de widget do HomeAppBar para validar o gradiente linear
// institucional (whiteSmoke -> alabasterGrey) e abertura da gaveta lateral.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';

void main() {
  testWidgets('matches screen background and opens drawer', (tester) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          appBar: const HomeAppBar(),
          drawer: const Drawer(child: Text('Sidebar Drawer')),
          body: const SizedBox(),
        ),
      ),
    );

    // Validação da presença do AppBar.
    expect(find.byType(HomeAppBar), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final appBarContext = tester.element(find.byType(HomeAppBar));
    expect(
      appBar.backgroundColor,
      Theme.of(appBarContext).scaffoldBackgroundColor,
    );
    expect(appBar.surfaceTintColor, Colors.transparent);
    expect(appBar.flexibleSpace, isNull);

    // Validação do botão que abre o Drawer.
    final openButton = find.byTooltip('Abrir menu');
    expect(openButton, findsOneWidget);

    await tester.tap(openButton);
    await tester.pumpAndSettle();

    expect(scaffoldKey.currentState?.isDrawerOpen, isTrue);
    expect(find.text('Sidebar Drawer'), findsOneWidget);
  });
}
