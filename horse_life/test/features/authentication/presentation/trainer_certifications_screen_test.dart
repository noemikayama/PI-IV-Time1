// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do limite de dez certificações profissionais.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da etapa de certificações, incluindo múltiplos PDFs,
// limite visual de três itens, rolagem, remoção e continuidade opcional.
// -----------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/authentication/application/states/registration_draft.dart';
import 'package:horse_life/features/authentication/presentation/screens/trainer_certifications_screen.dart';

void main() {
  // Estado profissional já preenchido até a etapa de certificações.
  const registration = TrainerRegistrationDraft(
    firstName: 'Ana',
    lastName: 'Silva',
    email: 'ana@email.com',
    sport: 'Salto',
  );

  // Montagem mínima com o tema usado pela interface real.
  Widget buildApp(TrainerCertificationsScreen screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  // Cria PDFs em memória para controlar nome, conteúdo e tamanho nos testes.
  XFile pdf(String name, [List<int> bytes = const [1]]) {
    return XFile.fromData(
      Uint8List.fromList(bytes),
      path: name,
      mimeType: 'application/pdf',
    );
  }

  // Conteúdo inicial, caráter opcional e progresso da quinta etapa.
  testWidgets('shows the optional certifications step as trainer step five', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        TrainerCertificationsScreen(
          registration: registration,
          filePicker: () async => [],
        ),
      ),
    );

    expect(find.text('Certificações\nprofissionais'), findsOneWidget);
    expect(find.textContaining('Anexe um ou mais documentos'), findsOneWidget);
    expect(find.text('Adicionar arquivo'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 5 de 8'), findsOneWidget);
    expect(find.byKey(const Key('trainer-certifications-list')), findsNothing);
  });

  // Inclusões sucessivas e limite visual com rolagem a partir do quarto item.
  testWidgets('adds PDFs and shows no more than three at once', (
    tester,
  ) async {
    var selection = [pdf('certificado_1.pdf'), pdf('certificado_2.pdf')];

    await tester.pumpWidget(
      buildApp(
        TrainerCertificationsScreen(
          registration: registration,
          filePicker: () async => selection,
        ),
      ),
    );

    final picker = find.byKey(const Key('pick-trainer-certification-files'));
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();

    selection = [pdf('certificado_3.pdf'), pdf('certificado_4.pdf')];
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();

    final list = find.byKey(const Key('trainer-certifications-list'));
    expect(list, findsOneWidget);
    expect(tester.getSize(list).height, 216);
    expect(find.byType(Scrollbar), findsOneWidget);

    final listView = tester.widget<ListView>(
      find.descendant(of: list, matching: find.byType(ListView)),
    );
    expect(listView.controller?.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets('limits the registration to ten certifications', (tester) async {
    TrainerRegistrationDraft? receivedRegistration;

    await tester.pumpWidget(
      buildApp(
        TrainerCertificationsScreen(
          registration: registration,
          filePicker: () async => [
            for (var index = 1; index <= 11; index++)
              pdf('certificado_$index.pdf'),
          ],
          onContinue: (updatedRegistration) {
            receivedRegistration = updatedRegistration;
          },
        ),
      ),
    );

    final picker = find.byKey(const Key('pick-trainer-certification-files'));
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    expect(
      find.text('Somente 10 certificações podem ser adicionadas.'),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    final continueButton = find.byKey(
      const Key('continue-trainer-certifications'),
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);

    expect(receivedRegistration?.trainerCertificationDocuments, hasLength(10));
  });

  // Remoção individual e preservação dos metadados do documento restante.
  testWidgets('removes one PDF and continues with the remaining documents', (
    tester,
  ) async {
    TrainerRegistrationDraft? receivedRegistration;

    await tester.pumpWidget(
      buildApp(
        TrainerCertificationsScreen(
          registration: registration,
          filePicker: () async => [
            pdf('primeiro.pdf', [1, 2]),
            pdf('segundo.pdf', [1, 2, 3]),
          ],
          onContinue: (updatedRegistration) {
            receivedRegistration = updatedRegistration;
          },
        ),
      ),
    );

    final picker = find.byKey(const Key('pick-trainer-certification-files'));
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('remove-trainer-certification-primeiro.pdf')),
    );
    await tester.pumpAndSettle();

    final continueButton = find.byKey(
      const Key('continue-trainer-certifications'),
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);

    final documents = receivedRegistration?.trainerCertificationDocuments ?? [];
    expect(documents, hasLength(1));
    expect(documents.single.name, 'segundo.pdf');
    expect(documents.single.sizeInBytes, 3);
    expect(receivedRegistration?.sport, 'Salto');
  });

  // Continuidade permitida quando nenhuma certificação opcional foi escolhida.
  testWidgets('allows continuing without selecting a certification', (
    tester,
  ) async {
    TrainerRegistrationDraft? receivedRegistration;

    await tester.pumpWidget(
      buildApp(
        TrainerCertificationsScreen(
          registration: registration,
          filePicker: () async => [],
          onContinue: (updatedRegistration) {
            receivedRegistration = updatedRegistration;
          },
        ),
      ),
    );

    final continueButton = find.byKey(
      const Key('continue-trainer-certifications'),
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);

    expect(receivedRegistration?.trainerCertificationDocuments, isEmpty);
  });

  // Encadeamento padrão da quinta para a sexta etapa do treinador.
  testWidgets('opens service areas as the following step', (tester) async {
    await tester.pumpWidget(
      buildApp(
        TrainerCertificationsScreen(
          registration: registration,
          filePicker: () async => [],
        ),
      ),
    );

    final continueButton = find.byKey(
      const Key('continue-trainer-certifications'),
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Regiões de\natendimento'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 6 de 8'), findsOneWidget);
  });

  // Defesa adicional caso o seletor nativo devolva uma extensão inválida.
  testWidgets('rejects files that are not PDFs', (tester) async {
    await tester.pumpWidget(
      buildApp(
        TrainerCertificationsScreen(
          registration: registration,
          filePicker: () async => [
            XFile.fromData(
              Uint8List.fromList([1]),
              path: 'certificado.docx',
              mimeType:
                  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            ),
          ],
        ),
      ),
    );

    final picker = find.byKey(const Key('pick-trainer-certification-files'));
    await tester.ensureVisible(picker);
    await tester.tap(picker);
    await tester.pumpAndSettle();

    expect(
      find.text('Somente arquivos no formato PDF foram adicionados.'),
      findsOneWidget,
    );
    expect(find.text('certificado.docx'), findsNothing);
  });
}
