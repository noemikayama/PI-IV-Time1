// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Formatação de data reutilizada nas etapas e na revisão.
// -----------------------------------------------------------------------------

String formatHorseDate(DateTime? date) => date == null
    ? 'DD/MM/AAAA'
    : '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
