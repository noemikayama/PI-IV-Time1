import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/authentication/data/repositories/firebase_password_reset_repository.dart';
import 'package:horse_life/features/authentication/data/repositories/password_reset_repository.dart';

final class _RecordingRemoteDataSource
    implements PasswordResetRemoteDataSource {
  Map<String, String>? input;

  @override
  Future<Object?> requestPasswordReset(Map<String, String> input) async {
    this.input = input;
    return {'mensagem': ' Instruções enviadas. '};
  }
}

final class _StubRemoteDataSource implements PasswordResetRemoteDataSource {
  const _StubRemoteDataSource.response(this.response) : error = null;

  const _StubRemoteDataSource.error(this.error) : response = null;

  final Object? response;
  final Object? error;

  @override
  Future<Object?> requestPasswordReset(Map<String, String> input) {
    final error = this.error;
    return error == null ? Future.value(response) : Future.error(error);
  }
}

final class _TestFirebaseFunctionsException extends FirebaseFunctionsException {
  _TestFirebaseFunctionsException({
    required super.code,
    required super.message,
  });
}

void main() {
  test('normalizes the email and returns the backend message', () async {
    final remote = _RecordingRemoteDataSource();
    final repository = FirebasePasswordResetRepository(remote: remote);

    final message = await repository.requestPasswordReset(
      email: ' Usuario@Email.COM ',
    );

    expect(remote.input, {'email': 'usuario@email.com'});
    expect(message, 'Instruções enviadas.');
  });

  for (final invalidResponse in <Object?>[
    null,
    'not-a-map',
    <String, Object?>{},
    <String, Object?>{'mensagem': 42},
    <String, Object?>{'mensagem': '   '},
  ]) {
    test('rejects the invalid backend response $invalidResponse', () async {
      final repository = FirebasePasswordResetRepository(
        remote: _StubRemoteDataSource.response(invalidResponse),
      );

      await expectLater(
        repository.requestPasswordReset(email: 'usuario@email.com'),
        throwsA(
          isA<PasswordResetFailure>().having(
            (error) => error.message,
            'message',
            'Resposta de recuperação de senha inválida.',
          ),
        ),
      );
    });
  }

  test('preserves an invalid-argument message from Firebase', () async {
    final repository = FirebasePasswordResetRepository(
      remote: _StubRemoteDataSource.error(
        _TestFirebaseFunctionsException(
          code: 'invalid-argument',
          message: 'E-mail recusado.',
        ),
      ),
    );

    await expectLater(
      repository.requestPasswordReset(email: 'usuario@email.com'),
      throwsA(
        isA<PasswordResetFailure>().having(
          (error) => error.message,
          'message',
          'E-mail recusado.',
        ),
      ),
    );
  });

  test(
    'uses the safe fallback when Firebase omits the error message',
    () async {
      final repository = FirebasePasswordResetRepository(
        remote: _StubRemoteDataSource.error(
          _TestFirebaseFunctionsException(
            code: 'invalid-argument',
            message: '',
          ),
        ),
      );

      await expectLater(
        repository.requestPasswordReset(email: 'usuario@email.com'),
        throwsA(
          isA<PasswordResetFailure>().having(
            (error) => error.message,
            'message',
            'E-mail inválido.',
          ),
        ),
      );
    },
  );

  test('maps other Firebase errors to a connection failure', () async {
    final repository = FirebasePasswordResetRepository(
      remote: _StubRemoteDataSource.error(
        _TestFirebaseFunctionsException(code: 'internal', message: 'details'),
      ),
    );

    await expectLater(
      repository.requestPasswordReset(email: 'usuario@email.com'),
      throwsA(
        isA<PasswordResetFailure>().having(
          (error) => error.message,
          'message',
          'Erro de conexão com o servidor',
        ),
      ),
    );
  });

  test('maps unexpected errors to a connection failure', () async {
    final repository = FirebasePasswordResetRepository(
      remote: _StubRemoteDataSource.error(StateError('unexpected')),
    );

    await expectLater(
      repository.requestPasswordReset(email: 'usuario@email.com'),
      throwsA(
        isA<PasswordResetFailure>().having(
          (error) => error.message,
          'message',
          'Erro de conexão com o servidor',
        ),
      ),
    );
  });
}
