// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração da recuperação de senha com a callable Firebase,
// normalização do e-mail, validação da resposta e tradução segura de falhas,
// isolando a callable em uma porta remota tipada.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';

import 'password_reset_repository.dart';

// Boundary estreita para a chamada externa, sem expor o SDK ao domínio.
abstract interface class PasswordResetRemoteDataSource {
  Future<Object?> requestPasswordReset(Map<String, String> input);
}

// Implementação de produção da boundary usando a callable do Firebase.
final class FirebasePasswordResetRemoteDataSource
    implements PasswordResetRemoteDataSource {
  const FirebasePasswordResetRemoteDataSource();

  static const _region = 'southamerica-east1';
  static const _functionName = 'requestPasswordReset';

  @override
  Future<Object?> requestPasswordReset(Map<String, String> input) async {
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_functionName).call<Object?>(input);
    return result.data;
  }
}

// Adapter remoto responsável pelos detalhes da callable requestPasswordReset.
final class FirebasePasswordResetRepository implements PasswordResetRepository {
  const FirebasePasswordResetRepository({
    PasswordResetRemoteDataSource remote =
        const FirebasePasswordResetRemoteDataSource(),
  }) : _remote = remote;

  final PasswordResetRemoteDataSource _remote;

  // Normaliza a entrada e exige o contrato { mensagem: String } do backend.
  @override
  Future<String> requestPasswordReset({required String email}) async {
    try {
      final response = await _remote.requestPasswordReset({
        'email': email.trim().toLowerCase(),
      });
      final data = _asMap(response);
      final message = data['mensagem'];
      if (message is! String || message.trim().isEmpty) {
        throw const PasswordResetFailure(
          'Resposta de recuperação de senha inválida.',
        );
      }
      return message.trim();
    } on PasswordResetFailure {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'invalid-argument') {
        final message = error.message?.trim();
        throw PasswordResetFailure(
          message == null || message.isEmpty
              ? const PasswordResetFailure.invalidEmail().message
              : message,
        );
      }
      throw const PasswordResetFailure.connection();
    } catch (_) {
      throw const PasswordResetFailure.connection();
    }
  }

  // Impede que respostas inesperadas sejam tratadas como confirmações válidas.
  Map<Object?, Object?> _asMap(Object? value) {
    if (value is Map<Object?, Object?>) return value;
    throw const PasswordResetFailure(
      'Resposta de recuperação de senha inválida.',
    );
  }
}
