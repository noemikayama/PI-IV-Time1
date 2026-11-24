// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração da composição de dependências na raiz e seleção
// das Homes pelo papel autenticado, sem duplicar o MaterialApp.
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
import 'package:horse_life/app/app.dart';
import 'package:horse_life/app/app_dependencies.dart';
import 'package:horse_life/core/firebase/firebase_bootstrap.dart';
import 'package:horse_life/features/authentication/presentation/screens/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Os adapters são criados aqui, mas só acessam o Firebase após o bootstrap.
  final dependencies = AppDependencies.production();

  runApp(
    HorseLifeApp(
      initializeApp: FirebaseBootstrap.initialize,
      home: const WelcomeScreen(),
      dependencies: dependencies,
    ),
  );
}
