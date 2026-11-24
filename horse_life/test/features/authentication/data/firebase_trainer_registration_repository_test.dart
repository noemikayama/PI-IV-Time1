// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 09/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da criação da URL assinada, envio e confirmação de um
// documento adicionado após a autenticação do treinador.
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do payload profissional, da ordem dos uploads, da
// autenticação temporária e das falhas posteriores à criação da conta.
// -----------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/authentication/application/states/registration_draft.dart';
import 'package:horse_life/features/authentication/application/states/trainer_document.dart';
import 'package:horse_life/features/authentication/application/states/trainer_service_area.dart';
import 'package:horse_life/features/authentication/data/repositories/firebase_trainer_registration_repository.dart';
import 'package:horse_life/features/authentication/data/repositories/registration_repository.dart';

void main() {
  test('registers before uploading each PDF sequentially', () async {
    final events = <String>[];
    Map<String, Object>? registrationData;
    var uploadIndex = 0;
    final repository = FirebaseTrainerRegistrationRepository(
      registerTrainer: (data) async {
        events.add('register');
        registrationData = data;
      },
      authenticate: (email, password) async => events.add('authenticate'),
      createAttachmentUpload: (type) async {
        events.add('create:${type.value}');
        uploadIndex++;
        return TrainerAttachmentUpload(
          path: '/document-$uploadIndex.pdf',
          url: 'https://storage.test/$uploadIndex',
          headers: const {'Content-Type': 'application/pdf'},
        );
      },
      uploadFile: (upload, bytes) async {
        events.add('upload:${upload.path}:${bytes.single}');
      },
      confirmAttachment: (type, path) async {
        events.add('confirm:${type.value}:$path');
      },
      signOut: () async => events.add('signOut'),
    );

    await repository.createAccount(
      registration: _registrationWithDocuments(),
      password: 'Senha@123',
    );

    expect(registrationData, {
      'nome': 'Ana Silva',
      'email': 'ana@email.com',
      'senha': 'Senha@123',
      'modalidades': ['Salto'],
      'regioesAtendimento': [
        {
          'estado': 'PR',
          'cidade': 'Todas as cidades',
          'complemento': 'Região Sul',
        },
        {
          'estado': 'RS',
          'cidade': 'Todas as cidades',
          'complemento': 'Região Sul',
        },
        {
          'estado': 'SC',
          'cidade': 'Todas as cidades',
          'complemento': 'Região Sul',
        },
        {'estado': 'SP', 'cidade': 'Campinas'},
      ],
    });
    expect(registrationData, isNot(contains('experiencias')));
    expect(registrationData, isNot(contains('certificacoes')));
    expect(events, [
      'register',
      'authenticate',
      'create:experiencias',
      'upload:/document-1.pdf:1',
      'confirm:experiencias:/document-1.pdf',
      'create:certificacoes',
      'upload:/document-2.pdf:2',
      'confirm:certificacoes:/document-2.pdf',
      'create:certificacoes',
      'upload:/document-3.pdf:3',
      'confirm:certificacoes:/document-3.pdf',
      'signOut',
    ]);
  });

  test('does not authenticate when no document was selected', () async {
    var authenticationCalls = 0;
    final repository = FirebaseTrainerRegistrationRepository(
      registerTrainer: (data) async {},
      authenticate: (email, password) async => authenticationCalls++,
    );

    await repository.createAccount(
      registration: const TrainerRegistrationDraft(
        firstName: 'Ana',
        lastName: 'Silva',
        email: 'ana@email.com',
        sport: 'Salto',
      ),
      password: 'Senha@123',
    );

    expect(authenticationCalls, 0);
  });

  test('uploads an attachment for an already authenticated trainer', () async {
    final events = <String>[];
    final repository = FirebaseTrainerRegistrationRepository(
      createAttachmentUpload: (type) async {
        events.add('create:${type.value}');
        return const TrainerAttachmentUpload(
          path: '/experiencia_1.pdf',
          url: 'https://storage.test/experiencia',
          headers: {'Content-Type': 'application/pdf'},
        );
      },
      uploadFile: (upload, bytes) async {
        events.add('upload:${upload.path}:${bytes.single}');
      },
      confirmAttachment: (type, path) async {
        events.add('confirm:${type.value}:$path');
      },
    );

    await repository.uploadTrainerAttachment(
      TrainerAttachmentType.experience,
      _document('experiencia.pdf', 7),
    );

    expect(events, [
      'create:experiencias',
      'upload:/experiencia_1.pdf:7',
      'confirm:experiencias:/experiencia_1.pdf',
    ]);
  });

  test(
    'marks attachment failures as occurring after account creation',
    () async {
      var didSignOut = false;
      final repository = FirebaseTrainerRegistrationRepository(
        registerTrainer: (data) async {},
        authenticate: (email, password) async {},
        createAttachmentUpload: (type) async {
          throw const RegistrationFailure.connection();
        },
        signOut: () async => didSignOut = true,
      );

      await expectLater(
        repository.createAccount(
          registration: _registrationWithDocuments(),
          password: 'Senha@123',
        ),
        throwsA(
          isA<RegistrationFailure>()
              .having((error) => error.accountCreated, 'accountCreated', isTrue)
              .having(
                (error) => error.message,
                'message',
                contains('conta foi criada'),
              ),
        ),
      );
      expect(didSignOut, isTrue);
    },
  );
}

TrainerRegistrationDraft _registrationWithDocuments() {
  return TrainerRegistrationDraft(
    firstName: ' Ana ',
    lastName: ' Silva ',
    email: ' ana@email.com ',
    sport: ' Salto ',
    trainerExperienceDocument: _document('experiencia.pdf', 1),
    trainerCertificationDocuments: [
      _document('certificacao-1.pdf', 2),
      _document('certificacao-2.pdf', 3),
    ],
    serviceAreas: const [
      TrainerServiceArea.countryRegion(countryRegion: 'Sul'),
      TrainerServiceArea.city(
        countryRegion: 'Sudeste',
        stateCode: 'SP',
        stateName: 'São Paulo',
        cityName: 'Campinas',
      ),
    ],
  );
}

TrainerDocument _document(String name, int marker) {
  return TrainerDocument(
    name: name,
    path: '/$name',
    sizeInBytes: 1,
    mimeType: 'application/pdf',
    readBytes: () async => Uint8List.fromList([marker]),
  );
}
