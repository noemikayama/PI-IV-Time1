// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Ativação da restauração da sessão Firebase na composição do app.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Definição da tela inicial de boas-vindas como destino liberado
// após a splash.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do arquivo para inicializar os serviços do Flutter e
// montar a raiz do HorseLife com o carregamento do Firebase e a tela de login
// como destino inicial.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'features/authentication/data/repositories/firebase_authentication_session_repository.dart';
import 'features/authentication/presentation/screens/welcome_screen.dart';

// Ponto de entrada da aplicação.
void main() {
  // Prepara os serviços do Flutter antes de iniciar as dependências
  // assíncronas.
  WidgetsFlutterBinding.ensureInitialized();

  // Monta a aplicação com a inicialização do Firebase e a tela principal.
  runApp(
    HorseLifeApp(
      initializeApp: FirebaseBootstrap.initialize,
      home: const WelcomeScreen(),
      sessionRepository: const FirebaseAuthenticationSessionRepository(),
    ),
  );
}
