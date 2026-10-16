// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes da etapa de documento profissional único, com
// uso do estado específico do treinador e do atributo sport, cobrindo seleção,
// aparência e remoção do PDF e rejeição de documentos em outros formatos.
// -----------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/authentication/application/states/registration_draft.dart';
import 'package:horse_life/features/authentication/presentation/screens/trainer_experience_screen.dart';

void main() {
  const registration = TrainerRegistrationDraft(
    firstName: 'Ana',
    lastName: 'Silva',
    email: 'ana@email.com',
    sport: 'Salto',
  );

  Widget buildApp(TrainerExperienceScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  testWidgets('shows the optional document step as trainer step four', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        TrainerExperienceScreen(
          registration: registration,
          filePicker: () async => null,
        ),
      ),
    );

    expect(find.text('Experiências\nprofissionais'), findsOneWidget);
    expect(find.textContaining('Anexe um documento'), findsOneWidget);
    expect(find.text('Adicionar arquivo'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 4 de 8'), findsOneWidget);
  });

  testWidgets('shows and removes the selected PDF', (tester) async {
    await tester.pumpWidget(
      buildApp(
        TrainerExperienceScreen(
          registration: registration,
          filePicker: () async => XFile.fromData(
            Uint8List.fromList([1]),
            path: 'experiencias.pdf',
            mimeType: 'application/pdf',
          ),
        ),
      ),
    );

    final picker = find.byKey(const Key('pick-trainer-experience-file'));
    await tester.tap(picker);
    await tester.pumpAndSettle();
    expect(find.text('experiencias.pdf'), findsOneWidget);
    expect(
      find.byKey(const Key('trainer-experience-pdf-icon')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('remove-trainer-experience-file')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('remove-trainer-experience-file')));
    await tester.pumpAndSettle();
    expect(find.text('experiencias.pdf'), findsNothing);
    expect(find.text('Adicionar arquivo'), findsOneWidget);
  });

  testWidgets('continues with the selected optional document', (tester) async {
    TrainerRegistrationDraft? receivedRegistration;

    await tester.pumpWidget(
      buildApp(
        TrainerExperienceScreen(
          registration: registration,
          filePicker: () async => XFile.fromData(
            Uint8List.fromList([1, 2, 3]),
            path: 'curriculo.pdf',
            mimeType: 'application/pdf',
          ),
          onContinue: (updatedRegistration) {
            receivedRegistration = updatedRegistration;
          },
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('pick-trainer-experience-file')));
    await tester.pumpAndSettle();

    final continueButton = find.byKey(const Key('continue-trainer-experience'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);

    final document = receivedRegistration?.trainerExperienceDocument;
    expect(document?.name, 'curriculo.pdf');
    expect(document?.sizeInBytes, 3);
    expect(receivedRegistration?.sport, 'Salto');
  });

  testWidgets('allows continuing without selecting a document', (tester) async {
    TrainerRegistrationDraft? receivedRegistration;

    await tester.pumpWidget(
      buildApp(
        TrainerExperienceScreen(
          registration: registration,
          filePicker: () async => null,
          onContinue: (updatedRegistration) {
            receivedRegistration = updatedRegistration;
          },
        ),
      ),
    );

    final continueButton = find.byKey(const Key('continue-trainer-experience'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);

    expect(receivedRegistration?.firstName, registration.firstName);
    expect(receivedRegistration?.trainerExperienceDocument, isNull);
  });

  testWidgets('opens trainer certifications as the following step', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        TrainerExperienceScreen(
          registration: registration,
          filePicker: () async => null,
        ),
      ),
    );

    final continueButton = find.byKey(const Key('continue-trainer-experience'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Certificações\nprofissionais'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 5 de 8'), findsOneWidget);
  });

  testWidgets('rejects a selected document that is not a PDF', (tester) async {
    await tester.pumpWidget(
      buildApp(
        TrainerExperienceScreen(
          registration: registration,
          filePicker: () async => XFile.fromData(
            Uint8List.fromList([1, 2, 3]),
            path: 'curriculo.docx',
            mimeType:
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('pick-trainer-experience-file')));
    await tester.pumpAndSettle();

    expect(find.text('Selecione um arquivo no formato PDF.'), findsOneWidget);
    expect(find.text('curriculo.docx'), findsNothing);
    expect(find.text('Adicionar arquivo'), findsOneWidget);
  });
}
