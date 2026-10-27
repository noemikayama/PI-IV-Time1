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
import 'home_section_card.dart';

/// Adaptador compatível: mantém a API utilizada pela Home do Responsável.
class GuardianSectionCard extends HomeSectionCard {
  const GuardianSectionCard({
    super.key,
    required super.title,
    required super.child,
    super.onShowAll,
  });
}
