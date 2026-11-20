// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do enum dos dias da semana do plano de treinamento com
// mapeamento para as chaves da API (SEGUNDA..DOMINGO) e rótulos em português.
// -----------------------------------------------------------------------------

/// Dias da semana aceitos pelo planejamento semanal do plano de treinamento.
enum TrainingPlanWeekday {
  monday(apiKey: 'SEGUNDA', label: 'Segunda-feira', shortLabel: 'Seg'),
  tuesday(apiKey: 'TERCA', label: 'Terça-feira', shortLabel: 'Ter'),
  wednesday(apiKey: 'QUARTA', label: 'Quarta-feira', shortLabel: 'Qua'),
  thursday(apiKey: 'QUINTA', label: 'Quinta-feira', shortLabel: 'Qui'),
  friday(apiKey: 'SEXTA', label: 'Sexta-feira', shortLabel: 'Sex'),
  saturday(apiKey: 'SABADO', label: 'Sábado', shortLabel: 'Sáb'),
  sunday(apiKey: 'DOMINGO', label: 'Domingo', shortLabel: 'Dom');

  const TrainingPlanWeekday({
    required this.apiKey,
    required this.label,
    required this.shortLabel,
  });

  final String apiKey;
  final String label;
  final String shortLabel;
}
