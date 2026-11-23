// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão de chaves explícitas no tratamento de FormatException,
// preservando o mapeamento das falhas de cadastro de cavalo.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Cadastro persistido em servidor, modalidades reais e anexos.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';

import '../models/horse_registration_draft.dart';
import '../services/firebase_horse_registration_service.dart';
import '../services/horse_registration_remote_service.dart';
import 'horse_registration_repository.dart';

/// Repositório real. Recebe um serviço substituível para facilitar os testes.
class FirebaseHorseRegistrationRepository
    implements HorseRegistrationRepository {
  FirebaseHorseRegistrationRepository({HorseRegistrationRemoteService? service})
    : _service = service ?? FirebaseHorseRegistrationService();

  final HorseRegistrationRemoteService _service;

  @override
  Future<List<HorseModality>> getModalities() async {
    try {
      final raw = await _service.getModalities();
      return raw
          .map((item) {
            final id = item['id'];
            final name = item['nome'];
            if (id is! String || name is! String || id.isEmpty) {
              throw const FormatException('Modalidade incompleta.');
            }
            return HorseModality(id: id, name: name);
          })
          .toList(growable: false);
    } catch (error) {
      throw _toFailure(
        error,
        defaultMessage: 'Não foi possível carregar as modalidades.',
      );
    }
  }

  @override
  Future<HorseRegistrationResult> register(HorseRegistrationDraft draft) async {
    // Primeiro salva o cadastro principal. Não inventa um ID em caso de falha.
    final Map<String, dynamic> data;
    try {
      data = await _service.registerHorse(draft.toApiPayload());
    } catch (error) {
      throw _toFailure(
        error,
        defaultMessage: 'Não foi possível cadastrar o cavalo.',
      );
    }

    final id = data['id'];
    final name = data['nome'];
    if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
      throw const HorseRegistrationFailure(
        'O servidor não confirmou o cadastro do cavalo.',
      );
    }

    // Imagens são opcionais. Falhas posteriores não apagam um cavalo já salvo.
    var failedImages = 0;
    for (final file in draft.images) {
      try {
        final lowerName = file.name.toLowerCase();
        final contentType = lowerName.endsWith('.png')
            ? 'image/png'
            : 'image/jpeg';
        final ticket = await _service.prepareImage(id, contentType);
        final bytes = await file.readAsBytes();
        await _service.sendImage(ticket, bytes);
        await _service.confirmImage(id, ticket.path);
      } catch (_) {
        failedImages++;
      }
    }

    return HorseRegistrationResult(
      id: id,
      name: name,
      warning: failedImages == 0
          ? null
          : 'Cavalo cadastrado, mas $failedImages imagem(ns) não foram enviadas. '
                'Você poderá adicioná-las depois.',
    );
  }

  HorseRegistrationFailure _toFailure(
    Object error, {
    required String defaultMessage,
  }) {
    if (error is HorseRegistrationFailure) return error;
    if (error is FirebaseFunctionsException) {
      // Mensagens simples para o usuário, mantendo detalhes técnicos no backend.
      return switch (error.code) {
        'already-exists' => const HorseRegistrationFailure(
          'Este microchip já está cadastrado.',
        ),
        'unauthenticated' => const HorseRegistrationFailure(
          'Entre na sua conta para cadastrar o cavalo.',
        ),
        'permission-denied' => const HorseRegistrationFailure(
          'Esta conta não tem permissão para cadastrar cavalos.',
        ),
        'invalid-argument' => HorseRegistrationFailure(
          error.message ?? 'Confira os dados informados.',
        ),
        'unavailable' || 'deadline-exceeded' => const HorseRegistrationFailure(
          'Servidor indisponível. Tente novamente.',
        ),
        _ => HorseRegistrationFailure(error.message ?? defaultMessage),
      };
    }
    if (error is FormatException) {
      return HorseRegistrationFailure(error.message);
    }
    return HorseRegistrationFailure(defaultMessage);
  }
}
