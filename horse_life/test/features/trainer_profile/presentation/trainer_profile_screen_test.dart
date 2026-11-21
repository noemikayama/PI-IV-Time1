// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura dos modais compartilhados, seleção e upload sequencial
// de certificações, inclusão de regiões e navegação para o visualizador de PDF.
//
// Data: 09/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura das listagens de certificações e regiões, incluindo seus
// estados vazios e a abertura individual dos documentos disponíveis.
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do carregamento do perfil, experiência, cavalos, estados
// vazio/erro e integração com a navegação compartilhada da Home.
// -----------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/core/widgets/gradient_button.dart';
import 'package:horse_life/features/authentication/application/states/trainer_document.dart';
import 'package:horse_life/features/authentication/application/states/trainer_service_area.dart';
import 'package:horse_life/features/authentication/data/repositories/brazilian_locations_repository.dart';
import 'package:horse_life/features/home/application/controllers/home_loader.dart';
import 'package:horse_life/features/home/data/models/trainer_home_data.dart';
import 'package:horse_life/features/home/presentation/screens/trainer/trainer_home_screen.dart';
import 'package:horse_life/features/profile/data/models/trainer_profile_data.dart';
import 'package:horse_life/features/profile/presentation/screens/trainer_profile_screen.dart';
import 'package:horse_life/features/profile/presentation/screens/trainer_experience_pdf_screen.dart';
import 'package:horse_life/core/widgets/add_trainer_certifications_dialog.dart';
import 'package:horse_life/features/profile/presentation/widgets/profile_horse_card.dart';
import 'package:horse_life/features/profile/presentation/widgets/trainer_certifications_sheet.dart';
import 'package:horse_life/features/profile/presentation/widgets/trainer_service_regions_sheet.dart';

void main() {
  const profile = TrainerProfileData(
    name: 'Ana Souza',
    email: 'ana@email.com',
    professionalStatus: 'Disponível',
    experience: TrainerExperienceDocument(
      fileName: 'curriculo_ana.pdf',
      url: 'https://storage/curriculo_ana.pdf',
    ),
    certificationCount: 1,
    certifications: [
      TrainerExperienceDocument(
        fileName: 'certificado_ana.pdf',
        url: 'https://storage/certificado_ana.pdf',
      ),
    ],
    serviceRegions: ['Campinas - SP'],
    horses: [TrainerProfileHorse(name: 'Apollo')],
  );

  testWidgets('shows backend trainer data and horse fallback card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TrainerProfileScreen(
            loadTrainerProfile: () async => profile,
            onLogout: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('Disponível'), findsOneWidget);
    expect(find.text('Cavalos sob tutoria'), findsOneWidget);
    expect(find.text('Total: 1'), findsOneWidget);
    expect(find.byType(ProfileHorseCard), findsOneWidget);
    expect(
      find.byKey(const Key('profile-horse-image-fallback')),
      findsOneWidget,
    );
  });

  testWidgets('opens trainer profile from shared bottom navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TrainerHomeScreen(
          loader: _TrainerHomeLoader(),
          trainerProfileLoader: () async => profile,
          onLogout: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cavalos sob tutoria'), findsNothing);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Cavalos sob tutoria'), findsOneWidget);
    expect(find.text('Ana Souza'), findsOneWidget);
  });

  testWidgets('opens experience PDF with its file name in the header', (
    tester,
  ) async {
    Uri? openedUri;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TrainerProfileScreen(
            loadTrainerProfile: () async => profile,
            onLogout: () async {},
            experienceDocumentBuilder: (context, uri) {
              openedUri = uri;
              return const SizedBox(key: Key('fake-experience-document'));
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Ver experiência profissional'));
    await tester.pumpAndSettle();

    expect(find.byType(TrainerExperiencePdfScreen), findsOneWidget);
    expect(find.text('curriculo_ana.pdf'), findsOneWidget);
    expect(openedUri, Uri.parse('https://storage/curriculo_ana.pdf'));
    expect(find.byKey(const Key('fake-experience-document')), findsOneWidget);

    await tester.tap(find.byKey(const Key('close-experience-pdf-button')));
    await tester.pumpAndSettle();
    expect(find.byType(TrainerExperiencePdfScreen), findsNothing);
  });

  testWidgets('opens a scrollable certifications sheet and reuses PDF reader', (
    tester,
  ) async {
    Uri? openedUri;
    final certifications = List.generate(
      8,
      (index) => TrainerExperienceDocument(
        fileName: 'certificado_${index + 1}.pdf',
        url: 'https://storage/certificado_${index + 1}.pdf',
      ),
    );
    final profileWithCertifications = TrainerProfileData(
      name: profile.name,
      email: profile.email,
      professionalStatus: profile.professionalStatus,
      experience: profile.experience,
      certificationCount: certifications.length,
      certifications: certifications,
      serviceRegions: profile.serviceRegions,
      horses: profile.horses,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TrainerProfileScreen(
            loadTrainerProfile: () async => profileWithCertifications,
            onLogout: () async {},
            experienceDocumentBuilder: (context, uri) {
              openedUri = uri;
              return const SizedBox(key: Key('fake-certification-document'));
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Ver certificações'));
    await tester.pumpAndSettle();

    expect(find.byType(TrainerCertificationsSheet), findsOneWidget);
    expect(
      find.byKey(const Key('trainer-certifications-scroll')),
      findsOneWidget,
    );
    final list = find.byKey(const Key('trainer-certifications-scroll'));
    await tester.drag(list, const Offset(0, -500));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('trainer-certification-certificado_8.pdf')),
    );
    await tester.tap(
      find.byKey(const ValueKey('trainer-certification-certificado_8.pdf')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TrainerCertificationsSheet), findsNothing);
    expect(find.byType(TrainerExperiencePdfScreen), findsOneWidget);
    expect(find.text('certificado_8.pdf'), findsOneWidget);
    expect(openedUri, Uri.parse('https://storage/certificado_8.pdf'));
    expect(
      find.byKey(const Key('fake-certification-document')),
      findsOneWidget,
    );
  });

  testWidgets('opens a scrollable service regions sheet', (tester) async {
    final regions = List.generate(8, (index) => 'Região ${index + 1} - SP');
    final profileWithRegions = TrainerProfileData(
      name: profile.name,
      email: profile.email,
      professionalStatus: profile.professionalStatus,
      experience: profile.experience,
      certificationCount: profile.certificationCount,
      certifications: profile.certifications,
      serviceRegions: regions,
      horses: profile.horses,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TrainerProfileScreen(
            loadTrainerProfile: () async => profileWithRegions,
            onLogout: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Ver regiões de atendimento'));
    await tester.pumpAndSettle();

    expect(find.byType(TrainerServiceRegionsSheet), findsOneWidget);
    expect(find.text('Regiões de atendimento'), findsOneWidget);
    final list = find.byKey(const Key('trainer-service-regions-scroll'));
    expect(list, findsOneWidget);
    expect(find.text('Região 1 - SP'), findsOneWidget);

    await tester.drag(list, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('trainer-service-region-7')),
    );

    expect(find.text('Região 8 - SP'), findsOneWidget);
  });

  testWidgets('shows the designed empty state when there are no regions', (
    tester,
  ) async {
    final profileWithoutRegions = TrainerProfileData(
      name: profile.name,
      email: profile.email,
      professionalStatus: profile.professionalStatus,
      experience: profile.experience,
      certificationCount: profile.certificationCount,
      certifications: profile.certifications,
      serviceRegions: const [],
      horses: profile.horses,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TrainerProfileScreen(
            loadTrainerProfile: () async => profileWithoutRegions,
            onLogout: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Ver regiões de atendimento'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('empty-service-regions-icon')), findsOneWidget);
    expect(find.text('Nenhuma região informada'), findsOneWidget);
    expect(
      find.text(
        'Adicione uma para que os usuários saibam onde podem usar seus serviços.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('selects a city and adds it to the trainer profile', (
    tester,
  ) async {
    TrainerServiceArea? addedArea;
    var profileLoads = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TrainerProfileScreen(
            loadTrainerProfile: () async {
              profileLoads++;
              return profile;
            },
            onLogout: () async {},
            locationsRepository: _ProfileLocationsRepository(),
            addTrainerServiceArea: (area) async => addedArea = area,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Ver regiões de atendimento'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('add-trainer-service-region-button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('service-area-type-city')));
    await tester.tap(find.byKey(const Key('continue-service-area-type')));
    await tester.pumpAndSettle();

    expect(find.text('Adicionar cidade'), findsOneWidget);
    expect(find.byKey(const Key('country-region-dropdown')), findsOneWidget);
    expect(
      find.byKey(const Key('service-area-state-dropdown')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('service-area-city-dropdown')), findsOneWidget);

    await tester.tap(find.byKey(const Key('save-service-area')));
    await tester.pumpAndSettle();

    expect(addedArea?.type, TrainerServiceAreaType.city);
    expect(addedArea?.stateCode, 'SP');
    expect(addedArea?.cityName, 'Campinas');
    expect(profileLoads, 2);
  });

  testWidgets('shows the designed empty state for certifications', (
    tester,
  ) async {
    final profileWithoutCertifications = TrainerProfileData(
      name: profile.name,
      email: profile.email,
      professionalStatus: profile.professionalStatus,
      experience: profile.experience,
      certificationCount: 0,
      serviceRegions: profile.serviceRegions,
      horses: profile.horses,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TrainerProfileScreen(
            loadTrainerProfile: () async => profileWithoutCertifications,
            onLogout: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Ver certificações'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('empty-trainer-certifications-icon')),
      findsOneWidget,
    );
    expect(find.text('Nenhuma certificação anexada'), findsOneWidget);
    expect(
      find.text('Adicione uma para que os usuários vejam o que você alcançou.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'adds certifications in a modal with two visible files and scrolling',
    (tester) async {
      final uploadedDocuments = <TrainerDocument>[];
      var profileLoads = 0;
      final selectedFiles = List.generate(
        3,
        (index) => XFile(
          '/tmp/certificado_${index + 1}.pdf',
          name: 'certificado_${index + 1}.pdf',
          mimeType: 'application/pdf',
          length: 5,
          bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, index]),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: TrainerProfileScreen(
              loadTrainerProfile: () async {
                profileLoads++;
                return profile;
              },
              onLogout: () async {},
              certificationsFilePicker: () async => selectedFiles,
              certificationsFileSizeLoader: (_) async => 5,
              uploadTrainerCertification: (document) async {
                uploadedDocuments.add(document);
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Ver certificações'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('add-trainer-certification-button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AddTrainerCertificationsDialog), findsOneWidget);
      expect(find.text('Adicionar\ncertificação'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('pick-profile-certification-files')),
      );
      await tester.pumpAndSettle();

      final list = find.byKey(const Key('new-trainer-certifications-list'));
      expect(list, findsOneWidget);
      expect(tester.getSize(list).height, 148);
      expect(
        find.byKey(const ValueKey('new-trainer-certification-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('new-trainer-certification-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('new-trainer-certification-2')),
        findsNothing,
      );

      await tester.drag(list, const Offset(0, -90));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('new-trainer-certification-2')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const Key('remove-new-trainer-certification-certificado_3.pdf'),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-trainer-certifications')));
      await tester.pumpAndSettle();

      expect(find.byType(AddTrainerCertificationsDialog), findsNothing);
      expect(uploadedDocuments.map((document) => document.name), [
        'certificado_1.pdf',
        'certificado_2.pdf',
      ]);
      expect(profileLoads, 2);
    },
  );

  testWidgets('selects and uploads a single experience PDF from empty state', (
    tester,
  ) async {
    final profileWithoutExperience = TrainerProfileData(
      name: profile.name,
      email: profile.email,
      professionalStatus: profile.professionalStatus,
      experience: null,
      certificationCount: profile.certificationCount,
      certifications: profile.certifications,
      serviceRegions: profile.serviceRegions,
      horses: profile.horses,
    );
    TrainerDocument? uploadedDocument;
    var pickerCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: TrainerProfileScreen(
            loadTrainerProfile: () async => profileWithoutExperience,
            onLogout: () async {},
            experienceFilePicker: () async {
              pickerCalls++;
              return XFile(
                '/tmp/nova_experiencia.pdf',
                name: 'nova_experiencia.pdf',
                mimeType: 'application/pdf',
                length: 5,
                bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]),
              );
            },
            experienceFileSizeLoader: (file) async => 5,
            uploadTrainerExperience: (document) async {
              uploadedDocument = document;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Ver experiência profissional'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum arquivo anexado'), findsOneWidget);
    expect(find.byType(GradientButton), findsOneWidget);
    expect(find.text('+ Adicionar'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('add-empty-trainer-experience-button')),
    );
    await tester.pump();
    expect(pickerCalls, 1);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(uploadedDocument?.name, 'nova_experiencia.pdf');
    expect(uploadedDocument?.sizeInBytes, 5);
  });
}

class _TrainerHomeLoader implements HomeLoader<TrainerHomeData> {
  @override
  Future<TrainerHomeData> fetchHome() async => const TrainerHomeData(
    trainerName: 'Ana',
    specialty: null,
    todayTrainings: [],
    weeklyFeedbacksDone: 0,
    weeklyFeedbacksTotal: 0,
    activePlans: null,
    weeklyTrainingsCompleted: 0,
    weeklyTrainingsPlanned: 0,
    createdExercises: 0,
    horses: [],
    clients: [],
  );
}

class _ProfileLocationsRepository implements BrazilianLocationsRepository {
  @override
  Future<List<String>> fetchCities(String stateCode) async => ['Campinas'];

  @override
  Future<List<BrazilianStateOption>> fetchStates() async => const [
    BrazilianStateOption(name: 'São Paulo', code: 'SP'),
  ];
}
