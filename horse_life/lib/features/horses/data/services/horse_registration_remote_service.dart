// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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

/// Somente esta camada conhece os nomes e formatos das APIs externas.
abstract class HorseRegistrationRemoteService {
  Future<List<Map<String, dynamic>>> getModalities();

  Future<Map<String, dynamic>> registerHorse(Map<String, Object?> payload);

  Future<HorseImageUploadTicket> prepareImage(String horseId, String contentType);

  Future<void> sendImage(HorseImageUploadTicket ticket, Uint8List bytes);

  Future<void> confirmImage(String horseId, String path);
}
