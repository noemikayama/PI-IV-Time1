// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 19/11/2026
// Autor: Davi Alves Froza - RA 25016900
// Alteração: Comentários atualizados: a consulta ao Java existe e é feita
// pela callable validateMicrochip.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Adaptador para conectar a futura verificação de microchip em Java.
// -----------------------------------------------------------------------------

import 'horse_microchip_validator.dart';

/// Recebe a função que consulta o servidor (em produção, a callable
/// validateMicrochip, que repassa o código ao servidor Java).
class RemoteHorseMicrochipValidator implements HorseMicrochipValidator {
  const RemoteHorseMicrochipValidator({required this.verifyOnServer});

  final Future<void> Function(String code) verifyOnServer;

  @override
  Future<void> validate(String microchip) async {
    // Primeiro o formato, no app; depois o país e os dígitos verificadores,
    // no servidor. A unicidade é conferida só no cadastro (registerHorse).
    await const LocalHorseMicrochipValidator().validate(microchip);
    await verifyOnServer(microchip);
  }
}
