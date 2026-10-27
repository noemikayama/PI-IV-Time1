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
//
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Recebimento de AppDependencies e encaminhamento ao AppGate,
// com manutenção dos parâmetros legados para compatibilidade.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/app_dependencies.dart';
import 'package:horse_life/app/app_gate.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/authentication/data/repositories/authentication_session_repository.dart';
import 'package:horse_life/features/home/application/controllers/home_loader.dart';
import 'package:horse_life/features/home/data/models/guardian_home_data.dart';
import 'package:horse_life/features/home/data/models/professional_home_data.dart';

// Contrato de inicialização exigido pela raiz do aplicativo.
typedef AppInitializer = Future<void> Function();

class HorseLifeApp extends StatelessWidget {
  const HorseLifeApp({
    required this.initializeApp,
    required this.home,
    this.dependencies,
    this.sessionRepository,
    this.guardianLoader,
    this.trainerLoader,
    super.key,
  });

  final AppInitializer initializeApp;
  final Widget home;

  /// Composição preferencial, criada uma única vez pelo main.dart.
  final AppDependencies? dependencies;

  /// Parâmetros antigos mantidos para não quebrar testes/composições existentes.
  final AuthenticationSessionRepository? sessionRepository;
  final HomeLoader<GuardianHomeData>? guardianLoader;
  final HomeLoader<ProfessionalHomeData>? trainerLoader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HorseLife',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppGate(
        initializeApp: initializeApp,
        home: home,
        dependencies: dependencies,
        sessionRepository: sessionRepository,
        guardianLoader: guardianLoader,
        trainerLoader: trainerLoader,
      ),
    );
  }
}
