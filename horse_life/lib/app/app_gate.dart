// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Observação da sessão persistente para alternar entre o conteúdo
// público e a home, com encerramento pelo repositório de autenticação.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do controle de inicialização do Firebase, com splash
// de quatro segundos e tratamento de carregamento, falha e nova tentativa.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../features/authentication/application/states/login_session.dart';
import '../features/authentication/data/repositories/authentication_session_repository.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';

// Porta de entrada visual que protege o restante do aplicativo enquanto as
// dependências obrigatórias são inicializadas.
class AppGate extends StatefulWidget {
  const AppGate({
    required this.initializeApp,
    required this.home,
    this.sessionRepository,
    super.key,
  });

  final Future<void> Function() initializeApp;
  final Widget home;
  final AuthenticationSessionRepository? sessionRepository;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  // Configuração do tempo mínimo de exposição da identidade visual.
  // Garante tempo suficiente para a identidade visual ser percebida.
  static const _minimumSplashDuration = Duration(seconds: 4);

  // Estado assíncrono acompanhado pelo FutureBuilder.
  late Future<void> _initialization;
  Stream<LoginSession?>? _session;

  // Ciclo de vida e inicialização.
  @override
  void initState() {
    super.initState();

    // Inicia o carregamento das dependências uma única vez ao montar o gate.
    _initialization = _initialize();
  }

  // Orquestra o carregamento real e o tempo mínimo da splash em paralelo.
  Future<void> _initialize() async {
    // Aguarda simultaneamente o Firebase e a duração mínima da splash.
    await Future.wait<void>([
      Future<void>.sync(widget.initializeApp),
      Future<void>.delayed(_minimumSplashDuration),
    ]);
  }

  // Recuperação após falha.
  void _retry() {
    // Reinicia o fluxo e notifica a interface após uma falha de conexão.
    setState(() {
      _session = null;
      _initialization = _initialize();
    });
  }

  // Seleção da interface para carregamento, erro ou sucesso.
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

        return _buildSessionGate();
      },
    );
  }

  Widget _buildSessionGate() {
    final repository = widget.sessionRepository;
    if (repository == null) return widget.home;

    _session ??= repository.watchSession();
    return StreamBuilder<LoginSession?>(
      stream: _session,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasError) {
          return SplashScreen.failed(onRetry: _retry);
        }

        final session = snapshot.data;
        if (session == null) return widget.home;
        return HomeScreen(signOut: repository.signOut);
      },
    );
  }
}
