// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da navegação do treinador para a etapa de nome com oito
// passos de progresso.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes da seleção e propagação do tipo de usuário.
// -----------------------------------------------------------------------------

import '../../../support/features/authentication/data/repositories/local_training_sport_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/authentication/data/models/user_type.dart';
import 'package:horse_life/features/authentication/presentation/screens/profile_selection_screen.dart';
import 'package:horse_life/features/authentication/presentation/screens/registration_name_screen.dart';

void main() {
  // Montagem isolada da tela com o tema de produção.
  Widget buildApp(ProfileSelectionScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  // Conteúdo, opções restritas e abertura do menu.
  testWidgets('shows both supported profiles and the explanatory content', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const ProfileSelectionScreen(trainerSportRepository: const LocalTrainingSportRepository())));

    expect(find.text('Seleção de perfil'), findsOneWidget);
    expect(find.textContaining('Antes dos próximos passos'), findsOneWidget);
    expect(find.text('Responsável'), findsOneWidget);
    expect(find.textContaining('Usuários responsáveis'), findsOneWidget);
    expect(find.textContaining('Usuários treinadores'), findsOneWidget);
    expect(find.text('Seguinte'), findsOneWidget);

    await tester.tap(find.byKey(const Key('profile-dropdown')));
    await tester.pumpAndSettle();

    expect(find.text('Responsável'), findsNWidgets(2));
    expect(find.text('Treinador'), findsOneWidget);
  });

  // Propagação tipada da escolha profissional.
  testWidgets('passes the selected profile to the next registration flow', (
    tester,
  ) async {
    UserType? receivedType;

    await tester.pumpWidget(
      buildApp(
        ProfileSelectionScreen(trainerSportRepository: const LocalTrainingSportRepository(), onContinue: (type) => receivedType = type),
      ),
    );

    await tester.tap(find.byKey(const Key('profile-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Treinador').last);
    await tester.pumpAndSettle();
    final continueButton = find.byKey(const Key('continue-profile-selection'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);

    expect(receivedType, UserType.trainer);
  });

  // Valor inicial adotado para o fluxo de responsável.
  testWidgets('uses guardian as the initial profile', (tester) async {
    UserType? receivedType;

    await tester.pumpWidget(
      buildApp(
        ProfileSelectionScreen(trainerSportRepository: const LocalTrainingSportRepository(), onContinue: (type) => receivedType = type),
      ),
    );

    final continueButton = find.byKey(const Key('continue-profile-selection'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);

    expect(receivedType, UserType.guardian);
  });

  // Navegação padrão para a primeira etapa do cadastro.
  testWidgets('opens the guardian registration when no flow is injected', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const ProfileSelectionScreen(trainerSportRepository: const LocalTrainingSportRepository())));

    final continueButton = find.byKey(const Key('continue-profile-selection'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationNameScreen), findsOneWidget);
    expect(find.text('Como você se chama?'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 1 de 4'), findsOneWidget);
  });

  // Navegação padrão para o primeiro dos oito passos do treinador.
  testWidgets('opens the trainer registration with eight progress steps', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const ProfileSelectionScreen(trainerSportRepository: const LocalTrainingSportRepository())));

    await tester.tap(find.byKey(const Key('profile-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Treinador').last);
    await tester.pumpAndSettle();

    final continueButton = find.byKey(const Key('continue-profile-selection'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationNameScreen), findsOneWidget);
    expect(find.text('Como você se chama?'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 1 de 8'), findsOneWidget);
    expect(
      find.byKey(const Key('registration-progress-segment-8')),
      findsOneWidget,
    );
  });
}
