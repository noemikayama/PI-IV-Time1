// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos e segmentos do código de autenticação,
// detalhando responsabilidades, fluxo de dados e integração entre camadas.
//
// Data: 16/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do catálogo das macrorregiões brasileiras e suas UFs.
// -----------------------------------------------------------------------------

// Agrupa os códigos das UFs pertencentes a uma macrorregião brasileira.
class BrazilianCountryRegion {
  const BrazilianCountryRegion({required this.name, required this.stateCodes});

  // Nome apresentado na UI e conjunto de UFs usado para filtrar seleções.
  final String name;
  final Set<String> stateCodes;
}

// Catálogo fixo das cinco macrorregiões e suas respectivas UFs.
abstract final class BrazilianCountryRegions {
  static const values = [
    BrazilianCountryRegion(
      name: 'Centro-Oeste',
      stateCodes: {'DF', 'GO', 'MS', 'MT'},
    ),
    BrazilianCountryRegion(
      name: 'Nordeste',
      stateCodes: {'AL', 'BA', 'CE', 'MA', 'PB', 'PE', 'PI', 'RN', 'SE'},
    ),
    BrazilianCountryRegion(
      name: 'Norte',
      stateCodes: {'AC', 'AM', 'AP', 'PA', 'RO', 'RR', 'TO'},
    ),
    BrazilianCountryRegion(
      name: 'Sudeste',
      stateCodes: {'ES', 'MG', 'RJ', 'SP'},
    ),
    BrazilianCountryRegion(name: 'Sul', stateCodes: {'PR', 'RS', 'SC'}),
  ];

  // Confirma se a sigla pertence a uma das 27 unidades federativas.
  static bool containsStateCode(String code) {
    return values.any((region) => region.stateCodes.contains(code));
  }
}
