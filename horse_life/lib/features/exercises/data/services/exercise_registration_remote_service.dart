// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do contrato das chamadas remotas de exercícios e do ticket
// de upload assinado para o Storage, desacoplando o Firebase dos repositórios.
// -----------------------------------------------------------------------------

import 'dart:typed_data';

/// Dados devolvidos pelo servidor com a URL assinada e cabeçalhos obrigatórios
/// para transferência binária direta de foto ou vídeo ao Cloud Storage.
class ExerciseMediaUploadTicket {
  const ExerciseMediaUploadTicket({
    required this.path,
    required this.url,
    required this.headers,
  });

  final String path;
  final Uri url;
  final Map<String, String> headers;
}

/// Contrato isolado de rede e Cloud Functions para exercícios e mídias.
abstract class ExerciseRegistrationRemoteService {
  /// Executa a callable registerExercise e retorna os dados de identificação gerados.
  Future<Map<String, dynamic>> registerExercise(Map<String, Object?> payload);

  /// Solicita uma URL assinada para upload de imagem ou vídeo no Storage.
  Future<ExerciseMediaUploadTicket> prepareMediaUpload({
    required String exerciseId,
    required String contentType,
  });

  /// Realiza o upload binário direto na URL assinada via HTTP PUT.
  Future<void> sendMediaBytes({
    required ExerciseMediaUploadTicket ticket,
    required Uint8List bytes,
  });

  /// Confirma a gravação da mídia após o término do envio ao Storage.
  Future<Map<String, dynamic>> confirmMedia({
    required String exerciseId,
    required String path,
  });

  /// Remove uma mídia vinculada ao exercício e apaga o arquivo do Storage.
  Future<Map<String, dynamic>> removeMedia({
    required String exerciseId,
    required String path,
  });
}
