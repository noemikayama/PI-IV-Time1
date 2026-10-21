// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração do cadastro de responsável com a callable
// registerGuardian, hospedada na região southamerica-east1.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';

import '../../application/states/registration_draft.dart';
import 'registration_repository.dart';

typedef GuardianRegistrationCall =
    Future<void> Function(Map<String, Object> data);

// Implementa somente o cadastro de responsável. A chamada é resolvida de forma
// tardia para que o Firebase já esteja inicializado pelo AppGate.
final class FirebaseGuardianRegistrationRepository
    implements RegistrationRepository {
  const FirebaseGuardianRegistrationRepository({
    GuardianRegistrationCall? registerGuardian,
  }) : _registerGuardian = registerGuardian;

  static const _region = 'southamerica-east1';
  static const _functionName = 'registerGuardian';

  final GuardianRegistrationCall? _registerGuardian;

  @override
  Future<void> createAccount({
    required RegistrationDraft registration,
    required String password,
  }) async {
    if (registration is! GuardianRegistrationDraft) {
      throw const RegistrationFailure(
        'Este repositório aceita apenas cadastros de responsável.',
      );
    }

    final data = <String, Object>{
      'nome':
          '${registration.firstName.trim()} '
          '${registration.lastName.trim()}',
      'email': registration.email.trim(),
      'senha': password,
    };

    try {
      final registerGuardian = _registerGuardian;
      if (registerGuardian != null) {
        await registerGuardian(data);
        return;
      }

      await FirebaseFunctions.instanceFor(
        region: _region,
      ).httpsCallable(_functionName).call<void>(data);
    } on FirebaseFunctionsException catch (error) {
      throw switch (error.code) {
        'already-exists' => const RegistrationFailure('E-mail já cadastrado.'),
        'invalid-argument' => RegistrationFailure(
          error.message ?? 'Dados de cadastro inválidos.',
        ),
        _ => const RegistrationFailure.connection(),
      };
    }
  }
}
