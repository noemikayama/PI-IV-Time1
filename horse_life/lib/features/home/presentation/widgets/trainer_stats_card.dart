// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Conversão dos argumentos herdados para super parâmetros e remoção
// de import não utilizado, preservando o estilo visual do card do treinador.
// -----------------------------------------------------------------------------
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Criação do card de métricas compacto com gradiente e valores
// absolutos ou fracionários para o painel do Profissional.
// -----------------------------------------------------------------------------
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão de integração e compatibilidade com a arquitetura
// Repository/Mapper/Service, sem alterar a composição visual aprovada.
// -----------------------------------------------------------------------------
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Compatibilidade mantida por delegação ao componente genérico
// Home*, compartilhado entre Guardian e Professional.
// -----------------------------------------------------------------------------

// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Permite cards com indicador indisponível no backend atual.
// -----------------------------------------------------------------------------

import 'home_stats_card.dart';

/// API original de Professional mantida; lógica visual compartilhada.
class TrainerStatsCard extends HomeStatsCard {
  const TrainerStatsCard({
    super.key,
    required super.title,
    required super.value,
    super.total,
    required super.gradientColors,
  }) : super(style: HomeStatsCardStyle.trainer);
}
