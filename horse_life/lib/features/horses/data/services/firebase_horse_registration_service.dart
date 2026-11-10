// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Adaptador real das Cloud Functions de cavalos e das imagens.
// -----------------------------------------------------------------------------

import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

import 'horse_registration_remote_service.dart';

/// Usa os endpoints já existentes nas Functions fornecidas pelo time.
/// Se o backend mudar, este será o principal arquivo a adaptar.
class FirebaseHorseRegistrationService
    implements HorseRegistrationRemoteService {
  FirebaseHorseRegistrationService({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final FirebaseFunctions _functions;

  Future<dynamic> _call(String name, [Map<String, Object?>? data]) async {
    final response = await _functions
        .httpsCallable(name)
        .call<dynamic>(data ?? <String, Object?>{});
    return response.data;
  }

  Map<String, dynamic> _object(dynamic value) {
    if (value is! Map)
      throw const FormatException('Resposta inválida do servidor.');
    return Map<String, dynamic>.from(value);
  }

  @override
  Future<List<Map<String, dynamic>>> getModalities() async {
    final data = await _call('getModalities');
    if (data is! List)
      throw const FormatException('Lista de modalidades inválida.');
    return data.map((item) => _object(item)).toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> registerHorse(
    Map<String, Object?> payload,
  ) async => _object(await _call('registerHorse', payload));

  @override
  Future<HorseImageUploadTicket> prepareImage(
    String horseId,
    String contentType,
  ) async {
    final data = _object(
      await _call('createHorseImageUpload', {
        'id': horseId,
        'contentType': contentType,
      }),
    );
    final path = data['caminho'];
    final url = data['uploadUrl'];
    final headers = data['headers'];
    if (path is! String || url is! String || headers is! Map) {
      throw const FormatException('Credenciais de envio de imagem inválidas.');
    }
    return HorseImageUploadTicket(
      path: path,
      url: Uri.parse(url),
      headers: headers.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
  }

  @override
  Future<void> sendImage(HorseImageUploadTicket ticket, Uint8List bytes) async {
    // Faz o PUT diretamente na URL temporária assinada pelo backend.
    final response = await http.put(
      ticket.url,
      headers: ticket.headers,
      body: bytes,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const FormatException(
        'Não foi possível enviar a imagem ao Storage.',
      );
    }
  }

  @override
  Future<void> confirmImage(String horseId, String path) async {
    await _call('confirmHorseImage', {'id': horseId, 'caminho': path});
  }
}
