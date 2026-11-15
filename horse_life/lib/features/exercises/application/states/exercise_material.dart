// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Alinhamento da serialização toJson() com o contrato do backend
// de exercícios, utilizando a chave 'descricao' em vez de 'nome'.
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do objeto de valor para os materiais necessários à
// execução de um exercício, contendo nome e quantidade.
// -----------------------------------------------------------------------------

// Representa um equipamento ou recurso exigido para a execução do exercício.
final class ExerciseMaterial {
  const ExerciseMaterial({
    required this.name,
    required this.quantity,
  }) : assert(quantity > 0, 'A quantidade do material deve ser maior que zero.');

  // Nome descritivo do material (ex.: Cavalete, Vara) e quantidade necessária.
  final String name;
  final int quantity;

  // Rótulo padronizado exibido nas listagens e na revisão (ex.: "(3) Cavalete").
  String get displayLabel => '($quantity) $name';

  // Serializa o item para o formato esperado pelo backend de exercícios.
  Map<String, Object> toJson() => {
    'descricao': name.trim(),
    'quantidade': quantity,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseMaterial &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          quantity == other.quantity;

  @override
  int get hashCode => Object.hash(name, quantity);
}
