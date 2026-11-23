// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Vinculação de onShowAllHorses na Home do responsável para abrir a
// listagem de cavalos (_openHorseList).
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Correção do recarregamento síncrono da Home após o perfil e a
// lista de cavalos; inclusão de conteúdo injetável para testes da navegação.
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Auditoria e correção dos comentários da integração da agenda, com
// documentação das dependências usadas para consultar e finalizar treinos.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Correção e detalhamento da documentação do fluxo conectado da
// agenda e da adaptação dos callbacks legados do responsável. Encaminhamento
// das dependências necessárias para abrir e finalizar a execução do treino.
//
// Data: 20/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Conexão opcional da agenda do responsável ao backend, com
// adaptação dos treinos retornados para as ações já expostas pela Home.
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Atualização de _homeFuture ao retornar do perfil de cavalos e da
// listagem, e filtragem de treinos cancelados na montagem da agenda.
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Correção da navegação da barra inferior para chamar _onNavigationDestination,
// permitindo acesso à listagem de cavalos, e repasse do callback ao Dashboard.
//
// Data: 18/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração da agenda semanal do responsável à navegação inferior,
// com precedência do vínculo de atleta, planos ativos e ações de treino.
// Documentação do carregamento, adaptação e ações da nova agenda.
//
// Data: 18/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Encaminhamento do callback de cadastro à Sidebar da Home,
// permitindo navegação injetável em testes sem mudar o Firebase de produção.
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de carregamento, navegação e composição;
// inclusão da trava que impede rotas duplicadas do perfil por toques rápidos.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Sincronização do menu inferior ao sair do perfil do cavalo.
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Correção da nova tentativa da Home para manter o callback de
// setState síncrono após o cadastro de um cavalo.
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Navegação dos cards da Home e do perfil ao detalhe do cavalo.
//
// Data: 15/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Corrige a declaração da Future compartilhada, compatibilidade
// da listagem com o cadastro modular e navegação dos cavalos.
//
// Data: 12/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Navegação para a listagem de cavalos, com cadastro reaproveitado
// de features/horses e sincronização após retorno do cadastro.
//
// Data: 15/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Restauração da Future da Home após o merge e correção da
// atualização assíncrona de estado no recarregamento.
//
// Data: 13/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Correção da navegação para o Dashboard após atualização da developer;
// manutenção dos destinos tipados e remoção de estado duplicado.
//
// Data: 10/11/2026 (organização após integração)
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Organização dos imports e comentários; integração do botão
// de cadastro também no estado vazio do perfil do responsável.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Cadastro de cavalos aberto pela rota da feature, sem acoplamento
// às etapas do formulário.
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Migração do estado da navegação inferior de índice numérico para
// HomeNavigationDestination, preservando o acesso ao perfil do responsável.
//
// Data: 06/11/2026 (cadastro real)
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Home recebe cavalo persistido pela Function registerHorse e
// atualiza getHome; repositório mock permanece apenas em cenários de teste.
//
// Data: 06/11/2026 (correção pós-testes móveis)
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Finalização do fluxo de cadastro sem recarregar a Home com dados
// remotos após um registro simulado; cavalo aparece apenas na sessão local.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Abertura da feature de cadastro de cavalos pela Home,
// preservando extensão futura para o perfil e outras telas.
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de estado, carregamento, edição de perfil
// e composição da interface.
//
// Data: 04/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração da tela de edição do perfil, com controlador para
// atualização dos dados e solicitação de redefinição de senha.
//
// Data: 30/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do carregamento e das ações do perfil do responsável.
//
// Data: 28/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração do perfil do responsável à navegação inferior, com
// carregamento real ou injetável e ações externas de perfil e cavalos.
//
// Data: 27/10/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Atualização das importações de HomeAppBar, HomeBottomNavBar e
// GuardianSidebar movidos para core/widgets/.
//
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Injeção de HomeLoader; acesso a Firebase saiu da screen.
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do GuardianRepository e dos modelos com as Cloud
// Functions; documentação das responsabilidades e lógicas principais,
// preservando o comportamento anterior da interface.
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão de compatibilidade da Home com os cards e cenários
// simulados; estrutura e comportamentos existentes preservados.
//
// Data: 13/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação da estrutura inicial da Home do Responsável,
// seguindo a arquitetura e os padrões visuais oficiais do HorseLife.
// -----------------------------------------------------------------------------

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/features/dashboard/dashboard_composition.dart';
import 'package:horse_life/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:horse_life/features/dashboard/presentation/screens/guardian/guardian_dashboard_screen.dart';

import 'package:horse_life/core/widgets/guardian_sidebar.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/features/authentication/data/repositories/firebase_password_reset_repository.dart';
import 'package:horse_life/features/horses/data/repositories/horse_registration_repository.dart';
import 'package:horse_life/features/horses/presentation/routes/horse_registration_flow_route.dart';
import 'package:horse_life/features/horses/presentation/screens/horse_profile_screen.dart';
import 'package:horse_life/features/profile/application/controllers/guardian_profile_controller.dart';
import 'package:horse_life/features/list_horse/presentation/screens/guardian/guardian_horse_list_screen.dart';
import 'package:horse_life/features/profile/data/models/guardian_profile_data.dart';
import 'package:horse_life/features/profile/data/repositories/guardian_profile_repository.dart';
import 'package:horse_life/features/profile/presentation/screens/guardian_profile_edit_screen.dart';
import 'package:horse_life/features/profile/presentation/screens/guardian_profile_screen.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';
import 'package:horse_life/features/training/data/repositories/training_agenda_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_execution_repository.dart';
import 'package:horse_life/features/training/presentation/screens/connected_training_agenda_screen.dart';
import 'package:horse_life/features/training/presentation/screens/training_agenda_screen.dart';

import '../../../application/controllers/home_loader.dart';
import '../../../data/models/guardian_home_data.dart';
import '../../../home_composition.dart';
import '../../widgets/guardian_home_content.dart';

/// Coordena os dados e a navegação da Home do responsável.
///
/// A mesma Future alimenta o conteúdo e a barra lateral, evitando buscas
/// duplicadas durante a reconstrução da tela.
class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({
    required this.onLogout,
    this.mockScenario,
    this.loader,
    this.dashboardRepository,
    this.onRegisterHorse,
    this.horseRegistrationRepository,
    this.guardianProfileLoader,
    this.onEditGuardianProfile,
    this.onShowAllGuardianHorses,
    this.onStartTraining,
    this.onViewTraining,
    this.onViewPlans,
    this.agendaLoader,
    this.trainingExecutionLoader,
    this.trainingCompletionSubmitter,
    this.horseListBuilder,
    super.key,
  });

  // Use normal, empty ou completed nos testes. Null usa os dados reais.
  final String? mockScenario;

  /// Carregador da Home. Quando ausente, usa a composição padrão.
  final HomeLoader<GuardianHomeData>? loader;

  /// Fonte opcional para testes; no app usa Firebase.
  final DashboardRepository? dashboardRepository;

  // Permite que a aplicação forneça outra rota para o cadastro de cavalos.
  final VoidCallback? onRegisterHorse;

  /// Repositório opcional para testes; normalmente, usa Firebase.
  /// Se mockScenario estiver ativo, utiliza o repositório simulado.
  final HorseRegistrationRepository? horseRegistrationRepository;

  /// Fonte injetável do perfil, usada principalmente em testes e composições.
  final GuardianProfileLoader? guardianProfileLoader;

  /// Ações de navegação disponibilizadas pela tela de perfil.
  final VoidCallback? onEditGuardianProfile;
  final VoidCallback? onShowAllGuardianHorses;

  // Ações legadas da Home. A agenda conectada adapta seus contratos antes de
  // encaminhar um treino para esses callbacks.
  final ValueChanged<GuardianTraining>? onStartTraining;
  final ValueChanged<GuardianTraining>? onViewTraining;
  final VoidCallback? onViewPlans;

  /// Fonte da agenda completa. Ausente mantém a adaptação legada para testes.
  final TrainingAgendaLoader? agendaLoader;

  /// Carrega os detalhes do treino selecionado na agenda conectada.
  final TrainingExecutionLoader? trainingExecutionLoader;

  /// Persiste o formulário preenchido após a execução ativa.
  final TrainingCompletionSubmitter? trainingCompletionSubmitter;

  /// Substitui somente o conteúdo da rota de cavalos em testes de navegação.
  final WidgetBuilder? horseListBuilder;

  // A operação de logout é recebida externamente.
  final Future<void> Function() onLogout;

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  // A fonte real é usada por padrão; cenários mock ficam restritos aos testes.

  // Estado local da navegação inferior.
  HomeNavigationDestination _selectedDestination =
      HomeNavigationDestination.home;
  late Future<GuardianHomeData> _homeFuture;

  // Cadastro mockado não muda o backend; mantém os nomes visíveis só na sessão.
  final List<String> _sessionMockHorses = [];
  late HomeLoader<GuardianHomeData> _loader;
  bool _isOpeningHorseProfile = false;

  // O repositório é criado sob demanda e reutilizado no carregamento e edição.
  FirebaseGuardianProfileRepository? _guardianProfileRepository;
  Future<GuardianProfileData>? _agendaProfileFuture;

  FirebaseGuardianProfileRepository get _profileRepository =>
      _guardianProfileRepository ??= const FirebaseGuardianProfileRepository();

  // --- Carregamento da Home e do perfil -------------------------------------
  Future<GuardianHomeData> _fetchHome() => _loader.fetchHome();

  /// Abre o detalhe remoto a partir de qualquer card que preserve o id.
  Future<void> _openHorseProfile(String id) async {
    if (_isOpeningHorseProfile) return;
    _isOpeningHorseProfile = true;

    try {
      final destination = await Navigator.of(context).push<dynamic>(
        MaterialPageRoute<dynamic>(
          builder: (_) => HorseProfileScreen(
            horseId: id,
            currentUserId: FirebaseAuth.instance.currentUser?.uid,
            isTrainer: false,
          ),
        ),
      );
      if (!mounted) return;
      // A nova consulta é criada antes do setState para que o callback apenas
      // substitua o estado e nunca devolva uma Future ao framework.
      final refreshedHome = _fetchHome();
      setState(() {
        _homeFuture = refreshedHome;
      });
      if (destination is HomeNavigationDestination) {
        _onNavigationDestination(destination);
      }
    } finally {
      _isOpeningHorseProfile = false;
    }
  }

  // Prioriza a fonte injetada; na aplicação, consulta o Firebase.
  Future<GuardianProfileData> _fetchGuardianProfile() {
    final injectedLoader = widget.guardianProfileLoader;
    if (injectedLoader != null) return injectedLoader();
    return _profileRepository.getGuardianProfile();
  }

  Future<GuardianProfileData> _fetchAgendaProfile() {
    // Compartilha a mesma consulta enquanto a tela estiver montada para evitar
    // uma nova leitura do perfil a cada reconstrução da aba de treinos.
    return _agendaProfileFuture ??= _fetchGuardianProfile();
  }

  // --- Fluxo de edição -------------------------------------------------------
  // Abre o formulário com o perfil já carregado e informa se houve alteração.
  Future<bool> _openGuardianProfileEditor(GuardianProfileData profile) async {
    final wasUpdated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => GuardianProfileEditScreen(
          profile: profile,
          controller: GuardianProfileController(
            profileRepository: _profileRepository,
            passwordResetRepository: const FirebasePasswordResetRepository(),
          ),
        ),
      ),
    );
    return wasUpdated ?? false;
  }

  // --- Ciclo de vida do carregador ------------------------------------------
  void _configureLoader() {
    _loader =
        widget.loader ??
        HomeComposition.guardian(mockScenario: widget.mockScenario);
  }

  /// Cadastro real pela rota já existente de features/horses.
  Future<void> _openRegisterHorse() async {
    final result = await Navigator.of(
      context,
    ).push<HorseRegistrationResult>(HorseRegistrationFlowRoute.build());
    if (!mounted || result == null) return;
    if (!result.isPersisted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('O cadastro não foi confirmado pelo servidor.'),
        ),
      );
      return;
    }
    _retryHome();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.warning ?? 'Cadastro de ${result.name} concluído!',
        ),
      ),
    );
  }

  /// Refaz a consulta da Home após uma falha apresentada ao usuário.
  void _retryHome() {
    final homeFuture = _fetchHome();
    setState(() {
      _homeFuture = homeFuture;
    });
  }

  @override
  void initState() {
    super.initState();
    _configureLoader();
    _homeFuture = _fetchHome();
  }

  @override
  void didUpdateWidget(covariant GuardianHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mockScenario != widget.mockScenario ||
        oldWidget.loader != widget.loader ||
        oldWidget.guardianProfileLoader != widget.guardianProfileLoader) {
      _configureLoader();
      _homeFuture = _fetchHome();
      _agendaProfileFuture = null;
    }
  }

  // Usa a agenda completa quando o carregador foi injetado. A adaptação local
  // preserva a API pública da Home para os fluxos de iniciar e consultar treino.
  Widget _buildTrainingAgenda() {
    final agendaLoader = widget.agendaLoader;
    if (agendaLoader != null) {
      GuardianTraining toGuardianTraining(TrainingAgendaEntry entry) =>
          GuardianTraining(
            title: entry.title,
            horseName: entry.horseName,
            trainerName: entry.trainerName,
            durationMinutes: entry.durationMinutes,
            planName: entry.planName,
            recordId: entry.id,
            status: trainingAgendaStatusToApi(entry.status),
          );
      return ConnectedTrainingAgendaScreen(
        loader: agendaLoader,
        executionLoader: widget.trainingExecutionLoader,
        completionSubmitter: widget.trainingCompletionSubmitter,
        onViewPlans: widget.onViewPlans,
        onStartTraining: widget.onStartTraining == null
            ? null
            : (entry) => widget.onStartTraining!(toGuardianTraining(entry)),
        onViewTraining: widget.onViewTraining == null
            ? null
            : (entry) => widget.onViewTraining!(toGuardianTraining(entry)),
        onViewHistory: widget.onViewTraining == null
            ? null
            : (entry) => widget.onViewTraining!(toGuardianTraining(entry)),
      );
    }
    // A Home fornece os treinos, enquanto o perfil determina se o vínculo com
    // cada cavalo permite iniciar a execução ou somente consultar o treino.
    return FutureBuilder<GuardianHomeData>(
      future: _homeFuture,
      builder: (context, homeSnapshot) {
        if (homeSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (homeSnapshot.hasError || !homeSnapshot.hasData) {
          return Center(
            child: TextButton.icon(
              onPressed: _retryHome,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          );
        }

        return FutureBuilder<GuardianProfileData>(
          future: _fetchAgendaProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            // Em uma falha isolada do perfil, a agenda continua disponível no
            // modo seguro de proprietário: somente visualização.
            final athleteHorses =
                profileSnapshot.data?.horses
                    .where(
                      (horse) =>
                          horse.relationship.toLowerCase().contains('atleta'),
                    )
                    .map((horse) => horse.name)
                    .toSet() ??
                <String>{};
            final home = homeSnapshot.data!;
            final today = DateTime.now();
            final activeTodayTrainings = home.todayTrainings
                .where((training) => training.status != 'CANCELADO')
                .toList(growable: false);
            final entries = activeTodayTrainings
                .map(
                  (training) => TrainingAgendaEntry(
                    id:
                        training.recordId ??
                        '${training.planName}:${training.horseName}',
                    title: training.title,
                    horseName: training.horseName,
                    trainerName: training.trainerName,
                    planName: training.planName,
                    date: today,
                    durationMinutes: training.durationMinutes,
                    status: trainingAgendaStatusFromApi(training.status),
                    action: athleteHorses.contains(training.horseName)
                        ? TrainingAgendaAction.start
                        : TrainingAgendaAction.view,
                  ),
                )
                .toList(growable: false);

            final plansByKey = <String, TrainingAgendaPlan>{};
            // O resumo da Home não possui uma coleção própria de planos. A
            // chave composta elimina repetições entre treinos do mesmo plano.
            for (final training in activeTodayTrainings) {
              final key = '${training.planName}:${training.horseName}';
              plansByKey.putIfAbsent(
                key,
                () => TrainingAgendaPlan(
                  id: key,
                  trainingName: training.title,
                  horseName: training.horseName,
                  trainerName: training.trainerName,
                  planName: training.planName,
                  date: today,
                  status: trainingAgendaStatusFromApi(training.status),
                ),
              );
            }

            GuardianTraining? sourceFor(TrainingAgendaEntry entry) {
              // Recupera o contrato original esperado pelos callbacks da Home.
              for (final training in activeTodayTrainings) {
                final id =
                    training.recordId ??
                    '${training.planName}:${training.horseName}';
                if (id == entry.id) return training;
              }
              return null;
            }

            return TrainingAgendaScreen(
              activePlansCount: plansByKey.length,
              plans: plansByKey.values.toList(growable: false),
              trainings: entries,
              onViewPlans: widget.onViewPlans,
              onStartTraining: widget.onStartTraining == null
                  ? null
                  : (entry) {
                      final training = sourceFor(entry);
                      if (training != null) widget.onStartTraining!(training);
                    },
              onViewTraining: widget.onViewTraining == null
                  ? null
                  : (entry) {
                      final training = sourceFor(entry);
                      if (training != null) widget.onViewTraining!(training);
                    },
              onViewHistory: widget.onViewTraining == null
                  ? null
                  : (entry) {
                      final training = sourceFor(entry);
                      if (training != null) widget.onViewTraining!(training);
                    },
            );
          },
        );
      },
    );
  }

  /// Listagem autenticada exclusivamente pela callable listHorses.
  Future<void> _openHorseList() async {
    final destination = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (listContext) =>
            widget.horseListBuilder?.call(listContext) ??
            GuardianHorseListScreen(
              onRegistrationCompleted: (result) {
                if (mounted && result.isPersisted) _retryHome();
              },
              appBar: const HomeAppBar(),
              drawer: GuardianSidebar(
                onLogout: widget.onLogout,
                homeFuture: _homeFuture,
                // Reutiliza o cadastro real e atualiza a Home ao retornar.
                onRegisterHorse: widget.onRegisterHorse ?? _openRegisterHorse,
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
    // Mantém a criação assíncrona fora do callback síncrono de setState.
    final refreshedHome = _fetchHome();
    setState(() {
      _homeFuture = refreshedHome;
    });
    if (destination is HomeNavigationDestination) {
      _onNavigationDestination(destination);
    }
  }

  /// Mantém a aba atual quando a listagem é aberta como rota secundária.
  void _onNavigationDestination(HomeNavigationDestination destination) {
    if (destination == HomeNavigationDestination.horses) {
      _openHorseList();
    } else if (destination == HomeNavigationDestination.dashboard) {
      _openDashboard();
    } else {
      setState(() => _selectedDestination = destination);
    }
  }

  // --- Composição visual e navegação ----------------------------------------
  // Abre o painel do perfil sem alterar o destino atual da Home.
  // Ao voltar, os dados já carregados da Home continuam disponíveis.
  Future<void> _openDashboard() async {
    final destination = await Navigator.of(context)
        .push<HomeNavigationDestination>(
          MaterialPageRoute<HomeNavigationDestination>(
            builder: (dashboardContext) => GuardianDashboardScreen(
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
      // Utiliza o fundo oficial do tema.
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Barra superior.
      appBar: const HomeAppBar(),
      // Menu lateral do responsável.
      drawer: GuardianSidebar(
        onLogout: widget.onLogout,
        homeFuture: _homeFuture,
        onRegisterHorse: widget.onRegisterHorse ?? _openRegisterHorse,
      ),
      // Área reservada aos cards futuros.
      body: switch (_selectedDestination) {
        HomeNavigationDestination.profile => GuardianProfileScreen(
          loadGuardianProfile: _fetchGuardianProfile,
          onLogout: widget.onLogout,
          onEditGuardianProfile: widget.onEditGuardianProfile,
          onEditGuardianProfileData: widget.onEditGuardianProfile == null
              ? _openGuardianProfileEditor
              : null,
          onShowAllGuardianHorses: widget.onShowAllGuardianHorses,
          // O perfil usa o mesmo fluxo de cadastro aberto pela Home.
          onRegisterGuardianHorse: widget.onRegisterHorse ?? _openRegisterHorse,
          onSelectGuardianHorse: _openHorseProfile,
        ),
        HomeNavigationDestination.trainings => _buildTrainingAgenda(),
        _ => GuardianHomeContent(
          homeFuture: _homeFuture,
          onRetry: _retryHome,
          sessionMockHorses: _sessionMockHorses,
          onRegisterHorse: widget.onRegisterHorse ?? _openRegisterHorse,
          onSelectHorse: _openHorseProfile,
          onShowAllHorses: widget.onShowAllGuardianHorses ?? _openHorseList,
        ),
      },
      // Barra inferior de navegação.
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
