// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da implementação Firebase do serviço de exercícios,
// conectando com as Cloud Functions da região southamerica-east1 e upload
// assinado direto ao Cloud Storage.
// -----------------------------------------------------------------------------

import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

import 'exercise_registration_remote_service.dart';

/// Comunica-se com as Cloud Functions de exercícios na região southamerica-east1.
class FirebaseExerciseRegistrationService
    implements ExerciseRegistrationRemoteService {
  FirebaseExerciseRegistrationService({
    FirebaseFunctions? functions,
    http.Client? httpClient,
  }) : _functions =
            functions ??
            FirebaseFunctions.instanceFor(region: _defaultRegion),
       _httpClient = httpClient;

  static const _defaultRegion = 'southamerica-east1';

  final FirebaseFunctions _functions;
  final http.Client? _httpClient;

  Future<dynamic> _call(String name, [Map<String, Object?>? data]) async {
    final response = await _functions
        .httpsCallable(name)
        .call<dynamic>(data ?? <String, Object?>{});
    return response.data;
  }

  Map<String, dynamic> _object(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Resposta inválida do servidor.');
    }
    return Map<String, dynamic>.from(value);
  }

  @override
  Future<Map<String, dynamic>> registerExercise(
    Map<String, Object?> payload,
  ) async {
    final result = await _call('registerExercise', payload);
    return _object(result);
  }

  @override
  Future<ExerciseMediaUploadTicket> prepareMediaUpload({
    required String exerciseId,
    required String contentType,
  }) async {
    final data = _object(
      await _call('createExerciseMediaUpload', {
        'id': exerciseId,
        'contentType': contentType,
      }),
    );

    final path = data['caminho'];
    final url = data['uploadUrl'];
    final headers = data['headers'];

    if (path is! String || url is! String || headers is! Map) {
      throw const FormatException('Credenciais de envio de mídia inválidas.');
    }

    return ExerciseMediaUploadTicket(
      path: path,
      url: Uri.parse(url),
      headers: headers.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
  }

  @override
  Future<void> sendMediaBytes({
    required ExerciseMediaUploadTicket ticket,
    required Uint8List bytes,
  }) async {
    final client = _httpClient ?? http.Client();
    final shouldCloseClient = _httpClient == null;

    try {
      final response = await client.put(
        ticket.url,
        headers: ticket.headers,
        body: bytes,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FormatException(
          'Não foi possível enviar a mídia ao Storage (HTTP ${response.statusCode}).',
        );
      }
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  @override
  Future<Map<String, dynamic>> confirmMedia({
    required String exerciseId,
    required String path,
  }) async {
    final result = await _call('confirmExerciseMedia', {
      'id': exerciseId,
      'caminho': path,
    });
    return _object(result);
  }

  @override
  Future<Map<String, dynamic>> removeMedia({
    required String exerciseId,
    required String path,
  }) async {
    final result = await _call('removeExerciseMedia', {
      'id': exerciseId,
      'caminho': path,
    });
    return _object(result);
  }
}
