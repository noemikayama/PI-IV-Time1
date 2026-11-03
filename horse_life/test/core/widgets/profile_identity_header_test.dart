// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação da montagem isolada do cabeçalho nos testes.
//
// Data: 28/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes do cabeçalho de identidade para os perfis de
// responsável e treinador, incluindo a omissão de status vazio.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/profile/presentation/widgets/profile_identity_header.dart';

void main() {
  // Monta o cabeçalho isoladamente com o tema oficial do aplicativo.
  Widget buildHeader({String? status}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: ProfileIdentityHeader(
          name: 'Nome do usuário',
          email: 'usuario@email.com',
          status: status,
        ),
      ),
    );
  }

  testWidgets('shows name and email without status for guardian', (
    tester,
  ) async {
    await tester.pumpWidget(buildHeader());

    expect(find.text('Nome do usuário'), findsOneWidget);
    expect(find.text('usuario@email.com'), findsOneWidget);
    expect(find.byKey(const Key('profile-status-chip')), findsNothing);
  });

  testWidgets('shows professional status chip for trainer', (tester) async {
    await tester.pumpWidget(buildHeader(status: 'Disponível'));

    expect(find.text('Disponível'), findsOneWidget);
    final decoratedBox = tester.widget<DecoratedBox>(
      find.byKey(const Key('profile-status-chip')),
    );
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(decoration.color, AppColors.pearlAqua);
  });

  testWidgets('does not show a blank status', (tester) async {
    await tester.pumpWidget(buildHeader(status: '   '));

    expect(find.byKey(const Key('profile-status-chip')), findsNothing);
  });
}
