// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 16/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Extração das macrorregiões para um modelo próprio, validação das
// UFs consultadas e retorno de coleções imutáveis.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração da biblioteca country_state_city para consultar estados
// e municípios brasileiros e organização das UFs por macrorregião do IBGE.
// -----------------------------------------------------------------------------

import 'package:country_state_city/country_state_city.dart' as locations;

import '../models/brazilian_country_region.dart';

// Projeção mínima de uma UF para evitar expor tipos da biblioteca à interface.
class BrazilianStateOption {
  const BrazilianStateOption({required this.name, required this.code});

  final String name;
  final String code;
}

// Contrato assíncrono que desacopla a UI da fonte externa de localidades.
abstract interface class BrazilianLocationsRepository {
  Future<List<BrazilianStateOption>> fetchStates();

  Future<List<String>> fetchCities(String stateCode);
}

// Adaptador da biblioteca country_state_city para o domínio da aplicação.
class CountryStateCityBrazilianLocationsRepository
    implements BrazilianLocationsRepository {
  const CountryStateCityBrazilianLocationsRepository();

  @override
  Future<List<BrazilianStateOption>> fetchStates() async {
    // Converte, ordena e devolve apenas nome e sigla das UFs brasileiras.
    final states = await locations.getStatesOfCountry('BR');
    final result = states
        .map(
          (state) =>
              BrazilianStateOption(name: state.name, code: state.isoCode),
        )
        .toList(growable: false);
    result.sort((first, second) => _compareNames(first.name, second.name));
    return List.unmodifiable(result);
  }

  @override
  Future<List<String>> fetchCities(String stateCode) async {
    final normalizedStateCode = stateCode.trim().toUpperCase();
    if (!BrazilianCountryRegions.containsStateCode(normalizedStateCode)) {
      throw ArgumentError.value(
        stateCode,
        'stateCode',
        'UF brasileira inválida',
      );
    }

    // Remove municípios repetidos antes de aplicar a ordenação alfabética.
    final cities = await locations.getStateCities('BR', normalizedStateCode);
    final result = cities.map((city) => city.name).toSet().toList();
    result.sort(_compareNames);
    return List.unmodifiable(result);
  }
}

// Compara nomes ignorando acentos, com desempate pelo texto original.
int _compareNames(String first, String second) {
  final normalizedComparison = _sortableName(
    first,
  ).compareTo(_sortableName(second));
  if (normalizedComparison != 0) return normalizedComparison;
  return first.toLowerCase().compareTo(second.toLowerCase());
}

// Produz uma chave simples de ordenação adequada aos nomes em português.
String _sortableName(String value) {
  const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  final lowerCase = value.toLowerCase();
  final buffer = StringBuffer();

  for (final rune in lowerCase.runes) {
    final character = String.fromCharCode(rune);
    final index = accents.indexOf(character);
    buffer.write(index < 0 ? character : plain[index]);
  }
  return buffer.toString();
}
