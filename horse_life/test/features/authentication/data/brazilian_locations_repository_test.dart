// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Verificação da integração com os dados da biblioteca externa.
// -----------------------------------------------------------------------------

import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/authentication/data/repositories/brazilian_locations_repository.dart';

void main() {
  // Inicializa os canais exigidos pela biblioteca externa de localidades.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Implementação real exercitada como teste de integração local.
  const repository = CountryStateCityBrazilianLocationsRepository();

  // Cobertura da quantidade e de UFs representativas retornadas pela fonte.
  test('loads Brazilian states from country_state_city', () async {
    final states = await repository.fetchStates();

    expect(states, hasLength(27));
    expect(states.any((state) => state.code == 'SP'), isTrue);
    expect(states.any((state) => state.code == 'DF'), isTrue);
  });

  // Cobertura dos municípios e da ordenação aplicada pelo adaptador.
  test('loads cities alphabetically from country_state_city', () async {
    final cities = await repository.fetchCities('SP');
    final sortedCities = List<String>.of(cities)..sort(comparePortugueseNames);

    expect(cities, contains('Campinas'));
    expect(cities, contains('São Paulo'));
    expect(cities, orderedEquals(sortedCities));
  });

  test('rejects an invalid Brazilian state code', () async {
    expect(repository.fetchCities('XX'), throwsArgumentError);
  });
}

// Reproduz no teste a regra esperada de ordenação em português.
int comparePortugueseNames(String first, String second) {
  final normalizedComparison = normalize(first).compareTo(normalize(second));
  if (normalizedComparison != 0) return normalizedComparison;
  return first.toLowerCase().compareTo(second.toLowerCase());
}

// Remove acentos apenas para compor a chave comparável da asserção.
String normalize(String value) {
  const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final character = String.fromCharCode(rune);
    final index = accents.indexOf(character);
    buffer.write(index < 0 ? character : plain[index]);
  }
  return buffer.toString();
}
