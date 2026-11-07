// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Catálogos locais permanentes de raças e pelagens, com busca
// que ignora maiúsculas e acentos; sem requisições ou substituição por API.
// -----------------------------------------------------------------------------

/// Listas locais permanentes para os campos de raça e pelagem.
/// Não são obtidas, validadas nem substituídas por dados do servidor.
/// Seleção ilustrativa, não é um catálogo oficial exaustivo.
abstract final class MockHorseCatalog {
  static const breeds = <String>[
    'Andaluz',
    'Árabe',
    'Appaloosa',
    'Brasileiro de Hipismo',
    'Bretão',
    'Campolina',
    'Crioulo',
    'Frísio',
    'Hanoveriano',
    'Lusitano',
    'Mangalarga',
    'Mangalarga Marchador',
    'Marajoara',
    'Morgan',
    'Mustang',
    'Nordestino',
    'Paint Horse',
    'Pantaneiro',
    'Percheron',
    'Pônei Brasileiro',
    'Puro-Sangue Árabe',
    'Puro-Sangue Inglês',
    'Quarto de Milha',
    'Sela Francesa',
    'Sorraia',
  ];

  static const coats = <String>[
    'Alazã',
    'Alazã tostada',
    'Baia',
    'Baia amarilha',
    'Baia cabos negros',
    'Branca',
    'Castanha',
    'Castanha escura',
    'Castanha clara',
    'Gateada',
    'Lobuna',
    'Oveira',
    'Pampa',
    'Preta',
    'Preta zaina',
    'Rosilha',
    'Ruã',
    'Tordilha',
    'Tordilha clara',
    'Tordilha escura',
  ];

  static const modalityNames = <String>[
    'Adestramento',
    'Enduro',
    'Hipismo completo',
    'Laço comprido',
    'Rédeas',
    'Salto',
    'Três tambores',
    'Vaquejada',
  ];

  static String normalized(String source) {
    const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const to = 'aaaaaeeeeiiiiooooouuuuc';
    final lower = source.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      final index = from.indexOf(char);
      buffer.write(index < 0 ? char : to[index]);
    }
    return buffer.toString();
  }

  /// Filtra por trecho, ignorando maiúsculas e acentos: 'mang' => Mangalargas.
  static List<String> search(List<String> options, String query) {
    final term = normalized(query);
    if (term.isEmpty) return List<String>.of(options);
    return options.where((item) => normalized(item).contains(term)).toList();
  }
}
