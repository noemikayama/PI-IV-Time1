// RESPONSÁVEL PELA ATUALIZAÇÃO: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão e padronização dos componentes e dados simulados da Home do Responsável, preservando a integração existente.
// -----------------------------------------------------------------------------
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do GuardianRepository e dos modelos com as Cloud
// Functions; documentação das responsabilidades e lógicas principais,
// preservando o comportamento anterior da interface.
// -----------------------------------------------------------------------------
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Compatibilidade mantida por delegação ao componente genérico
// Home*, compartilhado entre Guardian e Professional.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'home_stats_card.dart';

/// API original de Guardian mantida; lógica visual compartilhada.
class TrainingStatsCard extends HomeStatsCard {
  const TrainingStatsCard({
    super.key,
    required String title,
    required int completed,
    int? total,
    required List<Color> gradientColors,
  }) : super(
         title: title,
         value: completed,
         total: total,
         gradientColors: gradientColors,
         style: HomeStatsCardStyle.guardian,
       );
}
