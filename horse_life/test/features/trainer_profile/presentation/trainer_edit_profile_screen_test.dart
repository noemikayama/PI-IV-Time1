// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do preenchimento da edição, remoção de dados, payload
// incremental e solicitação de alteração de senha.
// -----------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/profile/data/models/trainer_profile_data.dart';
import 'package:horse_life/features/profile/data/repositories/trainer_profile_repository.dart';
import 'package:horse_life/features/profile/presentation/screens/trainer_edit_profile_screen.dart';
import 'package:horse_life/features/profile/presentation/screens/trainer_profile_screen.dart';

void main() {
  const profile = TrainerProfileData(
    name: 'Ana Souza',
    email: 'ana@email.com',
    professionalStatus: 'Disponível',
    experience: TrainerExperienceDocument(
      fileName: 'experiencia_1.pdf',
      url: 'https://storage/experiencia.pdf',
      path: '/arquivos/treinadores/1/experiencia_1.pdf',
    ),
    certificationCount: 1,
    certifications: [
      TrainerExperienceDocument(
        fileName: 'certificacao_1.pdf',
        url: 'https://storage/certificacao.pdf',
        path: '/arquivos/treinadores/1/certificacao_1.pdf',
      ),
    ],
    serviceRegions: ['Campinas - SP'],
    serviceRegionEntries: [
      TrainerProfileServiceRegion(state: 'SP', city: 'Campinas'),
    ],
    horses: [],
  );

  testWidgets('opens edit profile filled with backend data', (tester) async {
    await tester.pumpWidget(
      _app(
        TrainerProfileScreen(
          loadTrainerProfile: () async => profile,
          onLogout: () async {},
          updateTrainerProfile: (_) async {},
          uploadTrainerExperience: (_) async {},
          uploadTrainerCertification: (_) async {},
          requestPasswordReset: (_) async => 'E-mail enviado.',
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const Key('edit-trainer-profile-button')),
    );
    await tester.tap(find.byKey(const Key('edit-trainer-profile-button')));
    await tester.pumpAndSettle();

    expect(find.byType(TrainerEditProfileScreen), findsOneWidget);
    expect(find.text('Editar perfil'), findsOneWidget);
    expect(_fieldText(tester, 'trainer-edit-first-name'), 'Ana');
    expect(_fieldText(tester, 'trainer-edit-last-name'), 'Souza');
    expect(find.text('ana@email.com'), findsOneWidget);
    expect(find.text('experiencia_1.pdf'), findsOneWidget);
    expect(find.text('certificacao_1.pdf'), findsOneWidget);
    expect(find.text('Campinas - SP'), findsOneWidget);
    expect(find.text('Disponível'), findsOneWidget);
  });

  testWidgets('saves name and removals in a single backend update', (
    tester,
  ) async {
    TrainerProfileUpdate? receivedUpdate;
    await tester.pumpWidget(
      _app(
        TrainerEditProfileScreen(
          profile: profile,
          updateProfile: (update) async => receivedUpdate = update,
          uploadExperience: (_) async {},
          uploadCertification: (_) async {},
          requestPasswordReset: (_) async => 'E-mail enviado.',
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(
      find.byKey(const Key('trainer-edit-last-name')),
      'Silva',
    );
    await _removeItem(
      tester,
      const ValueKey('trainer-edit-certification-certificacao_1.pdf'),
    );
    await _removeItem(
      tester,
      const ValueKey('trainer-edit-region-sp|campinas|'),
    );
    await tester.ensureVisible(
      find.byKey(const Key('save-trainer-profile-changes')),
    );
    tester
        .widget<OutlinedButton>(
          find.byKey(const Key('save-trainer-profile-changes')),
        )
        .onPressed!();
    await tester.pumpAndSettle();

    expect(receivedUpdate?.firstName, 'Ana');
    expect(receivedUpdate?.lastName, 'Silva');
    expect(receivedUpdate?.certificationPathsToRemove, [
      '/arquivos/treinadores/1/certificacao_1.pdf',
    ]);
    expect(receivedUpdate?.serviceRegionsToRemove.single.city, 'Campinas');
  });

  testWidgets('requests password reset for the read-only profile email', (
    tester,
  ) async {
    String? requestedEmail;
    await tester.pumpWidget(
      _app(
        TrainerEditProfileScreen(
          profile: profile,
          updateProfile: (_) async {},
          uploadExperience: (_) async {},
          uploadCertification: (_) async {},
          requestPasswordReset: (email) async {
            requestedEmail = email;
            return 'E-mail enviado.';
          },
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(find.byKey(const Key('trainer-edit-password')));
    await tester.tap(find.byKey(const Key('trainer-edit-password')));
    await tester.pump();

    expect(requestedEmail, 'ana@email.com');
    expect(find.text('E-mail enviado.'), findsOneWidget);
  });

  testWidgets('updates profile before uploading newly selected PDFs', (
    tester,
  ) async {
    final events = <String>[];
    final profileWithoutMedia = TrainerProfileData(
      name: profile.name,
      email: profile.email,
      professionalStatus: profile.professionalStatus,
      experience: null,
      certificationCount: 0,
      serviceRegions: profile.serviceRegions,
      serviceRegionEntries: profile.serviceRegionEntries,
      horses: profile.horses,
    );
    final experience = XFile(
      '/tmp/nova_experiencia.pdf',
      name: 'nova_experiencia.pdf',
      mimeType: 'application/pdf',
      length: 5,
      bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]),
    );
    final certification = XFile(
      '/tmp/nova_certificacao.pdf',
      name: 'nova_certificacao.pdf',
      mimeType: 'application/pdf',
      length: 5,
      bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]),
    );
    await tester.pumpWidget(
      _app(
        TrainerEditProfileScreen(
          profile: profileWithoutMedia,
          updateProfile: (_) async => events.add('update'),
          uploadExperience: (_) async => events.add('experience'),
          uploadCertification: (_) async => events.add('certification'),
          requestPasswordReset: (_) async => 'E-mail enviado.',
          experienceFilePicker: () async => experience,
          experienceFileSizeLoader: (_) async => 5,
          certificationsFilePicker: () async => [certification],
          certificationsFileSizeLoader: (_) async => 5,
        ),
      ),
    );
    await tester.pump();

    await tester.ensureVisible(
      find.byKey(const Key('trainer-edit-add-experience')),
    );
    await tester.pumpAndSettle();
    tester
        .widget<TextButton>(
          find.byKey(const Key('trainer-edit-add-experience')),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    expect(find.text('nova_experiencia.pdf'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('trainer-edit-add-certifications')),
    );
    await tester.pumpAndSettle();
    tester
        .widget<TextButton>(
          find.byKey(const Key('trainer-edit-add-certifications')),
        )
        .onPressed!();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pick-profile-certification-files')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-trainer-certifications')));
    await tester.pumpAndSettle();
    expect(find.text('nova_certificacao.pdf'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('save-trainer-profile-changes')),
    );
    tester
        .widget<OutlinedButton>(
          find.byKey(const Key('save-trainer-profile-changes')),
        )
        .onPressed!();
    await tester.pumpAndSettle();

    expect(events, ['update', 'experience', 'certification']);
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

String _fieldText(WidgetTester tester, String key) {
  return tester
      .widget<TextFormField>(find.byKey(ValueKey(key)))
      .controller!
      .text;
}

Future<void> _removeItem(WidgetTester tester, Key key) async {
  final item = find.byKey(key);
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: item, matching: find.byType(IconButton)),
  );
  await tester.pump();
}
