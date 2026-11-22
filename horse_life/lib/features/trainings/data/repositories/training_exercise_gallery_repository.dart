// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Separa implementações de teste do contrato de produção.
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do contrato do repositório da galeria de exercícios do
// treinador e implementação local para testes de apresentação e fluxo.
// -----------------------------------------------------------------------------

import '../models/training_exercise_item.dart';

/// Contrato de obtenção dos exercícios da galeria do treinador para montagem
/// do treinamento, desacoplando as telas da origem de dados (Firebase ou mock).
abstract interface class TrainingExerciseGalleryRepository {
  Future<List<TrainingExerciseItem>> fetchGalleryExercises({
    String? searchQuery,
    String? horseId,
  });
}

/// Erro seguro para apresentação na interface durante consultas à galeria.
final class TrainingGalleryFailure implements Exception {
  const TrainingGalleryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Normaliza textos removendo acentuação comum para filtragem local coerente
/// com a busca realizada pelo backend.
String normalizeSearchText(String value) {
  const diacritics = 'áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ';
  const replacements = 'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
  var result = value;
  for (var index = 0; index < diacritics.length; index++) {
    result = result.replaceAll(diacritics[index], replacements[index]);
  }
  return result.trim().toLowerCase();
}
