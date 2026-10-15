// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do inicializador centralizado do Firebase.
// Seleciona as opções correspondentes à plataforma atual.
// -----------------------------------------------------------------------------

import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

abstract final class FirebaseBootstrap {
  static Future<void> initialize() {
    // Inicializa o Firebase com as opções correspondentes à plataforma
    // atual.
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
