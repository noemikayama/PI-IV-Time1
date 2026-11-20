// RESPONSÁVEL: Davi Alves Froza - RA 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Davi Alves Froza - RA 25016900
// Alteração: Cobertura do validador remoto do microchip: o formato é conferido
// no app e só um código de 15 dígitos é enviado ao servidor.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/horses/data/repositories/horse_microchip_validator.dart';
import 'package:horse_life/features/horses/data/repositories/remote_horse_microchip_validator.dart';

void main() {
  test('código com 14 dígitos é recusado sem consultar o servidor', () async {
    final sent = <String>[];
    final validator = RemoteHorseMicrochipValidator(
      verifyOnServer: (code) async => sent.add(code),
    );

    await expectLater(
      validator.validate('07698765432101'),
      throwsA(isA<HorseMicrochipValidationFailure>()),
    );
    expect(sent, isEmpty);
  });

  test('recusa do servidor chega a quem chamou com a mesma mensagem', () async {
    final validator = RemoteHorseMicrochipValidator(
      verifyOnServer: (_) async => throw const HorseMicrochipValidationFailure(
        'Os dígitos verificadores não conferem.',
      ),
    );

    await expectLater(
      validator.validate('076987654321017'),
      throwsA(
        isA<HorseMicrochipValidationFailure>().having(
          (failure) => failure.message,
          'message',
          'Os dígitos verificadores não conferem.',
        ),
      ),
    );
  });

  test('código aceito pelo servidor é enviado uma vez, sem alteração', () async {
    final sent = <String>[];
    final validator = RemoteHorseMicrochipValidator(
      verifyOnServer: (code) async => sent.add(code),
    );

    await validator.validate('076987654321017');

    expect(sent, ['076987654321017']);
  });
}
