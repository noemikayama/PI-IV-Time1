// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Reorganização da camada de dados e atualização dos imports; padronização
// de autoria e histórico para revisão do PR.
//
// Data: 13/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Rótulos de ordenação alinhados ao Figma (setas ↑ e ↓).
//
// Data: 07/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Bottom sheet que envia a ordenação selecionada para o Firebase.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../data/models/horse_list_item.dart';

extension HorseSortOrderLabel on HorseSortOrder {
  String get label {
    switch (this) {
      case HorseSortOrder.alphabeticalAsc:
        return 'A-Z';
      case HorseSortOrder.alphabeticalDesc:
        return 'Z-A';
      case HorseSortOrder.recentAsc:
        return 'Adicionado recentemente ↑';
      case HorseSortOrder.recentDesc:
        return 'Adicionado recentemente ↓';
    }
  }
}

Future<HorseSortOrder?> showHorseListSortSheet({
  required BuildContext context,
  required HorseSortOrder currentOrder,
}) {
  return showModalBottomSheet<HorseSortOrder>(
    context: context,
    showDragHandle: true,
    backgroundColor: const Color(0xFFF6F6F6),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (BuildContext sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Row(
                children: <Widget>[
                  Icon(Icons.sort_rounded, size: 22),
                  SizedBox(width: 5),
                  Text(
                    'Ordenar resultados',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 9),
              for (final HorseSortOrder order in HorseSortOrder.values)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(sheetContext).pop(order),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: <Widget>[
                        SizedBox(
                          width: 25,
                          child: order == currentOrder
                              ? const Icon(Icons.check_rounded, color: Color(0xFF008F79), size: 20)
                              : null,
                        ),
                        Text(
                          order.label,
                          style: TextStyle(
                            fontSize: 15,
                            color: order == currentOrder
                                ? const Color(0xFF008F79)
                                : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
