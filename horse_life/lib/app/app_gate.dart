// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Aumento da duração mínima da splash de três para quatro
// segundos.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do controle de inicialização do Firebase, com splash
// de três segundos e tratamento de carregamento, falha e nova tentativa.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../features/splash/presentation/screens/splash_screen.dart';

class AppGate extends StatefulWidget {
  const AppGate({required this.initializeApp, required this.home, super.key});

  final Future<void> Function() initializeApp;
  final Widget home;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  // Garante tempo suficiente para a identidade visual ser percebida.
  static const _minimumSplashDuration = Duration(seconds: 4);

  late Future<void> _initialization;

  @override
  void initState() {
    super.initState();

    // Inicia o carregamento das dependências uma única vez ao montar o gate.
    _initialization = _initialize();
  }

  Future<void> _initialize() async {
    // Aguarda simultaneamente o Firebase e a duração mínima da splash.
    await Future.wait<void>([
      Future<void>.sync(widget.initializeApp),
      Future<void>.delayed(_minimumSplashDuration),
    ]);
  }

  void _retry() {
    // Reinicia o fluxo e notifica a interface após uma falha de conexão.
    setState(() {
      _initialization = _initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Seleciona a tela correspondente ao estado atual da inicialização.
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        // Exibe a identidade visual enquanto as dependências são carregadas.
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }

        // Oferece uma nova tentativa quando a inicialização falha.
        if (snapshot.hasError) {
          return SplashScreen.failed(onRetry: _retry);
        }

        // Libera a tela principal somente depois da inicialização
        // bem-sucedida.
        return widget.home;
      },
    );
  }
}
