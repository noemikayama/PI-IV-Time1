// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Remoção de import redundante do resultado de cadastro e adequação
// da formatação sem alterar o envio ou o tratamento das mídias.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Integração completa com o serviço remoto de exercícios e upload
// sequencial de mídias para o Storage (JPEG/PNG/MP4) após o registro principal,
// retornando ExerciseRegistrationResult com tratamento tipado de falhas.
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Validação de presença obrigatória de ao menos uma orientação no
// payload antes do envio à Cloud Function.
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do adapter Firebase para submissão do cadastro de
// exercícios via Cloud Function na região southamerica-east1.
// -----------------------------------------------------------------------------

import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';

import '../../application/states/exercise_media.dart';
import '../../application/states/exercise_registration_draft.dart';
import '../services/exercise_registration_remote_service.dart';
import '../services/firebase_exercise_registration_service.dart';
import 'exercise_registration_repository.dart';

// Implementa o envio do exercício e mídias ao backend via serviço remoto.
final class FirebaseExerciseRegistrationRepository
    implements ExerciseRegistrationRepository {
  FirebaseExerciseRegistrationRepository({
    ExerciseRegistrationRemoteService? service,
  }) : _service = service ?? FirebaseExerciseRegistrationService();

  final ExerciseRegistrationRemoteService _service;

  @override
  Future<ExerciseRegistrationResult> registerExercise({
    required ExerciseRegistrationDraft draft,
  }) async {
    final cleanGuidelines = draft.guidelines
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    if (cleanGuidelines.isEmpty) {
      throw const ExerciseRegistrationFailure(
        'O exercício deve conter pelo menos uma orientação.',
      );
    }

    final trimmedName = draft.name.trim();
    if (trimmedName.length < 3 || trimmedName.length > 80) {
      throw const ExerciseRegistrationFailure(
        'O nome do exercício deve ter entre 3 e 80 caracteres.',
      );
    }

    final trimmedDescription = draft.description.trim();
    if (trimmedDescription.isEmpty || trimmedDescription.length > 1000) {
      throw const ExerciseRegistrationFailure(
        'A descrição do exercício deve ter entre 1 e 1000 caracteres.',
      );
    }

    final duration = draft.defaultDurationMinutes;
    if (duration == null || duration < 1 || duration > 240) {
      throw const ExerciseRegistrationFailure(
        'A duração padrão deve ser um número inteiro entre 1 e 240 minutos.',
      );
    }

    if (draft is SpecificExerciseRegistrationDraft &&
        draft.horse.id.trim().isEmpty) {
      throw const ExerciseRegistrationFailure(
        'Selecione o cavalo do exercício específico.',
      );
    }

    final Map<String, dynamic> data;
    try {
      data = await _service.registerExercise(draft.toApiPayload());
    } catch (error) {
      throw _toFailure(
        error,
        defaultMessage: 'Não foi possível cadastrar o exercício.',
      );
    }

    final id = data['id'];
    final rawCode = data['codigo'] ?? data['code'];
    final name = data['nome'] ?? data['name'];

    if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
      throw const ExerciseRegistrationFailure(
        'O servidor não confirmou o cadastro do exercício.',
      );
    }

    final code = switch (rawCode) {
      final int value => value,
      final num value => value.toInt(),
      final String value => int.tryParse(value) ?? 0,
      _ => 0,
    };

    var failedMediaCount = 0;
    for (final media in draft.mediaItems) {
      try {
        final ticket = await _service.prepareMediaUpload(
          exerciseId: id,
          contentType: media.resolvedContentType,
        );

        final bytes = await _loadMediaBytes(media);
        await _service.sendMediaBytes(ticket: ticket, bytes: bytes);

        await _service.confirmMedia(exerciseId: id, path: ticket.path);
      } catch (_) {
        failedMediaCount++;
      }
    }

    final warning = failedMediaCount == 0
        ? null
        : 'Exercício cadastrado, mas $failedMediaCount mídia(s) não foram enviadas. '
              'Você poderá adicioná-las depois.';

    return ExerciseRegistrationResult(
      id: id,
      code: code,
      name: name,
      warning: warning,
      failedMediaCount: failedMediaCount,
    );
  }

  Future<Uint8List> _loadMediaBytes(ExerciseMedia media) async {
    final reader = media.readBytes;
    if (reader != null) {
      return await reader();
    }
    throw const ExerciseRegistrationFailure(
      'Não foi possível ler os dados do arquivo de mídia.',
    );
  }

  ExerciseRegistrationFailure _toFailure(
    Object error, {
    required String defaultMessage,
  }) {
    if (error is ExerciseRegistrationFailure) return error;
    if (error is FirebaseFunctionsException) {
      return switch (error.code) {
        'invalid-argument' => ExerciseRegistrationFailure(
          error.message ?? 'Dados do exercício inválidos.',
        ),
        'permission-denied' => ExerciseRegistrationFailure(
          error.message ??
              'Você não tem permissão para cadastrar este exercício.',
        ),
        'not-found' => ExerciseRegistrationFailure(
          error.message ?? 'Cavalo vinculado não encontrado ou inativo.',
        ),
        _ => ExerciseRegistrationFailure(error.message ?? defaultMessage),
      };
    }
    return ExerciseRegistrationFailure(defaultMessage);
  }
}
