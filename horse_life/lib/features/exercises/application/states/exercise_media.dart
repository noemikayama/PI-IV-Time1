// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do estado imutável que representa mídias auxiliares
// (imagens e vídeos) anexadas ao rascunho de cadastro do exercício.
// -----------------------------------------------------------------------------

import 'dart:typed_data';

// Distingue o tipo de arquivo auxiliar para exibição de ícones e upload.
enum ExerciseMediaType {
  image,
  video,
}

// Armazena os metadados da mídia selecionada e adia a leitura dos bytes até o
// momento efetivo da submissão ao Firebase Storage.
final class ExerciseMedia {
  const ExerciseMedia({
    required this.name,
    required this.path,
    required this.type,
    required this.sizeInBytes,
    this.mimeType,
    this.readBytes,
  });

  final String name;
  final String path;
  final ExerciseMediaType type;
  final int sizeInBytes;
  final String? mimeType;
  final Future<Uint8List> Function()? readBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseMedia &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          path == other.path &&
          type == other.type &&
          sizeInBytes == other.sizeInBytes &&
          mimeType == other.mimeType;

  @override
  int get hashCode => Object.hash(name, path, type, sizeInBytes, mimeType);
}
