// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
    super.key,
  });

  // Dependências recebidas de fora para manter a raiz configurável e testável.
  final AppInitializer initializeApp;
  final Widget home;

  // Configuração global do MaterialApp.
  @override
  Widget build(BuildContext context) {
    // Configura tema, identidade do aplicativo e controle de inicialização.
    return MaterialApp(
      title: 'HorseLife',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppGate(initializeApp: initializeApp, home: home),
    );
  }
}
