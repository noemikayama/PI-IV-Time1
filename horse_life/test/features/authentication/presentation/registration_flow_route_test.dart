// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da composição padrão, da injeção de teste e da
// escolha do controller correspondente ao perfil.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/authentication/application/controllers/registration_controller.dart';
import 'package:horse_life/features/authentication/application/states/registration_draft.dart';
import 'package:horse_life/features/authentication/data/repositories/registration_repository.dart';
import 'package:horse_life/features/authentication/data/repositories/training_sport_repository.dart';
import 'package:horse_life/features/authentication/presentation/routes/registration_flow_route.dart';
import 'package:horse_life/features/authentication/presentation/screens/profile_selection_screen.dart';
import 'package:horse_life/features/authentication/presentation/screens/registration_name_screen.dart';

void main() {
  testWidgets('builds the registration flow with its default controller', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp());

    await tester.tap(find.text('Abrir cadastro'));
    await tester.pumpAndSettle();

    final screen = tester.widget<ProfileSelectionScreen>(
      find.byType(ProfileSelectionScreen),
    );
    expect(screen.registrationControllerFor, isNotNull);
  });

  testWidgets('uses the trainer controller for the professional profile', (
    tester,
  ) async {
    final guardianController = RegistrationController(
      _FakeRegistrationRepository(),
    );
    final trainerController = RegistrationController(
      _FakeRegistrationRepository(),
    );
    final sportRepository = _FakeTrainingSportRepository();

    await tester.pumpWidget(
      _buildApp(
        guardianController: guardianController,
        trainerController: trainerController,
        trainerSportRepository: sportRepository,
      ),
    );

    await tester.tap(find.text('Abrir cadastro'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Treinador').last);
    await tester.pumpAndSettle();
    final continueButton = find.byKey(const Key('continue-profile-selection'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    final screen = tester.widget<RegistrationNameScreen>(
      find.byType(RegistrationNameScreen),
    );
    expect(screen.registrationController, same(trainerController));
    expect(screen.sportRepository, same(sportRepository));
  });
}

Widget _buildApp({
  RegistrationController? guardianController,
  RegistrationController? trainerController,
  TrainingSportRepository? trainerSportRepository,
}) {
  return MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () => Navigator.push(
          context,
          RegistrationFlowRoute.build(
            guardianController: guardianController,
            trainerController: trainerController,
            trainerSportRepository: trainerSportRepository,
          ),
        ),
        child: const Text('Abrir cadastro'),
      ),
    ),
  );
}

final class _FakeRegistrationRepository implements RegistrationRepository {
  @override
  Future<void> createAccount({
    required RegistrationDraft registration,
    required String password,
  }) async {}
}

final class _FakeTrainingSportRepository implements TrainingSportRepository {
  @override
  Future<List<String>> fetchSports() async => const ['Salto'];
}
