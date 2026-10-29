import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/authentication/application/controllers/password_reset_controller.dart';
import 'package:horse_life/features/authentication/data/repositories/password_reset_repository.dart';

final class _RecordingPasswordResetRepository
    implements PasswordResetRepository {
  _RecordingPasswordResetRepository.success()
    : result = 'Mensagem segura',
      error = null;

  _RecordingPasswordResetRepository.failure(this.error) : result = '';

  final String result;
  final Object? error;
  String? receivedEmail;

  @override
  Future<String> requestPasswordReset({required String email}) {
    receivedEmail = email;
    final error = this.error;
    return error == null ? Future.value(result) : Future.error(error);
  }
}

void main() {
  test('forwards the email and returns the repository result', () async {
    final repository = _RecordingPasswordResetRepository.success();
    final controller = PasswordResetController(repository);

    final result = await controller.requestPasswordReset('User@Email.com');

    expect(repository.receivedEmail, 'User@Email.com');
    expect(result, 'Mensagem segura');
  });

  test('propagates a repository failure', () async {
    const failure = PasswordResetFailure.connection();
    final controller = PasswordResetController(
      _RecordingPasswordResetRepository.failure(failure),
    );

    await expectLater(
      controller.requestPasswordReset('usuario@email.com'),
      throwsA(same(failure)),
    );
  });
}
