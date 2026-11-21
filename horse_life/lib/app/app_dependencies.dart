// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Criação da composição de dependências de autenticação e das
// duas Homes. Loaders Firebase são montados de forma tardia, após o bootstrap.
// -----------------------------------------------------------------------------

import 'package:horse_life/features/authentication/data/repositories/authentication_session_repository.dart';
import 'package:horse_life/features/authentication/data/repositories/firebase_authentication_session_repository.dart';
import 'package:horse_life/features/home/application/controllers/home_loader.dart';
import 'package:horse_life/features/home/data/models/guardian_home_data.dart';
import 'package:horse_life/features/home/data/models/trainer_home_data.dart';
import 'package:horse_life/features/home/home_composition.dart';

/// Dependências de longa duração. Não mantém o estado visual do aplicativo.
/// Pode receber repositories e loaders fake em testes.
class AppDependencies {
  AppDependencies({
    required this.sessionRepository,
    HomeLoader<GuardianHomeData>? guardianLoader,
    HomeLoader<TrainerHomeData>? trainerLoader,
  }) : _guardianLoader = guardianLoader,
       _trainerLoader = trainerLoader;

  /// Não acessa FirebaseAuth.instance durante a criação da composição.
  factory AppDependencies.production() => AppDependencies(
    sessionRepository: const FirebaseAuthenticationSessionRepository(),
  );

  final AuthenticationSessionRepository sessionRepository;

  HomeLoader<GuardianHomeData>? _guardianLoader;
  HomeLoader<TrainerHomeData>? _trainerLoader;

  /// A primeira leitura deve ocorrer após FirebaseBootstrap.initialize.
  HomeLoader<GuardianHomeData> get guardianLoader =>
      _guardianLoader ??= HomeComposition.guardian();

  /// O retorno de getHome para trainer depende do contrato real do backend.
  HomeLoader<TrainerHomeData> get trainerLoader =>
      _trainerLoader ??= HomeComposition.trainer();
}
