// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Revisão integral dos comentários e documentação das dependências
// de agenda, execução e finalização, incluindo seus ciclos de inicialização.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Revisão da documentação das dependências injetáveis e do ciclo de
// criação tardia dos carregadores da Home e da agenda. Inclusão dos repositórios
// responsáveis por carregar e finalizar a execução de um treino.
//
// Data: 20/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão do carregador da agenda entre as dependências de longa
// duração, com criação tardia do repositório Firebase de produção.
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
import 'package:horse_life/features/training/data/repositories/training_agenda_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_execution_repository.dart';

/// Dependências de longa duração. Não mantém o estado visual do aplicativo.
/// Pode receber repositories e loaders fake em testes.
class AppDependencies {
  AppDependencies({
    required this.sessionRepository,
    HomeLoader<GuardianHomeData>? guardianLoader,
    HomeLoader<TrainerHomeData>? trainerLoader,
    TrainingAgendaLoader? trainingAgendaLoader,
    TrainingExecutionLoader? trainingExecutionLoader,
    TrainingCompletionSubmitter? trainingCompletionSubmitter,
  }) : _guardianLoader = guardianLoader,
       _trainerLoader = trainerLoader,
       _trainingAgendaLoader = trainingAgendaLoader,
       _trainingExecutionLoader = trainingExecutionLoader,
       _trainingCompletionSubmitter = trainingCompletionSubmitter;

  /// Não acessa FirebaseAuth.instance durante a criação da composição.
  factory AppDependencies.production() => AppDependencies(
    sessionRepository: const FirebaseAuthenticationSessionRepository(),
  );

  /// Fonte da sessão usada pelo gate para observar autenticação e encerrar o
  /// acesso atual.
  final AuthenticationSessionRepository sessionRepository;

  HomeLoader<GuardianHomeData>? _guardianLoader;
  HomeLoader<TrainerHomeData>? _trainerLoader;
  TrainingAgendaLoader? _trainingAgendaLoader;
  TrainingExecutionLoader? _trainingExecutionLoader;
  TrainingCompletionSubmitter? _trainingCompletionSubmitter;

  /// A primeira leitura deve ocorrer após FirebaseBootstrap.initialize.
  HomeLoader<GuardianHomeData> get guardianLoader =>
      _guardianLoader ??= HomeComposition.guardian();

  /// O retorno de getHome para trainer depende do contrato real do backend.
  HomeLoader<TrainerHomeData> get trainerLoader =>
      _trainerLoader ??= HomeComposition.trainer();

  /// Cria a integração da agenda somente após a inicialização do Firebase.
  TrainingAgendaLoader get trainingAgendaLoader =>
      _trainingAgendaLoader ??= FirebaseTrainingAgendaRepository();

  /// Resolve o treino agendado e carrega seus detalhes e exercícios.
  TrainingExecutionLoader get trainingExecutionLoader =>
      _trainingExecutionLoader ??= FirebaseTrainingExecutionRepository();

  /// Envia ao backend o resultado preenchido ao final de uma execução.
  TrainingCompletionSubmitter get trainingCompletionSubmitter =>
      _trainingCompletionSubmitter ??= FirebaseTrainingCompletionRepository();
}
