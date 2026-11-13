// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// HISTÓRICO DE ALTERAÇÕES
// 12/11/2026: Consulta exclusiva à Cloud Function listHorses; busca e
// ordenação remotas, validação de contrato e tratamento de perfil autenticado.

import 'package:cloud_functions/cloud_functions.dart';
import '../../domain/models/horse_list_item.dart';
import '../../domain/repositories/horse_list_repository.dart';

/// Não utiliza Firestore direto nem dados fictícios: listHorses aplica as
/// permissões e os vínculos conforme a sessão autenticada no backend.
class FirebaseHorseListRepository implements HorseListRepository {
  FirebaseHorseListRepository({FirebaseFunctions? functions})
      : _functions = functions ??
          FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final FirebaseFunctions _functions;

  @override
  Future<List<HorseListItem>> listHorses({
    required HorseListProfile profile,
    String search = '',
    HorseSortOrder order = HorseSortOrder.alphabeticalAsc,
  }) async {
    final query = search.trim();
    if (query.length > 80) {
      throw const FormatException('A busca deve ter até 80 caracteres.');
    }
    final data = <String, dynamic>{
      'ordenacao': order.firebaseValue,
      if (query.isNotEmpty) 'busca': query,
    };
    final response = await _functions.httpsCallable('listHorses').call<dynamic>(data);
    final result = _asMap(response.data);
    final expectedRole = profile == HorseListProfile.guardian
        ? 'RESPONSAVEL'
        : 'TREINADOR';
    if (result['tipoConta'] != expectedRole) {
      throw const FormatException(
        'A conta autenticada não corresponde ao perfil da listagem.',
      );
    }
    final rawHorses = result['cavalos'];
    if (rawHorses is! List) {
      throw const FormatException('Resposta inesperada do Firebase: lista ausente.');
    }
    return rawHorses
        .map((raw) => _fromCard(_asMap(raw), profile))
        .toList(growable: false);
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is! Map) {
      throw const FormatException('Resposta inesperada do Firebase.');
    }
    return value.map<String, dynamic>(
      (key, item) => MapEntry(key.toString(), item),
    );
  }

  static String _name(dynamic ref, {String fallback = 'Não informado'}) {
    if (ref == null) return fallback;
    final name = _asMap(ref)['nome']?.toString().trim();
    return name == null || name.isEmpty ? fallback : name;
  }

  static HorseListItem _fromCard(
    Map<String, dynamic> card,
    HorseListProfile profile,
  ) {
    final id = card['id']?.toString().trim() ?? '';
    final name = card['nome']?.toString().trim() ?? '';
    final date = DateTime.tryParse(card['vinculadoEm']?.toString() ?? '');
    if (id.isEmpty || name.isEmpty || date == null) {
      throw const FormatException('Card de cavalo inválido retornado pela Function.');
    }
    final rawRelations = card['responsabilidades'];
    final relations = rawRelations is List
        ? rawRelations.map((item) => item.toString()).toSet()
        : <String>{};
    final relation = profile == HorseListProfile.professional
        ? 'Treinador'
        : relations.contains('PROPRIETARIO')
            ? 'Proprietário'
            : relations.contains('ATLETA') ? 'Atleta' : 'Responsável';
    final image = card['foto'];
    final photoUrl = image == null ? null : _asMap(image)['url']?.toString();
    return HorseListItem(
      id: id,
      name: name,
      relation: relation,
      trainerName: _name(card['treinador'], fallback: 'Não vinculado'),
      ownerName: _name(card['proprietario']),
      modality: _name(card['modalidade'], fallback: 'Não informada'),
      imageUrl: (photoUrl?.isEmpty ?? true) ? null : photoUrl,
      linkedAt: date,
    );
  }
}
