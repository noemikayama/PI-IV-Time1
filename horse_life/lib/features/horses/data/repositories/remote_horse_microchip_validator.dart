// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Adaptador para conectar a futura verificação de microchip em Java.
// -----------------------------------------------------------------------------

import 'horse_microchip_validator.dart';

/// Recebe uma função que faz a consulta ao Java quando o endpoint estiver pronto.
/// Não inventa endereço, rota ou formato da resposta do backend ainda indefinido.
class RemoteHorseMicrochipValidator implements HorseMicrochipValidator {
  const RemoteHorseMicrochipValidator({required this.verifyOnServer});

  final Future<void> Function(String code) verifyOnServer;

  @override
  Future<void> validate(String microchip) async {
    // Primeiro erro de formato, depois verificação de existência/unicidade.
    await const LocalHorseMicrochipValidator().validate(microchip);
    await verifyOnServer(microchip);
  }
}
