// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da configuração do MaterialApp e do tema visual do
// HorseLife, com controle de inicialização pelo AppGate.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import 'app_gate.dart';

// Define o contrato usado para inicializar as dependências da aplicação.
typedef AppInitializer = Future<void> Function();

class HorseLifeApp extends StatelessWidget {
  const HorseLifeApp({
    required this.initializeApp,
    required this.home,
    super.key,
  });

  final AppInitializer initializeApp;
  final Widget home;

  @override
  Widget build(BuildContext context) {
    // Configura tema, identidade do aplicativo e controle de inicialização.
    return MaterialApp(
      title: 'HorseLife',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF009B7A)),
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        useMaterial3: true,
      ),
      home: AppGate(initializeApp: initializeApp, home: home),
    );
  }
}
