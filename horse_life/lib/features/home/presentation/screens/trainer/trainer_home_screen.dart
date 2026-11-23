// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Correção dos callbacks de setState que devolviam Future durante o
// recarregamento da Home após navegações e novas tentativas; documentação da
// regra de atualização síncrona da Future armazenada.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Resolução direta do código de treinamento a partir do ID do registro
// da agenda via callable getTrainingRecord e remoção do bloqueio indevido por SnackBar.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Remoção da correlação com dados mockados em _openTrainingDetails,
// resolução do treinamento real no backend via galeria do treinador quando
// identificado apenas por registroId/título e correção do direcionamento de
// onViewPlan para TrainingPlanDetailScreen.
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Ajuste na instanciação de TrainingPlanGalleryItem em _openTrainingDetails
// para fornecer os campos obrigatórios code e estimatedDurationMinutes.
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Integração da navegação para a tela de visualização de treinamentos
// (TrainingDetailScreen) a partir dos botões "Ver detalhes" dos cards da agenda
// e "Ver treino" da Home do treinador.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Auditoria dos comentários da agenda profissional e documentação
// das dependências encaminhadas ao fluxo de execução e finalização do treino.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do carregador conectado da agenda profissional e da
// adaptação dos treinos da API para os callbacks da Home. Encaminhamento das
// dependências de consulta e finalização da execução do treino.
//
// Data: 20/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Conexão opcional da agenda profissional ao backend, preservando
// os callbacks de consulta de planos, treinos e histórico da Home.
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Atualização de _homeFuture ao retornar do perfil de cavalos e da
// listagem, e filtragem de treinos cancelados na montagem da agenda.
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Correção da duplicidade em onDestinationSelected na HomeBottomNavBar,
// conexão unificada do fluxo de navegação e repasse ao Dashboard.
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Conexão dos atalhos de plano de treinos e treinamento do menu
// flutuante da agenda com TrainingPlanRegistrationFlowRoute e
// TrainingRegistrationFlowRoute.
//
// Data: 18/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração da agenda semanal profissional, dos estados vazios e
// do menu flutuante para criação de planos, treinamentos e exercícios.
// Documentação da adaptação dos dados e das ações profissionais.
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de dependências, perfil e navegação;
// inclusão da trava que impede rotas duplicadas do cavalo por toques rápidos.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Sincronização do menu inferior ao sair do perfil do cavalo.
//
// Data: 10/11/2026 (perfil do cavalo)
// Autor: Noemi Kayama - RA 25004140
// Alteração: Navegação dos cards profissionais ao perfil do cavalo.
//
// Data: 12/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Aba Cavalos e Mostrar tudo abrem somente a callable listHorses,
// com a barra de navegação e Sidebar institucionais.
//
// Data: 13/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Correção da navegação para o Dashboard após atualização da developer;
// manutenção dos destinos tipados e remoção de estado duplicado.
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Ampliação da composição do perfil com os callbacks de upload de
// experiência/certificações, regiões e edição completa do perfil.
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração da aba de perfil do treinador com o repositório
// Firebase, carregamento dos dados e encerramento da sessão autenticada.
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de dependências, estado, carregamento e
// navegação da Home do treinador.
//
// Data: 04/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Ocultação do conteúdo da Home ao selecionar a área de perfil na
// navegação inferior e ajuste da formatação do carregador.
//
// Data: 27/10/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Atualização das importações de HomeAppBar, HomeBottomNavBar e
// TrainerSidebar movidos para core/widgets/.
//
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Movido para screens/trainer conforme arquitetura e injeção de HomeLoader.
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração ao mesmo fluxo de Repository/Service usado no Guardian,
// com Firebase por padrão e cenários mock explícitos para testes.
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação da Home do Profissional com AppBar e navegação
// compartilhadas, Sidebar exclusiva, Mock API e três cenários de testes.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/features/dashboard/dashboard_composition.dart';
import 'package:horse_life/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:horse_life/features/dashboard/presentation/screens/trainer/trainer_dashboard_screen.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/core/widgets/trainer_sidebar.dart';
import 'package:horse_life/features/authentication/application/states/trainer_document.dart';
import 'package:horse_life/features/authentication/application/states/trainer_service_area.dart';
import 'package:horse_life/features/authentication/data/repositories/brazilian_locations_repository.dart';
import 'package:horse_life/features/authentication/data/repositories/firebase_trainer_registration_repository.dart';
import 'package:horse_life/features/authentication/data/repositories/firebase_password_reset_repository.dart';
import 'package:horse_life/features/exercises/presentation/routes/exercise_registration_flow_route.dart';
import 'package:horse_life/features/profile/data/models/trainer_profile_data.dart';
import 'package:horse_life/features/list_horse/presentation/screens/professional/professional_horse_list_screen.dart';
import 'package:horse_life/features/profile/data/repositories/trainer_profile_repository.dart';
import 'package:horse_life/features/profile/presentation/screens/trainer_edit_profile_screen.dart';
import 'package:horse_life/features/profile/presentation/screens/trainer_profile_screen.dart';
import 'package:horse_life/features/profile/presentation/screens/trainer_experience_pdf_screen.dart';
import 'package:horse_life/features/horses/presentation/screens/horse_profile_screen.dart';
import 'package:horse_life/core/widgets/add_trainer_certifications_dialog.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';
import 'package:horse_life/features/training/data/repositories/training_agenda_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_execution_repository.dart';
import 'package:horse_life/features/training/presentation/screens/connected_training_agenda_screen.dart';
import 'package:horse_life/features/training/presentation/screens/training_agenda_screen.dart';
import 'package:horse_life/features/training/presentation/widgets/training_agenda_floating_menu.dart';
import 'package:horse_life/features/training_plans/data/models/training_plan_gallery_item.dart';
import 'package:horse_life/features/training_plans/data/repositories/firebase_training_plan_repository.dart';
import 'package:horse_life/features/training_plans/presentation/routes/training_plan_registration_flow_route.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_detail_screen.dart';
import 'package:horse_life/features/trainings/presentation/routes/training_registration_flow_route.dart';
import 'package:horse_life/features/trainings/presentation/screens/training_detail_screen.dart';
import '../../../application/controllers/home_loader.dart';
import '../../../data/models/trainer_home_data.dart';
import '../../../data/repositories/trainer_repository.dart';
import '../../../home_composition.dart';
import '../../widgets/trainer_home_content.dart';

/// Composição da Home do treinador e da aba de perfil.
///
/// Mantém instâncias de repositório sob demanda para que Firebase só seja
/// acessado depois do bootstrap executado pelo AppGate.
class TrainerHomeScreen extends StatefulWidget {
  const TrainerHomeScreen({
    super.key,
    required this.onLogout,
    this.mockScenario,
    this.loader,
    this.dashboardRepository,
    this.repository,
    this.onViewTraining,
    this.onSelectHorse,
    this.onSelectClient,
    this.onShowAllTrainings,
    this.onShowAllHorses,
    this.onShowAllClients,
    this.onNavigationSelected,
    this.trainerProfileLoader,
    this.onEditTrainerProfile,
    this.onViewExperience,
    this.onViewCertifications,
    this.onViewServiceRegions,
    this.experienceDocumentBuilder,
    this.experienceFilePicker,
    this.uploadTrainerExperience,
    this.certificationsFilePicker,
    this.certificationsFileSizeLoader,
    this.uploadTrainerCertification,
    this.locationsRepository =
        const CountryStateCityBrazilianLocationsRepository(),
    this.addTrainerServiceArea,
    this.updateTrainerProfile,
    this.requestTrainerPasswordReset,
    this.onViewPlans,
    this.onCreateTrainingPlan,
    this.onCreateTraining,
    this.onCreateExercise,
    this.agendaLoader,
    this.trainingExecutionLoader,
    this.trainingCompletionSubmitter,
  });

  // --- Fontes de dados -------------------------------------------------------
  /// `null` usa o Firebase; os demais cenários habilitam dados simulados.
  final String? mockScenario;

  /// Preferencialmente injetado pela raiz do aplicativo.
  final HomeLoader<TrainerHomeData>? loader;

  /// Fonte opcional para testes; no app usa Firebase.
  final DashboardRepository? dashboardRepository;

  /// Injeção opcional de repositório (por exemplo, em testes).
  final TrainerRepository? repository;

  /// Encerra a sessão autenticada.
  final Future<void> Function() onLogout;

  /// Abre o detalhe de um treino escolhido na Home.
  final ValueChanged<TrainerTraining>? onViewTraining;

  /// Abre o cavalo escolhido na Home.
  final ValueChanged<TrainerHorse>? onSelectHorse;

  /// Abre o cliente escolhido na Home.
  final ValueChanged<TrainerClient>? onSelectClient;

  /// Ações opcionais das listagens completas.
  final VoidCallback? onShowAllTrainings;
  final VoidCallback? onShowAllHorses;
  final VoidCallback? onShowAllClients;

  /// Notifica integrações externas sobre a troca da navegação inferior.
  final ValueChanged<int>? onNavigationSelected;

  /// Fonte alternativa do perfil usada por testes e composições específicas.
  final TrainerProfileLoader? trainerProfileLoader;
  final VoidCallback? onEditTrainerProfile;
  final VoidCallback? onViewExperience;
  final VoidCallback? onViewCertifications;
  final VoidCallback? onViewServiceRegions;

  /// Dependências opcionais encaminhadas ao fluxo documental do perfil.
  final ExperienceDocumentBuilder? experienceDocumentBuilder;
  final TrainerProfileExperienceFilePicker? experienceFilePicker;
  final TrainerExperienceUploader? uploadTrainerExperience;
  final TrainerProfileCertificationsFilePicker? certificationsFilePicker;
  final TrainerProfileFileSizeLoader? certificationsFileSizeLoader;
  final TrainerExperienceUploader? uploadTrainerCertification;

  /// Fonte de localidades e persistência de regiões encaminhadas ao perfil.
  final BrazilianLocationsRepository locationsRepository;
  final TrainerServiceAreaAdder? addTrainerServiceArea;
  final TrainerProfileUpdateHandler? updateTrainerProfile;
  final TrainerPasswordResetRequester? requestTrainerPasswordReset;

  // Ações exclusivas da agenda profissional.
  final VoidCallback? onViewPlans;
  final VoidCallback? onCreateTrainingPlan;
  final VoidCallback? onCreateTraining;
  final VoidCallback? onCreateExercise;

  /// Fonte da agenda completa. Quando ausente, mantém a adaptação dos dados da
  /// Home usada pelos cenários legados e pelos testes existentes.
  final TrainingAgendaLoader? agendaLoader;

  /// Carrega os detalhes do treino consultado a partir da agenda.
  final TrainingExecutionLoader? trainingExecutionLoader;

  /// Envia ao backend os dados preenchidos ao concluir uma execução.
  final TrainingCompletionSubmitter? trainingCompletionSubmitter;

  @override
  State<TrainerHomeScreen> createState() => _TrainerHomeScreenState();
}

class _TrainerHomeScreenState extends State<TrainerHomeScreen> {
  // --- Estado compartilhado --------------------------------------------------
  late Future<TrainerHomeData> _homeFuture;
  HomeNavigationDestination _selectedDestination =
      HomeNavigationDestination.home;

  late HomeLoader<TrainerHomeData> _loader;
  bool _isOpeningHorseProfile = false;
  bool _isOpeningTrainingDetails = false;
  FirebaseTrainerProfileRepository? _trainerProfileRepository;
  FirebaseTrainerRegistrationRepository? _trainerAttachmentRepository;
  FirebasePasswordResetRepository? _passwordResetRepository;

  /// A sidebar e o conteúdo usam uma única Future, evitando chamadas duplicadas.
  Future<TrainerHomeData> _fetchHome() => _loader.fetchHome();

  /// Usa o mesmo detalhe para cards da Home e do perfil profissional.
  Future<void> _openHorseProfile(String id) async {
    if (_isOpeningHorseProfile) return;
    _isOpeningHorseProfile = true;

    try {
      final destination = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute<dynamic>(
          builder: (_) => HorseProfileScreen(
            horseId: id,
            currentUserId: FirebaseAuth.instance.currentUser?.uid,
            isTrainer: true,
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _homeFuture = _fetchHome();
      });
      if (destination is HomeNavigationDestination) {
        _onNavigationDestination(destination);
      }
    } finally {
      _isOpeningHorseProfile = false;
    }
  }

  /// Resolve os dados reais do treinamento no backend via galeria quando a
  /// navegação fornece apenas o ID do registro da agenda/home.
  Future<TrainingPlanGalleryItem?> _resolveRealTrainingFromBackend({
    required String title,
    String? horseName,
  }) async {
    final home = await _homeFuture;
    if (home.horses.isEmpty) return null;

    final normalizedHorse = horseName?.trim().toLowerCase() ?? '';
    String horseId = home.horses.first.id;
    if (normalizedHorse.isNotEmpty) {
      for (final horse in home.horses) {
        if (horse.name.trim().toLowerCase() == normalizedHorse) {
          horseId = horse.id;
          break;
        }
      }
    }

    final items = await const FirebaseTrainingPlanRepository()
        .fetchTrainingGallery(horseId: horseId, searchQuery: title);
    if (items.isEmpty) return null;

    final normalizedTitle = title.trim().toLowerCase();
    for (final item in items) {
      if (item.title.trim().toLowerCase() == normalizedTitle) {
        return item;
      }
    }
    return items.length == 1 ? items.first : null;
  }

  /// Abre a visualização completa do treinamento selecionado na Home ou Agenda.
  Future<void> _openTrainingDetails(
    String id, {
    String? title,
    String? horseName,
    int? code,
    int? estimatedDurationMinutes,
  }) async {
    if (_isOpeningTrainingDetails) return;
    _isOpeningTrainingDetails = true;

    try {
      final parsedIdCode = int.tryParse(id);
      String effectiveCode;
      TrainingPlanGalleryItem? initialTraining;

      if (code != null && code > 0) {
        effectiveCode = code.toString();
        if (title != null) {
          initialTraining = TrainingPlanGalleryItem(
            id: id,
            code: code,
            title: title,
            estimatedDurationMinutes: estimatedDurationMinutes ?? 0,
          );
        }
      } else if (parsedIdCode != null && parsedIdCode > 0) {
        effectiveCode = id;
        if (title != null) {
          initialTraining = TrainingPlanGalleryItem(
            id: id,
            code: parsedIdCode,
            title: title,
            estimatedDurationMinutes: estimatedDurationMinutes ?? 0,
          );
        }
      } else if (widget.mockScenario == null) {
        String? resolvedCode;
        TrainingPlanGalleryItem? resolvedItem;

        // 1. Tenta resolver o código numérico pelo ID do registro via getTrainingRecord
        try {
          final recordCall = FirebaseFunctions.instanceFor(
            region: 'southamerica-east1',
          ).httpsCallable('getTrainingRecord');
          final response = await recordCall.call<dynamic>({'registroId': id});
          final data = response.data;
          if (data is Map && data['treinamento'] is Map) {
            final raw = data['treinamento']['codigo']?.toString().trim();
            if (raw != null && raw.isNotEmpty && int.tryParse(raw) != null) {
              resolvedCode = raw;
              final tTitle =
                  data['treinamento']['titulo']?.toString() ?? title ?? '';
              final tDuration =
                  data['treinamento']['duracaoEstimada'] as int? ??
                  estimatedDurationMinutes ??
                  0;
              resolvedItem = TrainingPlanGalleryItem(
                id: id,
                code: int.parse(raw),
                title: tTitle,
                estimatedDurationMinutes: tDuration,
              );
            }
          }
        } catch (_) {}

        // 2. Se não resolveu pelo registro e temos título, tenta galeria como fallback
        if (resolvedCode == null && title != null && title.trim().isNotEmpty) {
          try {
            final galleryResolved = await _resolveRealTrainingFromBackend(
              title: title,
              horseName: horseName,
            );
            if (galleryResolved != null && galleryResolved.code > 0) {
              resolvedCode = galleryResolved.code.toString();
              resolvedItem = galleryResolved;
            }
          } catch (_) {}
        }

        if (resolvedCode != null) {
          effectiveCode = resolvedCode;
          initialTraining = resolvedItem;
        } else {
          effectiveCode = id;
          if (title != null) {
            initialTraining = TrainingPlanGalleryItem(
              id: id,
              code: 0,
              title: title,
              estimatedDurationMinutes: estimatedDurationMinutes ?? 0,
            );
          }
        }
      } else {
        effectiveCode = id;
        if (title != null) {
          initialTraining = TrainingPlanGalleryItem(
            id: id,
            code: 0,
            title: title,
            estimatedDurationMinutes: estimatedDurationMinutes ?? 0,
          );
        }
      }

      if (!mounted) return;
      final destination = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute<dynamic>(
          builder: (_) => TrainingDetailScreen(
            trainingCode: effectiveCode,
            initialTraining: initialTraining,
            currentUserId: FirebaseAuth.instance.currentUser?.uid,
            isTrainer: true,
            isOwner: true,
            onNavigationSelected: (dest) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(dest);
              }
            },
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _homeFuture = _fetchHome();
      });
      if (destination is HomeNavigationDestination) {
        _onNavigationDestination(destination);
      }
    } finally {
      _isOpeningTrainingDetails = false;
    }
  }

  /// Abre a visualização completa de um plano de treinamento a partir da Agenda.
  Future<void> _openTrainingPlanDetails(String planId) async {
    if (_isOpeningTrainingDetails) return;
    _isOpeningTrainingDetails = true;

    try {
      final destination = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute<dynamic>(
          builder: (_) => TrainingPlanDetailScreen(
            planId: planId,
            currentUserId: FirebaseAuth.instance.currentUser?.uid,
            isTrainer: true,
            onNavigationSelected: (dest) {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop(dest);
              }
            },
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        _homeFuture = _fetchHome();
      });
      if (destination is HomeNavigationDestination) {
        _onNavigationDestination(destination);
      }
    } finally {
      _isOpeningTrainingDetails = false;
    }
  }

  void _handleViewTraining(TrainerTraining training) {
    if (widget.onViewTraining != null) {
      widget.onViewTraining!(training);
    } else {
      _openTrainingDetails(
        training.id,
        title: training.title,
        horseName: training.horseName,
      );
    }
  }

  Future<TrainerProfileData> _fetchTrainerProfile() {
    final injectedLoader = widget.trainerProfileLoader;
    if (injectedLoader != null) return injectedLoader();
    _trainerProfileRepository ??= FirebaseTrainerProfileRepository();
    return _trainerProfileRepository!.getTrainerProfile();
  }

  Future<void> _uploadTrainerExperience(TrainerDocument document) {
    final injectedUploader = widget.uploadTrainerExperience;
    if (injectedUploader != null) return injectedUploader(document);
    _trainerAttachmentRepository ??=
        const FirebaseTrainerRegistrationRepository();
    return _trainerAttachmentRepository!.uploadTrainerAttachment(
      TrainerAttachmentType.experience,
      document,
    );
  }

  Future<void> _uploadTrainerCertification(TrainerDocument document) {
    final injectedUploader = widget.uploadTrainerCertification;
    if (injectedUploader != null) return injectedUploader(document);
    _trainerAttachmentRepository ??=
        const FirebaseTrainerRegistrationRepository();
    return _trainerAttachmentRepository!.uploadTrainerAttachment(
      TrainerAttachmentType.certification,
      document,
    );
  }

  Future<void> _addTrainerServiceArea(TrainerServiceArea area) {
    final injectedAdder = widget.addTrainerServiceArea;
    if (injectedAdder != null) return injectedAdder(area);
    _trainerProfileRepository ??= FirebaseTrainerProfileRepository();
    return _trainerProfileRepository!.addServiceArea(area);
  }

  Future<void> _updateTrainerProfile(TrainerProfileUpdate update) {
    final injectedUpdater = widget.updateTrainerProfile;
    if (injectedUpdater != null) return injectedUpdater(update);
    _trainerProfileRepository ??= FirebaseTrainerProfileRepository();
    return _trainerProfileRepository!.updateTrainerProfile(update);
  }

  Future<String> _requestTrainerPasswordReset(String email) {
    final injectedRequester = widget.requestTrainerPasswordReset;
    if (injectedRequester != null) return injectedRequester(email);
    _passwordResetRepository ??= const FirebasePasswordResetRepository();
    return _passwordResetRepository!.requestPasswordReset(email: email);
  }

  void _configureLoader() {
    _loader =
        widget.loader ??
        HomeComposition.trainer(
          mockScenario: widget.mockScenario,
          repository: widget.repository,
        );
  }

  @override
  void initState() {
    super.initState();
    _configureLoader();
    _homeFuture = _fetchHome();
  }

  /// Substitui a Future armazenada para executar uma nova tentativa.
  void _retry() {
    setState(() {
      _homeFuture = _fetchHome();
    });
  }

  void _openExerciseCreation() {
    // Exercícios já possuem fluxo próprio e podem ser abertos diretamente.
    Navigator.of(context).push(ExerciseRegistrationFlowRoute.build());
  }

  void _openTrainingCreation() {
    Navigator.of(context).push(TrainingRegistrationFlowRoute.build());
  }

  void _openTrainingPlanCreation() {
    Navigator.of(context).push(TrainingPlanRegistrationFlowRoute.build());
  }

  @override
  void didUpdateWidget(covariant TrainerHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mockScenario != oldWidget.mockScenario ||
        widget.repository != oldWidget.repository ||
        widget.loader != oldWidget.loader) {
      _configureLoader();
      _homeFuture = _fetchHome();
    }
  }

  // Prioriza a resposta completa da agenda quando disponível e converte cada
  // item consultado para o modelo que a Home já expõe aos seus consumidores.
  Widget _buildTrainingAgenda() {
    final agendaLoader = widget.agendaLoader;
    if (agendaLoader != null) {
      return ConnectedTrainingAgendaScreen(
        loader: agendaLoader,
        executionLoader: widget.trainingExecutionLoader,
        completionSubmitter: widget.trainingCompletionSubmitter,
        onViewPlans: widget.onViewPlans,
        onViewPlan: (plan) {
          if (widget.onViewPlans != null) {
            widget.onViewPlans!();
          } else {
            _openTrainingPlanDetails(plan.id);
          }
        },
        onViewTraining: (entry) => _handleViewTraining(
          TrainerTraining(
            id: entry.id,
            title: entry.title,
            horseName: entry.horseName,
            planName: entry.planName,
            status: trainingAgendaStatusToApi(entry.status),
          ),
        ),
        onViewHistory: (entry) => _handleViewTraining(
          TrainerTraining(
            id: entry.id,
            title: entry.title,
            horseName: entry.horseName,
            planName: entry.planName,
            status: trainingAgendaStatusToApi(entry.status),
          ),
        ),
      );
    }
    // Converte o resumo retornado pela Home nos contratos reutilizáveis da
    // agenda, preservando os modelos originais para os callbacks externos.
    return FutureBuilder<TrainerHomeData>(
      future: _homeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: TextButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          );
        }

        final home = snapshot.data!;
        final today = DateTime.now();
        final activeTodayTrainings = home.todayTrainings
            .where((training) => training.status != 'CANCELADO')
            .toList(growable: false);
        final entries = activeTodayTrainings
            .map(
              (training) => TrainingAgendaEntry(
                id: training.id,
                title: training.title,
                horseName: training.horseName,
                trainerName: home.trainerName,
                planName: training.planName,
                date: today,
                durationMinutes: 0,
                status: trainingAgendaStatusFromApi(training.status),
                action: TrainingAgendaAction.view,
              ),
            )
            .toList(growable: false);

        final plansByKey = <String, TrainingAgendaPlan>{};
        // Agrupa treinos por plano e cavalo, pois a Home não retorna os planos
        // como uma lista independente.
        for (final training in activeTodayTrainings) {
          final key = training.id;
          plansByKey.putIfAbsent(
            key,
            () => TrainingAgendaPlan(
              id: key,
              trainingName: training.title,
              horseName: training.horseName,
              trainerName: home.trainerName,
              planName: training.planName,
              date: today,
              status: trainingAgendaStatusFromApi(training.status),
            ),
          );
        }

        TrainerTraining? sourceFor(TrainingAgendaEntry entry) {
          // Resolve o item adaptado de volta ao modelo exposto pela Home.
          for (final training in activeTodayTrainings) {
            if (training.id == entry.id) return training;
          }
          return null;
        }

        void viewEntry(TrainingAgendaEntry entry) {
          final training = sourceFor(entry);
          if (training != null) {
            _handleViewTraining(training);
          } else {
            _openTrainingDetails(
              entry.id,
              title: entry.title,
              horseName: entry.horseName,
            );
          }
        }

        return TrainingAgendaScreen(
          audience: TrainingAgendaAudience.trainer,
          activePlansCount: home.activePlans ?? plansByKey.length,
          plans: plansByKey.values.toList(growable: false),
          trainings: entries,
          onViewPlans: widget.onViewPlans,
          onViewPlan: (plan) {
            if (widget.onViewPlans != null) {
              widget.onViewPlans!();
            } else {
              _openTrainingPlanDetails(plan.id);
            }
          },
          onViewTraining: viewEntry,
          onViewHistory: viewEntry,
        );
      },
    );
  }

  /// Treinador consulta cavalos vinculados; cadastro segue exclusivo do responsável.
  Future<void> _openHorseList() async {
    final destination = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (listContext) => ProfessionalHorseListScreen(
          appBar: const HomeAppBar(),
          drawer: TrainerSidebar(
            onLogout: widget.onLogout,
            homeFuture: _homeFuture,
          ),
          bottomNavigationBar: HomeBottomNavBar(
            selectedDestination: HomeNavigationDestination.horses,
            onDestinationSelected: (selected) {
              if (selected != HomeNavigationDestination.horses) {
                Navigator.of(listContext).pop(selected);
              }
            },
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _homeFuture = _fetchHome();
    });
    if (destination is HomeNavigationDestination) {
      _onNavigationDestination(destination);
    }
  }

  void _onNavigationDestination(HomeNavigationDestination destination) {
    if (destination == HomeNavigationDestination.horses) {
      widget.onNavigationSelected?.call(destination.index);
      _openHorseList();
    } else if (destination == HomeNavigationDestination.dashboard) {
      widget.onNavigationSelected?.call(destination.index);
      _openDashboard();
    } else {
      setState(() => _selectedDestination = destination);
      widget.onNavigationSelected?.call(destination.index);
    }
  }

  // --- Composição visual e navegação ----------------------------------------
  // Abre o painel do perfil sem alterar o destino atual da Home.
  // Ao voltar, os dados já carregados da Home continuam disponíveis.
  Future<void> _openDashboard() async {
    final destination = await Navigator.of(context)
        .push<HomeNavigationDestination>(
          MaterialPageRoute<HomeNavigationDestination>(
            builder: (dashboardContext) => TrainerDashboardScreen(
              onLogout: widget.onLogout,
              onHome: () => Navigator.of(dashboardContext).pop(),
              onNavigationSelected: (selected) {
                Navigator.of(dashboardContext).pop(selected);
              },
              homeFuture: _homeFuture,
              repository:
                  widget.dashboardRepository ??
                  DashboardComposition.production(),
            ),
          ),
        );
    if (!mounted || destination == null) return;
    _onNavigationDestination(destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const HomeAppBar(),
      drawer: TrainerSidebar(
        onLogout: widget.onLogout,
        homeFuture: _homeFuture,
      ),
      body: switch (_selectedDestination) {
        HomeNavigationDestination.profile => TrainerProfileScreen(
          loadTrainerProfile: _fetchTrainerProfile,
          onLogout: widget.onLogout,
          onEditTrainerProfile: widget.onEditTrainerProfile,
          onViewExperience: widget.onViewExperience,
          onViewCertifications: widget.onViewCertifications,
          onViewServiceRegions: widget.onViewServiceRegions,
          onShowAllHorses: widget.onShowAllHorses,
          experienceDocumentBuilder: widget.experienceDocumentBuilder,
          experienceFilePicker: widget.experienceFilePicker,
          uploadTrainerExperience: _uploadTrainerExperience,
          certificationsFilePicker: widget.certificationsFilePicker,
          certificationsFileSizeLoader: widget.certificationsFileSizeLoader,
          uploadTrainerCertification: _uploadTrainerCertification,
          locationsRepository: widget.locationsRepository,
          addTrainerServiceArea: _addTrainerServiceArea,
          updateTrainerProfile: _updateTrainerProfile,
          requestPasswordReset: _requestTrainerPasswordReset,
          onSelectHorse: _openHorseProfile,
        ),
        HomeNavigationDestination.trainings => _buildTrainingAgenda(),
        _ => TrainerHomeContent(
          homeFuture: _homeFuture,
          onRetry: _retry,
          onViewTraining: _handleViewTraining,
          onSelectHorse:
              widget.onSelectHorse ?? (horse) => _openHorseProfile(horse.id),
          onSelectClient: widget.onSelectClient,
          onShowAllTrainings: widget.onShowAllTrainings,
          onShowAllHorses: widget.onShowAllHorses,
          onShowAllClients: widget.onShowAllClients,
        ),
      },
      floatingActionButton:
          _selectedDestination == HomeNavigationDestination.trainings
          ? TrainingAgendaFloatingMenu(
              onCreatePlan:
                  widget.onCreateTrainingPlan ?? _openTrainingPlanCreation,
              onCreateTraining:
                  widget.onCreateTraining ?? _openTrainingCreation,
              onCreateExercise:
                  widget.onCreateExercise ?? _openExerciseCreation,
            )
          : null,
      bottomNavigationBar: HomeBottomNavBar(
        selectedDestination: _selectedDestination,
        onDestinationSelected: (destination) {
          if (destination == HomeNavigationDestination.dashboard) {
            _openDashboard();
            return;
          }
          _onNavigationDestination(destination);
        },
      ),
    );
  }
}
