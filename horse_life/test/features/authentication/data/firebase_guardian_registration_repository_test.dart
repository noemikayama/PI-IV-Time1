// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do contrato enviado ao cadastro de responsável.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/authentication/application/states/registration_draft.dart';
import 'package:horse_life/features/authentication/data/repositories/firebase_guardian_registration_repository.dart';
import 'package:horse_life/features/authentication/data/repositories/registration_repository.dart';

void main() {
  test('maps the guardian draft to the registerGuardian contract', () async {
    Map<String, Object>? receivedData;
    final repository = FirebaseGuardianRegistrationRepository(
      registerGuardian: (data) async => receivedData = data,
    );

    await repository.createAccount(
      registration: const GuardianRegistrationDraft(
        firstName: ' Ana ',
        lastName: ' Silva ',
        email: ' ana@email.com ',
      ),
      password: 'Senha@123',
    );

    expect(receivedData, {
      'nome': 'Ana Silva',
      'email': 'ana@email.com',
      'senha': 'Senha@123',
    });
  });

  test('does not send a trainer draft to the guardian endpoint', () async {
    var wasCalled = false;
    final repository = FirebaseGuardianRegistrationRepository(
      registerGuardian: (data) async => wasCalled = true,
    );

    await expectLater(
      repository.createAccount(
        registration: const TrainerRegistrationDraft(
          firstName: 'Bruno',
          lastName: 'Lima',
          email: 'bruno@email.com',
        ),
        password: 'Senha@123',
      ),
      throwsA(isA<RegistrationFailure>()),
    );
    expect(wasCalled, isFalse);
  });
}
