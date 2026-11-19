// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes de widget do HomeAppBar para validar o gradiente linear
// institucional (whiteSmoke -> alabasterGrey) e abertura da gaveta lateral.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';

void main() {
  testWidgets('renders HomeAppBar with linear gradient background and opens drawer', (
    tester,
  ) async {
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

    // Validação da decoração com gradiente linear no flexibleSpace.
    final containerFinder = find.descendant(
      of: find.byType(HomeAppBar),
      matching: find.byType(Container),
    );
    expect(containerFinder, findsWidgets);

    bool foundGradient = false;
    for (final element in tester.widgetList<Container>(containerFinder)) {
      final decoration = element.decoration;
      if (decoration is BoxDecoration && decoration.gradient is LinearGradient) {
        final gradient = decoration.gradient as LinearGradient;
        expect(gradient.begin, Alignment.topCenter);
        expect(gradient.end, Alignment.bottomCenter);
        expect(gradient.colors, [AppColors.whiteSmoke, AppColors.alabasterGray]);
        foundGradient = true;
        break;
      }
    }
    expect(foundGradient, isTrue);

    // Validação do botão que abre o Drawer.
    final openButton = find.byTooltip('Abrir menu');
    expect(openButton, findsOneWidget);

    await tester.tap(openButton);
    await tester.pumpAndSettle();

    expect(scaffoldKey.currentState?.isDrawerOpen, isTrue);
    expect(find.text('Sidebar Drawer'), findsOneWidget);
  });
}

