// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Etapas de raça e pelagem usam o mesmo campo de busca local.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../data/mocks/mock_horse_catalog.dart';
import '../widgets/horse_search_field.dart';

enum HorseCatalogKind { breed, coat }

/// As opções são permanentes no frontend: nenhuma chamada ao servidor.
class HorseCatalogStep extends StatelessWidget {
  const HorseCatalogStep({
    required this.kind,
    required this.value,
    required this.onSelected,
    super.key,
  });

  final HorseCatalogKind kind;
  final String value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isBreed = kind == HorseCatalogKind.breed;
    return HorseSearchField(
      key: ValueKey(isBreed ? 'horse-breed-field' : 'horse-coat-field'),
      label: isBreed ? 'Raça' : 'Pelagem',
      options: isBreed ? MockHorseCatalog.breeds : MockHorseCatalog.coats,
      value: value,
      onSelected: onSelected,
    );
  }
}
