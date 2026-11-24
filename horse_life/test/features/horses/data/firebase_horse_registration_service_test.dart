// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Davi Alves Froza - RA 25016900
// Alteração: Cenários da callable validateMicrochip: payload enviado, recusa
// do microchip e falha do servidor.
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação e documentação dos cenários de timeout, autenticação e
// transferência de imagens do serviço remoto de cavalos.
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/horses/data/repositories/horse_microchip_validator.dart';
import 'package:horse_life/features/horses/data/services/firebase_horse_registration_service.dart';
import 'package:horse_life/features/horses/data/services/horse_registration_remote_service.dart';
import 'package:http/http.dart' as http;

void main() {
  test('interrompe callable quando o backend não responde', () {
    final service = FirebaseHorseRegistrationService(
      call: (_, _) => Completer<Object?>().future,
      requestTimeout: const Duration(milliseconds: 20),
    );

    expect(service.getModalities(), throwsA(isA<TimeoutException>()));
  });

  test('createHorseImageUpload recebe id e contentType da foto', () async {
    String? functionName;
    Map<String, Object?>? payload;
    final service = FirebaseHorseRegistrationService(
      call: (name, data) async {
        functionName = name;
        payload = data;
        return {
          'caminho': '/fotos/cavalos/horse-1/imagem_1.jpg',
          'uploadUrl': 'https://storage.example.test/upload',
          'headers': {
            'Content-Type': 'image/jpeg',
            'x-goog-content-length-range': '0,5242880',
          },
        };
      },
    );

    final ticket = await service.prepareImage('horse-1', 'image/jpeg');

    expect(functionName, 'createHorseImageUpload');
    expect(payload, {'id': 'horse-1', 'contentType': 'image/jpeg'});
    expect(ticket.path, '/fotos/cavalos/horse-1/imagem_1.jpg');
    expect(ticket.headers['Content-Type'], 'image/jpeg');
  });

  test('renova a sessão e repete createHorseImageUpload uma vez', () async {
    var calls = 0;
    var refreshes = 0;
    final service = FirebaseHorseRegistrationService(
      call: (name, data) async {
        calls++;
        if (calls == 1) {
          throw FirebaseFunctionsException(
            code: 'unauthenticated',
            message: 'Faça login para continuar.',
          );
        }
        return {
          'caminho': 'fotos/cavalos/horse-1/imagem_1.jpg',
          'uploadUrl': 'https://storage.example.test/upload',
          'headers': {'Content-Type': 'image/jpeg'},
        };
      },
      refreshAuthToken: () async => refreshes++,
    );

    final ticket = await service.prepareImage('horse-1', 'image/jpeg');

    expect(ticket.path, 'fotos/cavalos/horse-1/imagem_1.jpg');
    expect(refreshes, 1);
    expect(calls, 2);
  });

  test('envia os bytes com todos os headers assinados pelo backend', () async {
    Uri? sentUrl;
    Map<String, String>? sentHeaders;
    Object? sentBody;
    final service = FirebaseHorseRegistrationService(
      call: (_, _) async => const {},
      put: (url, {headers, body}) async {
        sentUrl = url;
        sentHeaders = headers;
        sentBody = body;
        return http.Response('', 200);
      },
    );
    final bytes = Uint8List.fromList([0xFF, 0xD8, 0xFF]);
    final ticket = HorseImageUploadTicket(
      path: 'fotos/cavalos/horse-1/imagem_1.jpg',
      url: Uri.parse('https://storage.example.test/upload'),
      headers: const {
        'Content-Type': 'image/jpeg',
        'x-goog-content-length-range': '0,5242880',
      },
    );

    await service.sendImage(ticket, bytes);

    expect(sentUrl, ticket.url);
    expect(sentHeaders, ticket.headers);
    expect(sentBody, same(bytes));
  });

  test('preserva o status e a resposta quando o Storage recusa o PUT', () {
    final service = FirebaseHorseRegistrationService(
      call: (_, _) async => const {},
      put: (_, {headers, body}) async =>
          http.Response('<Code>SignatureDoesNotMatch</Code>', 403),
    );
    final ticket = HorseImageUploadTicket(
      path: 'fotos/cavalos/horse-1/imagem_1.jpg',
      url: Uri.parse('https://storage.example.test/upload'),
      headers: const {'Content-Type': 'image/jpeg'},
    );

    expect(
      service.sendImage(ticket, Uint8List.fromList([0xFF, 0xD8])),
      throwsA(
        isA<HorseImageStorageException>()
            .having((error) => error.statusCode, 'statusCode', 403)
            .having(
              (error) => error.details,
              'details',
              contains('SignatureDoesNotMatch'),
            ),
      ),
    );
  });

  test('validateMicrochip envia o código à callable validateMicrochip', () async {
    String? functionName;
    Map<String, Object?>? payload;
    final service = FirebaseHorseRegistrationService(
      call: (name, data) async {
        functionName = name;
        payload = data;
        return {'valido': true};
      },
    );

    await service.validateMicrochip('076987654321017');

    expect(functionName, 'validateMicrochip');
    expect(payload, {'codigo': '076987654321017'});
  });

  test('microchip recusado pelo servidor vira falha com a mensagem dele', () {
    final service = FirebaseHorseRegistrationService(
      call: (_, _) async => throw FirebaseFunctionsException(
        code: 'invalid-argument',
        message: 'Os dígitos verificadores não conferem.',
      ),
    );

    expect(
      service.validateMicrochip('076987654321018'),
      throwsA(
        isA<HorseMicrochipValidationFailure>().having(
          (failure) => failure.message,
          'message',
          'Os dígitos verificadores não conferem.',
        ),
      ),
    );
  });

  test('servidor indisponível não vira microchip inválido', () {
    final service = FirebaseHorseRegistrationService(
      call: (_, _) async => throw FirebaseFunctionsException(
        code: 'unavailable',
        message: 'Não foi possível verificar o microchip agora. Tente novamente.',
      ),
    );

    expect(
      service.validateMicrochip('076987654321017'),
      throwsA(
        isA<FirebaseFunctionsException>().having(
          (error) => error.code,
          'code',
          'unavailable',
        ),
      ),
    );
  });
}
