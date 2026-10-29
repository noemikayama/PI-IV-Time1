// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos e segmentos do código de autenticação,
// detalhando responsabilidades, fluxo de dados e integração entre camadas.
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão da leitura multiplataforma do PDF e dos limites
// compartilhados com o backend.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos metadados compartilhados pelos documentos de
// experiência e certificação profissional do treinador.
// -----------------------------------------------------------------------------

import 'dart:typed_data';

// Leitura adiada: o PDF só é carregado em memória no momento do upload.
typedef TrainerDocumentReader = Future<Uint8List> Function();

// Regras compartilhadas pelas telas e pelo adapter de cadastro profissional.
abstract final class TrainerDocumentLimits {
  static const maximumSizeInBytes = 10 * 1024 * 1024;
  static const maximumCertifications = 10;

  // Rejeita arquivos vazios e aplica o mesmo teto de 10 MB do backend.
  static bool acceptsSize(int sizeInBytes) {
    return sizeInBytes > 0 && sizeInBytes <= maximumSizeInBytes;
  }
}

// Representa os metadados necessários para revisar e enviar um documento.
// O conteúdo do PDF permanece no arquivo apontado por [path].
class TrainerDocument {
  const TrainerDocument({
    required this.name,
    required this.path,
    required this.sizeInBytes,
    this.mimeType,
    TrainerDocumentReader? readBytes,
  }) : _readBytes = readBytes;

  // Identificação e localização do arquivo selecionado pelo usuário.
  final String name;
  final String path;
  // Metadados preservados para validação e para a futura integração de upload.
  final int sizeInBytes;
  final String? mimeType;
  final TrainerDocumentReader? _readBytes;

  // Materializa o conteúdo somente quando o repositório inicia o envio.
  Future<Uint8List> loadBytes() {
    final readBytes = _readBytes;
    if (readBytes == null) {
      throw StateError('O arquivo selecionado não está mais disponível.');
    }
    return readBytes();
  }
}
