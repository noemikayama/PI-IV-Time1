// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do valor imutável que representa uma região de atendimento.
// -----------------------------------------------------------------------------

// Define o nível geográfico usado para delimitar uma área de atendimento.
enum TrainerServiceAreaType { countryRegion, state, city }

// Valor imutável que reúne os dados aplicáveis a cada nível geográfico.
class TrainerServiceArea {
  // Uma macrorregião não precisa identificar estado ou cidade.
  const TrainerServiceArea.countryRegion({required this.countryRegion})
    : type = TrainerServiceAreaType.countryRegion,
      stateCode = null,
      stateName = null,
      cityName = null;

  // Um estado sempre permanece associado à macrorregião selecionada.
  const TrainerServiceArea.state({
    required this.countryRegion,
    required this.stateCode,
    required this.stateName,
  }) : type = TrainerServiceAreaType.state,
       cityName = null;

  // Uma cidade carrega toda a hierarquia para manter contexto na revisão.
  const TrainerServiceArea.city({
    required this.countryRegion,
    required this.stateCode,
    required this.stateName,
    required this.cityName,
  }) : type = TrainerServiceAreaType.city;

  // Hierarquia geográfica normalizada da seleção.
  final TrainerServiceAreaType type;
  final String countryRegion;
  final String? stateCode;
  final String? stateName;
  final String? cityName;

  // Texto principal exibido nas listas de seleção e confirmação.
  String get label => switch (type) {
    TrainerServiceAreaType.countryRegion => countryRegion,
    TrainerServiceAreaType.state => stateName!,
    TrainerServiceAreaType.city => cityName!,
  };

  // Complemento que esclarece o nível e o contexto da área escolhida.
  String get description => switch (type) {
    TrainerServiceAreaType.countryRegion => 'Região do país',
    TrainerServiceAreaType.state => 'Estado • $countryRegion',
    TrainerServiceAreaType.city => 'Cidade • $stateCode',
  };

  // Chave estável e insensível a maiúsculas usada para rejeitar duplicatas.
  String get identifier => [
    type.name,
    countryRegion,
    stateCode,
    cityName,
  ].whereType<String>().join('|').toLowerCase();
}
