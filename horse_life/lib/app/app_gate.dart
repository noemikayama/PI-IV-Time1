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
//
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Roteamento da sessão para a Home de Guardian ou Trainer,
// injeção tardia dos loaders e isolamento da navegação após login/logout.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/app_dependencies.dart';
import 'package:horse_life/features/authentication/application/states/login_session.dart';
import 'package:horse_life/features/authentication/data/repositories/authentication_session_repository.dart';
import 'package:horse_life/features/home/application/controllers/home_loader.dart';
import 'package:horse_life/features/home/data/models/guardian_home_data.dart';
import 'package:horse_life/features/home/data/models/professional_home_data.dart';
import 'package:horse_life/features/home/home_composition.dart';
import 'package:horse_life/features/home/presentation/screens/guardian/guardian_home_screen.dart';
import 'package:horse_life/features/home/presentation/screens/trainer/professional_home_screen.dart';
import 'package:horse_life/features/splash/presentation/screens/splash_screen.dart';

/// Permite testar o gate sem montar os cards de cada Home.
typedef SessionHomeBuilder = Widget Function(
  BuildContext context,
  LoginSession session,
  Future<void> Function() onLogout,
);

class AppGate extends StatefulWidget {
  const AppGate({
    required this.initializeApp,
    required this.home,
    this.dependencies,
    this.sessionRepository,
    this.guardianLoader,
    this.trainerLoader,
    this.guardianHomeBuilder,
    this.trainerHomeBuilder,
    this.minimumSplashDuration = const Duration(seconds: 4),
    super.key,
  });

  final Future<void> Function() initializeApp;
  final Widget home;
  final AppDependencies? dependencies;

  // Compatibilidade com chamadas anteriores do AppGate.
  final AuthenticationSessionRepository? sessionRepository;
  final HomeLoader<GuardianHomeData>? guardianLoader;
  final HomeLoader<ProfessionalHomeData>? trainerLoader;

  final SessionHomeBuilder? guardianHomeBuilder;
  final SessionHomeBuilder? trainerHomeBuilder;
  final Duration minimumSplashDuration;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  late Future<void> _initialization;
  Stream<LoginSession?>? _sessionStream;
  HomeLoader<GuardianHomeData>? _legacyGuardianLoader;
  HomeLoader<ProfessionalHomeData>? _legacyTrainerLoader;

  AuthenticationSessionRepository? get _sessionRepository =>
      widget.dependencies?.sessionRepository ?? widget.sessionRepository;

  @override
  void initState() {
    super.initState();
    _initialization = _initialize();
  }

  @override
  void didUpdateWidget(covariant AppGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousRepository =
        oldWidget.dependencies?.sessionRepository ?? oldWidget.sessionRepository;
    if (!identical(previousRepository, _sessionRepository)) {
      _sessionStream = null;
    }
  }

  /// Mantém splash e inicialização em paralelo; não bloqueia o primeiro frame.
  Future<void> _initialize() async {
    await Future.wait<void>([
      Future<void>.sync(widget.initializeApp),
      Future<void>.delayed(widget.minimumSplashDuration),
    ]);
  }

  void _retryInitialization() {
    setState(() {
      _sessionStream = null;
      _initialization = _initialize();
    });
  }

  void _retrySession() {
    // Não chama FirebaseBootstrap.initialize outra vez por erro de sessão.
    setState(() => _sessionStream = null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SplashScreen();
        }
        if (snapshot.hasError) {
          return SplashScreen.failed(onRetry: _retryInitialization);
        }
        return _buildSessionGate();
      },
    );
  }

  Widget _buildSessionGate() {
    final repository = _sessionRepository;
    if (repository == null) return widget.home; // Compatibilidade legado.

    _sessionStream ??= repository.watchSession();
    return StreamBuilder<LoginSession?>(
      stream: _sessionStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        if (snapshot.hasError) {
          return SplashScreen.failed(onRetry: _retrySession);
        }

        final session = snapshot.data;
        if (session == null) {
          return _buildFlow(
            identity: 'public',
            pageBuilder: (context) => widget.home,
          );
        }
        return _buildFlow(
          identity: 'authenticated:${session.uid}:${session.role.value}',
          pageBuilder: (context) => _buildAuthenticatedHome(
            context,
            session,
            repository.signOut,
          ),
        );
      },
    );
  }

  /// Troca o Navigator inteiro quando a identidade muda: não mantém rotas
  /// do login/registro acessíveis após o logout ou uma troca de perfil.
  Widget _buildFlow({
    required String identity,
    required WidgetBuilder pageBuilder,
  }) {
    return HeroControllerScope.none(
      child: Navigator(
        key: ValueKey<String>('horse-life-flow:$identity'),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: pageBuilder,
        ),
      ),
    );
  }

  HomeLoader<GuardianHomeData> get _guardianLoader =>
      widget.dependencies?.guardianLoader ??
      widget.guardianLoader ??
      (_legacyGuardianLoader ??= HomeComposition.guardian());

  HomeLoader<ProfessionalHomeData> get _trainerLoader =>
      widget.dependencies?.trainerLoader ??
      widget.trainerLoader ??
      (_legacyTrainerLoader ??= HomeComposition.professional());

  Widget _buildAuthenticatedHome(
    BuildContext context,
    LoginSession session,
    Future<void> Function() onLogout,
  ) {
    switch (session.role) {
      case AuthenticationRole.guardian:
        return widget.guardianHomeBuilder?.call(context, session, onLogout) ??
            GuardianHomeScreen(
              onLogout: onLogout,
              loader: _guardianLoader,
            );
      case AuthenticationRole.trainer:
        return widget.trainerHomeBuilder?.call(context, session, onLogout) ??
            ProfessionalHomeScreen(
              onLogout: onLogout,
              loader: _trainerLoader,
            );
    }
  }
}
