// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Davi Alves Froza - RA 25016900
// Alteração: Opção de apontar as Functions para o emulador local com
// --dart-define=FUNCTIONS_EMULATOR_HOST=<endereço>.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do inicializador centralizado do Firebase.
// Seleciona as opções correspondentes à plataforma atual.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

abstract final class FirebaseBootstrap {
  static Future<void> initialize() async {
    // Inicializa o Firebase com as opções correspondentes à plataforma
    // atual.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Só com o define as Functions vão para o emulador local (porta 5001);
    // Auth, Storage e o banco continuam os reais. Como instanceFor guarda
    // uma instância por região, esta configuração vale para todas as
    // chamadas do app.
    const host = String.fromEnvironment('FUNCTIONS_EMULATOR_HOST');
    if (host.isNotEmpty) {
      FirebaseFunctions.instanceFor(
        region: 'southamerica-east1',
      ).useFunctionsEmulator(host, 5001);
    }
  }
}
