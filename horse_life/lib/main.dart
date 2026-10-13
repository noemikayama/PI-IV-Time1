// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do arquivo para inicializar os serviços do Flutter e
// montar a raiz do HorseLife com o carregamento do Firebase.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/firebase/firebase_bootstrap.dart';

void main() {
  // Prepara os serviços do Flutter antes de iniciar as dependências
  // assíncronas.
  WidgetsFlutterBinding.ensureInitialized();

  // Monta a aplicação com a inicialização do Firebase e a tela principal.
  runApp(
    HorseLifeApp(
      initializeApp: FirebaseBootstrap.initialize,
      home: const HorseLifeHome(),
    ),
  );
}

class HorseLifeHome extends StatelessWidget {
  const HorseLifeHome({super.key});

  @override
  Widget build(BuildContext context) {
    // Mantém o ponto inicial da interface disponível após a inicialização.
    return const Scaffold(body: SizedBox.expand());
  }
}
