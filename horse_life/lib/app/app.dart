// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão do repositório opcional de sessão na composição do gate.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Aplicação do tema institucional centralizado do HorseLife.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da configuração do MaterialApp e do tema visual do
// HorseLife, com controle de inicialização pelo AppGate.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../features/authentication/data/repositories/authentication_session_repository.dart';
import 'app_gate.dart';
import 'theme/app_theme.dart';

// Define o contrato usado para inicializar as dependências da aplicação.
typedef AppInitializer = Future<void> Function();

// Raiz visual do HorseLife, responsável por reunir o tema institucional, o
// processo de inicialização e a primeira tela liberada pelo AppGate.
class HorseLifeApp extends StatelessWidget {
  const HorseLifeApp({
    required this.initializeApp,
    required this.home,
    this.sessionRepository,
    super.key,
  });

  // Dependências recebidas de fora para manter a raiz configurável e testável.
  final AppInitializer initializeApp;
  final Widget home;
  final AuthenticationSessionRepository? sessionRepository;

  // Configuração global do MaterialApp.
  @override
  Widget build(BuildContext context) {
    // Configura tema, identidade do aplicativo e controle de inicialização.
    return MaterialApp(
      title: 'HorseLife',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppGate(
        initializeApp: initializeApp,
        home: home,
        sessionRepository: sessionRepository,
      ),
    );
  }
}
