// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Contrato isolado de verificação do microchip. Formato validado
// localmente enquanto a verificação definitiva pelo servidor Java não existe.
// -----------------------------------------------------------------------------

/// Mensagem legível para a tela quando o microchip é recusado.
class HorseMicrochipValidationFailure implements Exception {
  const HorseMicrochipValidationFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Apenas a verificação do microchip terá integração futura com o servidor.
/// Raças e pelagens usam catálogos locais permanentes, sem dependência desta API.
abstract class HorseMicrochipValidator {
  /// Lança [HorseMicrochipValidationFailure] quando o código não é aceito.
  Future<void> validate(String microchip);
}

/// Provisório: permite testar erros de caracteres e comprimento sem servidor.
/// Não confirma existência, autenticidade ou unicidade do microchip.
class LocalHorseMicrochipValidator implements HorseMicrochipValidator {
  const LocalHorseMicrochipValidator();

  @override
  Future<void> validate(String microchip) async {
    if (!RegExp(r'^\d{15}$').hasMatch(microchip)) {
      throw const HorseMicrochipValidationFailure(
        'O microchip deve conter exatamente 15 dígitos numéricos, sem letras ou espaços.',
      );
    }
  }
}
