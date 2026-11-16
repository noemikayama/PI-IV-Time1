// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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

import 'package:horse_life/core/widgets/guardian_sidebar.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/features/authentication/data/repositories/firebase_password_reset_repository.dart';
import 'package:horse_life/features/horses/data/repositories/horse_registration_repository.dart';
import 'package:horse_life/features/horses/data/repositories/mock_horse_registration_repository.dart';
import 'package:horse_life/features/horses/presentation/routes/horse_registration_flow_route.dart';
import 'package:horse_life/features/horses/presentation/screens/horse_profile_screen.dart';
import 'package:horse_life/features/profile/application/controllers/guardian_profile_controller.dart';
import 'package:horse_life/features/profile/data/models/guardian_profile_data.dart';
import 'package:horse_life/features/profile/data/repositories/guardian_profile_repository.dart';
import 'package:horse_life/features/profile/presentation/screens/guardian_profile_edit_screen.dart';
import 'package:horse_life/features/profile/presentation/screens/guardian_profile_screen.dart';

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
    this.onRegisterHorse,
    this.horseRegistrationRepository,
    this.guardianProfileLoader,
    this.onEditGuardianProfile,
    this.onShowAllGuardianHorses,
    super.key,
  });

  // Use normal, empty ou completed nos testes. Null usa os dados reais.
  final String? mockScenario;

  /// Carregador da Home. Quando ausente, usa a composição padrão.
  final HomeLoader<GuardianHomeData>? loader;

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
  late Future<GuardianHomeData> _homeFuture;
  late HomeLoader<GuardianHomeData> _loader;
  bool _isOpeningHorseProfile = false;

  // O repositório é criado sob demanda e reutilizado no carregamento e edição.
  FirebaseGuardianProfileRepository? _guardianProfileRepository;

  FirebaseGuardianProfileRepository get _profileRepository =>
      _guardianProfileRepository ??= const FirebaseGuardianProfileRepository();

  // --- Carregamento da Home e do perfil -------------------------------------
  Future<GuardianHomeData> _fetchHome() => _loader.fetchHome();

  /// Abre o detalhe remoto a partir de qualquer card que preserve o id.
  Future<void> _openHorseProfile(String id) async {
    if (_isOpeningHorseProfile) return;
    _isOpeningHorseProfile = true;

    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => HorseProfileScreen(
            horseId: id,
            currentUserId: FirebaseAuth.instance.currentUser?.uid,
            isTrainer: false,
            onNavigationSelected: (destination) {
              if (mounted) setState(() => _selectedDestination = destination);
            },
          ),
        ),
      );
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

  /// Mantém a feature independente da Home, retornando ao ponto de origem.
  Future<void> _openRegisterHorse() async {
    final result = await Navigator.of(context).push<HorseRegistrationResult>(
      HorseRegistrationFlowRoute.build(
        repository:
            widget.horseRegistrationRepository ??
            (widget.mockScenario == null
                ? null
                : const MockHorseRegistrationRepository()),
      ),
    );
    if (!mounted || result == null) return;

    if (result.isPersisted) {
      // Cadastro real: atualiza a lista de cavalos consultando o servidor.
      _retryHome();
    } else {
      // Cadastro mockado: exibe o nome só na sessão, sem consultar o servidor.
      setState(() => _sessionMockHorses.add(result.name));
    }

    // Mostra a mensagem retornada pela feature ou uma confirmação padrão.
    final message =
        result.warning ??
        (result.isPersisted
            ? 'Cadastro de ${result.name} concluído!'
            : 'Cadastro de ${result.name} concluído em modo de demonstração '
                  '(não salvo no servidor)!');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        oldWidget.loader != widget.loader) {
      _configureLoader();
      _homeFuture = _fetchHome();
    }
  }

  // --- Composição visual e navegação ----------------------------------------
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
      body: _selectedDestination == HomeNavigationDestination.profile
          ? GuardianProfileScreen(
              loadGuardianProfile: _fetchGuardianProfile,
              onLogout: widget.onLogout,
              onEditGuardianProfile: widget.onEditGuardianProfile,
              onEditGuardianProfileData: widget.onEditGuardianProfile == null
                  ? _openGuardianProfileEditor
                  : null,
              onShowAllGuardianHorses: widget.onShowAllGuardianHorses,
              // O perfil usa o mesmo fluxo de cadastro aberto pela Home.
              onRegisterGuardianHorse:
                  widget.onRegisterHorse ?? _openRegisterHorse,
              onSelectGuardianHorse: _openHorseProfile,
            )
          : GuardianHomeContent(
              homeFuture: _homeFuture,
              onRetry: _retryHome,
              sessionMockHorses: _sessionMockHorses,
              onRegisterHorse: widget.onRegisterHorse ?? _openRegisterHorse,
              onSelectHorse: _openHorseProfile,
            ),
      // Barra inferior de navegação.
      bottomNavigationBar: HomeBottomNavBar(
        selectedDestination: _selectedDestination,
        onDestinationSelected: (destination) =>
            setState(() => _selectedDestination = destination),
      ),
    );
  }
}
