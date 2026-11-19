// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 19/11/2026
// Autor: Davi Alves Froza - RA 25016900
// Alteração: Verificação do microchip pela callable validateMicrochip, que
// consulta o servidor Java.
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos contratos de preparação, envio, confirmação e
// remoção das imagens persistidas do cavalo.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Exposição da remoção de imagem para reutilização na edição.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Contrato das chamadas remotas. Mantém Firebase fora da tela.
// -----------------------------------------------------------------------------

import 'dart:typed_data';

/// Dados que o servidor devolve para enviar uma imagem ao Storage.
class HorseImageUploadTicket {
  const HorseImageUploadTicket({
    required this.path,
    required this.url,
    required this.headers,
  });

  final String path;
  final Uri url;
  final Map<String, String> headers;
}

/// Falha devolvida pelo Storage durante o PUT da imagem.
class HorseImageStorageException implements Exception {
  const HorseImageStorageException({required this.statusCode, this.details});

  final int statusCode;
  final String? details;

  @override
  String toString() => 'HorseImageStorageException($statusCode)';
}

/// Somente esta camada conhece os nomes e formatos das APIs externas.
abstract class HorseRegistrationRemoteService {
  Future<List<Map<String, dynamic>>> getModalities();

  Future<Map<String, dynamic>> registerHorse(Map<String, Object?> payload);

  /// Confere o microchip no servidor. Lança `HorseMicrochipValidationFailure`
  /// quando o código é recusado; qualquer outro erro segue como está.
  Future<void> validateMicrochip(String code);

  Future<HorseImageUploadTicket> prepareImage(
    String horseId,
    String contentType,
  );

  Future<void> sendImage(HorseImageUploadTicket ticket, Uint8List bytes);

  Future<void> confirmImage(String horseId, String path);

  Future<void> removeImage(String horseId, String path);
}
