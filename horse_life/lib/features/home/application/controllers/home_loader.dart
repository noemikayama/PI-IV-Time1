// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Contrato de carregamento assíncrono injetado nas HomeScreens,
// permitindo substituir dados de produção por fakes nos testes.
// -----------------------------------------------------------------------------

/// Operação tipada de carregamento, sem dependência de Flutter ou de SDK externo.
abstract interface class HomeLoader<T> {
  Future<T> fetchHome();
}
