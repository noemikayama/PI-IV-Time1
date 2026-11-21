// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do payload, da criação da sessão, dos claims e das
// falhas seguras do adapter Firebase de login.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/authentication/application/states/login_session.dart';
import 'package:horse_life/features/authentication/data/repositories/firebase_login_repository.dart';
import 'package:horse_life/features/authentication/data/repositories/login_repository.dart';

void main() {
  test(
    'calls login, authenticates the token and returns a typed session',
    () async {
      Map<String, String>? receivedCredentials;
      String? receivedToken;
      final repository = FirebaseLoginRepository(
        callLogin: (credentials) async {
          receivedCredentials = credentials;
          return {
            'customToken': 'custom-token',
            'role': 'guardian',
            'nome': ' Ana Silva ',
          };
        },
        signInWithCustomToken: (token) async {
          receivedToken = token;
          return const AuthenticatedIdentity(
            uid: 'guardian-uid',
            roleClaim: 'guardian',
          );
        },
      );

      final session = await repository.authenticate(
        email: ' ANA@EMAIL.COM ',
        password: 'Senha@123',
      );

      expect(receivedCredentials, {
        'email': 'ana@email.com',
        'senha': 'Senha@123',
      });
      expect(receivedToken, 'custom-token');
      expect(session.uid, 'guardian-uid');
      expect(session.name, 'Ana Silva');
      expect(session.role, AuthenticationRole.guardian);
    },
  );

  test('rejects a role that differs from the authenticated claim', () async {
    var didSignOut = false;
    final repository = FirebaseLoginRepository(
      callLogin: (credentials) async => {
        'customToken': 'custom-token',
        'role': 'guardian',
        'nome': 'Ana Silva',
      },
      signInWithCustomToken: (token) async => const AuthenticatedIdentity(
        uid: 'guardian-uid',
        roleClaim: 'trainer',
      ),
      signOut: () async => didSignOut = true,
    );

    await expectLater(
      repository.authenticate(email: 'ana@email.com', password: 'Senha@123'),
      throwsA(
        isA<LoginFailure>().having(
          (error) => error.message,
          'message',
          contains('permissões'),
        ),
      ),
    );
    expect(didSignOut, isTrue);
  });

  test('rejects an unsupported admin role before authentication', () async {
    var authenticationCalls = 0;
    final repository = FirebaseLoginRepository(
      callLogin: (credentials) async => {
        'customToken': 'token',
        'role': 'admin',
        'nome': 'Administrador',
      },
      signInWithCustomToken: (token) async {
        authenticationCalls++;
        return const AuthenticatedIdentity(uid: 'uid', roleClaim: 'guardian');
      },
    );

    await expectLater(
      repository.authenticate(email: 'ana@email.com', password: 'Senha@123'),
      throwsA(isA<LoginFailure>()),
    );
    expect(authenticationCalls, 0);
  });

  test('preserves a typed failure returned by the login operation', () async {
    final repository = FirebaseLoginRepository(
      callLogin: (credentials) async =>
          throw const LoginFailure.invalidCredentials(),
    );

    await expectLater(
      repository.authenticate(email: 'ana@email.com', password: 'incorreta'),
      throwsA(
        isA<LoginFailure>().having(
          (error) => error.message,
          'message',
          'E-mail ou senha incorretos',
        ),
      ),
    );
  });
}
