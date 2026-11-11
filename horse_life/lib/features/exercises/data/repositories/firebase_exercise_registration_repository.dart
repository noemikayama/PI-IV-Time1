// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do adapter Firebase para submissão do cadastro de
// exercícios via Cloud Function na região southamerica-east1.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';

import '../../application/states/exercise_registration_draft.dart';
import 'exercise_registration_repository.dart';

// Seam da callable para permitir testes de serialização e tratamento de erros.
typedef ExerciseRegistrationCall =
    Future<void> Function(Map<String, Object?> data);

// Implementa o envio do exercício ao backend mantendo a resolução tardia do SDK.
final class FirebaseExerciseRegistrationRepository
    implements ExerciseRegistrationRepository {
  const FirebaseExerciseRegistrationRepository({
    ExerciseRegistrationCall? registerExercise,
  }) : _registerExercise = registerExercise;

  static const _region = 'southamerica-east1';
  static const _functionName = 'registerExercise';

  final ExerciseRegistrationCall? _registerExercise;

  @override
  Future<void> registerExercise({
    required ExerciseRegistrationDraft draft,
  }) async {
    final data = <String, Object?>{
      'nome': draft.name.trim(),
      'descricao': draft.description.trim(),
      'tipo': draft.exerciseType.name,
      'orientacoes': draft.guidelines
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      if (draft.defaultDurationMinutes != null)
        'duracaoPadraoMinutos': draft.defaultDurationMinutes,
      'materiais': draft.materials
          .map((material) => material.toJson())
          .toList(growable: false),
      if (draft is SpecificExerciseRegistrationDraft) 'cavaloId': draft.horse.id,
    };

    try {
      final registerExercise = _registerExercise;
      if (registerExercise != null) {
        await registerExercise(data);
        return;
      }

      await FirebaseFunctions.instanceFor(
        region: _region,
      ).httpsCallable(_functionName).call<void>(data);
    } on FirebaseFunctionsException catch (error) {
      throw switch (error.code) {
        'invalid-argument' => ExerciseRegistrationFailure(
          error.message ?? 'Dados do exercício inválidos.',
        ),
        _ => const ExerciseRegistrationFailure.connection(),
      };
    }
  }
}
