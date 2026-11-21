// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da quebra de linha de modalidades longas em telas
// estreitas, tanto no campo selecionado quanto no menu aberto.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes da seleção dinâmica de modalidade do treinador.
// Uso do estado específico de treinador, padronização de arquivo, tipos, campos
// e chaves com o termo sport e cobertura da navegação para experiências.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/authentication/application/states/registration_draft.dart';
import 'package:horse_life/features/authentication/data/repositories/training_sport_repository.dart';
import 'package:horse_life/features/authentication/presentation/screens/trainer_experience_screen.dart';
import 'package:horse_life/features/authentication/presentation/screens/training_sport_screen.dart';

class _FakeTrainingSportRepository implements TrainingSportRepository {
  const _FakeTrainingSportRepository(this.sports);

  final List<String> sports;

  @override
  Future<List<String>> fetchSports() async => sports;
}

void main() {
  const registration = TrainerRegistrationDraft(
    firstName: 'Ana',
    lastName: 'Silva',
    email: 'ana@email.com',
  );

  Widget buildApp(TrainingSportScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  testWidgets('loads the sports and shows the third trainer step', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const TrainingSportScreen(
          registration: registration,
          sportRepository: _FakeTrainingSportRepository([
            'Adestramento',
            'Salto',
            'Enduro',
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Modalidade de treinos'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 3 de 8'), findsOneWidget);
    expect(find.text('Adestramento'), findsOneWidget);

    await tester.tap(find.byKey(const Key('training-sport-dropdown')));
    await tester.pumpAndSettle();

    expect(find.text('Salto'), findsOneWidget);
    expect(find.text('Enduro'), findsOneWidget);
  });

  testWidgets('returns the selected sport in the registration draft', (
    tester,
  ) async {
    TrainerRegistrationDraft? receivedRegistration;

    await tester.pumpWidget(
      buildApp(
        TrainingSportScreen(
          registration: registration,
          sportRepository: const _FakeTrainingSportRepository([
            'Adestramento',
            'Salto',
            'Enduro',
          ]),
          onContinue: (updatedRegistration) {
            receivedRegistration = updatedRegistration;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('training-sport-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salto'));
    await tester.pumpAndSettle();

    final continueButton = find.byKey(const Key('continue-training-sport'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);

    expect(receivedRegistration?.firstName, 'Ana');
    expect(receivedRegistration?.email, 'ana@email.com');
    expect(receivedRegistration?.sport, 'Salto');
  });

  testWidgets('wraps long sport names without overflow', (tester) async {
    const longSport =
        'Equitação de trabalho com treinamento especializado avançado';
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildApp(
        const TrainingSportScreen(
          registration: registration,
          sportRepository: _FakeTrainingSportRepository([longSport, 'Salto']),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final dropdown = find.byKey(const Key('training-sport-dropdown'));
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    expect(find.text(longSport), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the trainer experience step after the sport', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const TrainingSportScreen(
          registration: registration,
          sportRepository: _FakeTrainingSportRepository([
            'Adestramento',
            'Salto',
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final continueButton = find.byKey(const Key('continue-training-sport'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(TrainerExperienceScreen), findsOneWidget);
    expect(find.text('Experiências\nprofissionais'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 4 de 8'), findsOneWidget);

    final experienceScreen = tester.widget<TrainerExperienceScreen>(
      find.byType(TrainerExperienceScreen),
    );
    expect(experienceScreen.registration.sport, 'Adestramento');
  });
}
