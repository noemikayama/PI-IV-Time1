// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos metadados compartilhados pelos documentos de
// experiência e certificação profissional do treinador.
// -----------------------------------------------------------------------------

// Representa os metadados necessários para revisar e enviar um documento.
// O conteúdo do PDF permanece no arquivo apontado por [path].
class TrainerDocument {
  const TrainerDocument({
    required this.name,
    required this.path,
    required this.sizeInBytes,
    this.mimeType,
  });

  // Identificação e localização do arquivo selecionado pelo usuário.
  final String name;
  final String path;
  // Metadados preservados para validação e para a futura integração de upload.
  final int sizeInBytes;
  final String? mimeType;
}
