// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da revisão, remoções e submissão final do treinador.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/authentication/application/controllers/registration_controller.dart';
import 'package:horse_life/features/authentication/application/states/registration_draft.dart';
import 'package:horse_life/features/authentication/application/states/trainer_document.dart';
import 'package:horse_life/features/authentication/application/states/trainer_service_area.dart';
import 'package:horse_life/features/authentication/data/repositories/registration_repository.dart';
import 'package:horse_life/features/authentication/presentation/screens/trainer_confirmation_screen.dart';

void main() {
  // Cadastro completo usado para exercitar todas as seções da revisão.
  const registration = TrainerRegistrationDraft(
    firstName: 'Ana',
    lastName: 'Silva',
    email: 'ana@email.com',
    sport: 'Salto',
    trainerExperienceDocument: TrainerDocument(
      name: 'experiencias.pdf',
      path: '/experiencias.pdf',
      sizeInBytes: 10,
      mimeType: 'application/pdf',
    ),
    trainerCertificationDocuments: [
      TrainerDocument(
        name: 'certificado_1.pdf',
        path: '/certificado_1.pdf',
        sizeInBytes: 11,
        mimeType: 'application/pdf',
      ),
      TrainerDocument(
        name: 'certificado_2.pdf',
        path: '/certificado_2.pdf',
        sizeInBytes: 12,
        mimeType: 'application/pdf',
      ),
    ],
    serviceAreas: [
      TrainerServiceArea.city(
        countryRegion: 'Sudeste',
        stateCode: 'SP',
        stateName: 'São Paulo',
        cityName: 'Campinas',
      ),
      TrainerServiceArea.city(
        countryRegion: 'Sudeste',
        stateCode: 'SP',
        stateName: 'São Paulo',
        cityName: 'Ribeirão Preto',
      ),
    ],
  );

  // Monta cada cenário com a configuração visual real da aplicação.
  Widget buildApp(Widget home) {
    return MaterialApp(theme: AppTheme.light, home: home);
  }

  // Conteúdo consolidado e ausência de ações próprias das etapas de coleta.
  testWidgets('reviews trainer data as step eight without add actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const TrainerConfirmationScreen(
          registration: registration,
          password: 'Senha@123',
        ),
      ),
    );

    expect(find.text('Revise seus dados'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 8 de 8'), findsOneWidget);
    expect(find.text('experiencias.pdf'), findsOneWidget);
    expect(find.text('certificado_1.pdf'), findsOneWidget);
    expect(find.text('certificado_2.pdf'), findsOneWidget);
    expect(find.text('Campinas - SP'), findsOneWidget);
    expect(find.text('Ribeirão Preto - SP'), findsOneWidget);
    expect(find.byKey(const Key('add-service-area')), findsNothing);
    expect(
      find.byKey(const Key('pick-trainer-certification-files')),
      findsNothing,
    );
  });

  // Edição inline do contato sem perda dos dados profissionais já coletados.
  testWidgets('edits common fields with the guardian review behavior', (
    tester,
  ) async {
    TrainerRegistrationDraft? updatedRegistration;

    await tester.pumpWidget(
      buildApp(
        TrainerConfirmationScreen(
          registration: registration,
          password: 'Senha@123',
          onEditPassword: (registration) {
            updatedRegistration = registration;
          },
        ),
      ),
    );

    final editFirstName = find.byTooltip('Editar Primeiro nome');
    await tester.ensureVisible(editFirstName);
    await tester.tap(editFirstName);
    await tester.enterText(
      find.byKey(const Key('trainer-review-first-name')),
      'Beatriz',
    );
    await tester.tap(find.byTooltip('Concluir edição de Primeiro nome'));

    final editPassword = find.byTooltip('Editar Senha');
    await tester.ensureVisible(editPassword);
    await tester.tap(editPassword);
    await tester.pump();

    expect(updatedRegistration?.firstName, 'Beatriz');
    expect(updatedRegistration?.sport, 'Salto');
    expect(updatedRegistration?.trainerCertificationDocuments, hasLength(2));
  });

  // Remoções durante a revisão e conteúdo exato entregue ao repositório.
  testWidgets('removes media and regions and submits only remaining data', (
    tester,
  ) async {
    final repository = _FakeRegistrationRepository();
    var wasCreated = false;

    await tester.pumpWidget(
      buildApp(
        TrainerConfirmationScreen(
          registration: registration,
          password: 'Senha@123',
          registrationController: RegistrationController(repository),
          onCreated: () => wasCreated = true,
        ),
      ),
    );

    final removeExperience = find.byKey(
      const Key('remove-trainer-review-experience'),
    );
    await tester.ensureVisible(removeExperience);
    await tester.tap(removeExperience);
    await tester.pump();

    final removeCertification = find.byKey(
      const ValueKey('remove-trainer-review-certification-0'),
    );
    await tester.ensureVisible(removeCertification);
    await tester.tap(removeCertification);
    await tester.pump();

    final removeArea = find.byKey(
      const ValueKey('remove-trainer-review-service-area-0'),
    );
    await tester.ensureVisible(removeArea);
    await tester.tap(removeArea);
    await tester.pump();

    final createButton = find.byKey(
      const Key('create-trainer-registration-account'),
    );
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    final submitted = repository.receivedRegistration;
    expect(submitted, isA<TrainerRegistrationDraft>());
    final trainer = submitted! as TrainerRegistrationDraft;
    expect(trainer.trainerExperienceDocument, isNull);
    expect(trainer.trainerCertificationDocuments, hasLength(1));
    expect(
      trainer.trainerCertificationDocuments.single.name,
      'certificado_2.pdf',
    );
    expect(trainer.serviceAreas, hasLength(1));
    expect(trainer.serviceAreas.single.cityName, 'Ribeirão Preto');
    expect(repository.receivedPassword, 'Senha@123');
    expect(wasCreated, isTrue);
  });
}

// Espião simples que captura os argumentos enviados pelo controller.
class _FakeRegistrationRepository implements RegistrationRepository {
  RegistrationDraft? receivedRegistration;
  String? receivedPassword;

  @override
  Future<void> createAccount({
    required RegistrationDraft registration,
    required String password,
  }) async {
    receivedRegistration = registration;
    receivedPassword = password;
  }
}
