// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 19/11/2026
// Autor: Davi Alves Froza - RA 25016900
// Alteração: Chamada da callable validateMicrochip; só a recusa do microchip
// vira HorseMicrochipValidationFailure.
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de callable, autenticação e upload;
// inclusão de timeout nas chamadas, renovação do token e envio ao Storage.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Reutilização do adaptador de imagens no perfil editável.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Adaptador real das Cloud Functions de cavalos e das imagens.
// -----------------------------------------------------------------------------

import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

import '../repositories/horse_microchip_validator.dart';
import 'horse_registration_remote_service.dart';

// --- Dependências substituíveis para testes ---------------------------------

typedef HorseFunctionCall =
    Future<Object?> Function(String name, Map<String, Object?> data);
typedef HorseImagePut =
    Future<http.Response> Function(
      Uri url, {
      Map<String, String>? headers,
      Object? body,
    });
typedef HorseAuthTokenRefresh = Future<void> Function();

/// Usa os endpoints já existentes nas Functions fornecidas pelo time.
/// Se o backend mudar, este será o principal arquivo a adaptar.
class FirebaseHorseRegistrationService
    implements HorseRegistrationRemoteService {
  FirebaseHorseRegistrationService({
    FirebaseFunctions? functions,
    HorseFunctionCall? call,
    HorseImagePut? put,
    HorseAuthTokenRefresh? refreshAuthToken,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _callOverride = call,
       _putOverride = put,
       _refreshAuthTokenOverride = refreshAuthToken,
       _functions =
           functions ??
           (call == null
               ? FirebaseFunctions.instanceFor(region: 'southamerica-east1')
               : null);

  final FirebaseFunctions? _functions;
  final HorseFunctionCall? _callOverride;
  final HorseImagePut? _putOverride;
  final HorseAuthTokenRefresh? _refreshAuthTokenOverride;
  final Duration requestTimeout;

  // --- Execução autenticada das callables -----------------------------------
  // Toda chamada possui timeout. Uma resposta `unauthenticated` força a
  // renovação do token e permite exatamente uma nova tentativa.

  Future<dynamic> _call(String name, [Map<String, Object?>? data]) async {
    final payload = data ?? <String, Object?>{};
    try {
      return await _callOnce(name, payload).timeout(requestTimeout);
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'unauthenticated') rethrow;

      final refresh = _refreshAuthTokenOverride;
      if (refresh != null) {
        await refresh().timeout(requestTimeout);
      } else {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) rethrow;
        await user.getIdToken(true).timeout(requestTimeout);
      }

      // Uma única repetição evita loops quando o backend realmente rejeita
      // a sessão ou quando a conta deixou de ter acesso.
      return _callOnce(name, payload).timeout(requestTimeout);
    }
  }

  Future<dynamic> _callOnce(String name, Map<String, Object?> payload) async {
    final override = _callOverride;
    if (override != null) return override(name, payload);
    final response = await _functions!
        .httpsCallable(name)
        .call<dynamic>(payload);
    return response.data;
  }

  Map<String, dynamic> _object(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Resposta inválida do servidor.');
    }
    return Map<String, dynamic>.from(value);
  }

  // --- Catálogo e cadastro --------------------------------------------------

  @override
  Future<List<Map<String, dynamic>>> getModalities() async {
    final data = await _call('getModalities');
    if (data is! List) {
      throw const FormatException('Lista de modalidades inválida.');
    }
    return data.map((item) => _object(item)).toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> registerHorse(
    Map<String, Object?> payload,
  ) async => _object(await _call('registerHorse', payload));

  // --- Verificação do microchip ---------------------------------------------
  // Só a recusa do código (invalid-argument) vira falha de validação, com a
  // mensagem do servidor. Servidor Java fora do ar ('unavailable') ou rede
  // seguem como erro, para a tela não chamar de inválido um código que não
  // pôde ser conferido.

  @override
  Future<void> validateMicrochip(String code) async {
    try {
      await _call('validateMicrochip', {'codigo': code});
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'invalid-argument') rethrow;
      throw HorseMicrochipValidationFailure(
        error.message ?? 'Microchip inválido.',
      );
    }
  }

  // --- Preparação, envio e confirmação das imagens --------------------------
  // O backend emite uma URL temporária; o serviço faz o PUT diretamente no
  // Storage e depois confirma ou remove o caminho pelas callables existentes.

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
    final response = await (_putOverride ?? http.put)(
      ticket.url,
      headers: ticket.headers,
      body: bytes,
    ).timeout(requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = response.body.trim();
      throw HorseImageStorageException(
        statusCode: response.statusCode,
        details: body.isEmpty
            ? response.reasonPhrase
            : body.substring(0, body.length.clamp(0, 500)),
      );
    }
  }

  @override
  Future<void> confirmImage(String horseId, String path) async {
    await _call('confirmHorseImage', {'id': horseId, 'caminho': path});
  }

  @override
  Future<void> removeImage(String horseId, String path) async {
    await _call('removeHorseImage', {'id': horseId, 'caminho': path});
  }
}
