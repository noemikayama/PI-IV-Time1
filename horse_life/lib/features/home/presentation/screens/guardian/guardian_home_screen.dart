// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Cadastro de cavalos aberto pela rota da feature, sem acoplamento
// às etapas do formulário.
//
// Data: 06/11/2026 (cadastro real)
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Home recebe cavalo persistido pela Function registerHorse e
// atualiza getHome; repositório mock permanece apenas em cenários de teste.
//
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
// Alteração: Revisão de compatibilidade da Home com os cards e cenários simulados; estrutura e comportamentos existentes preservados.
//
// Data: 13/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação da estrutura inicial da Home do Responsável,
// seguindo a arquitetura e os padrões visuais oficiais do HorseLife.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/guardian_sidebar.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/features/horses/data/repositories/horse_registration_repository.dart';
import 'package:horse_life/features/horses/data/repositories/mock_horse_registration_repository.dart';
import 'package:horse_life/features/horses/presentation/screens/horse_registration_screen.dart';
import 'package:horse_life/features/authentication/data/repositories/firebase_password_reset_repository.dart';
import 'package:horse_life/features/profile/application/controllers/guardian_profile_controller.dart';
import 'package:horse_life/features/horses/presentation/routes/horse_registration_flow_route.dart';
import 'package:horse_life/features/profile/data/models/guardian_profile_data.dart';
import 'package:horse_life/features/profile/data/repositories/guardian_profile_repository.dart';
import 'package:horse_life/features/profile/presentation/screens/guardian_profile_edit_screen.dart';
import 'package:horse_life/features/profile/presentation/screens/guardian_profile_screen.dart';
import '../../../application/controllers/home_loader.dart';
import '../../../data/models/guardian_home_data.dart';
import '../../../home_composition.dart';
import '../../widgets/guardian_home_content.dart';

/// Coordena fonte de dados, estado de navegação e compartilhamento da Future entre corpo e sidebar.
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

  // Informe normal, empty ou completed apenas em testes.
  // Null ativa as Cloud Functions reais.
  final String? mockScenario;

  /// Dependência injetada pela raiz. Se ausente, aplica composição legada.
  final HomeLoader<GuardianHomeData>? loader;

  // Ponto de extensão para abrir o cadastro por rotas externas.
  final VoidCallback? onRegisterHorse;

  /// Pode receber um repositório fake em testes; sem injeção usa Firebase
  /// na produção ou mock quando mockScenario está ativo.
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
  // --- Estado e dependências -------------------------------------------------
  // A Future é compartilhada entre o conteúdo e o menu para evitar requisições
  // duplicadas durante reconstruções da tela.
  int _selectedIndex = 0;
  // Cadastro mockado não muda o backend; mantém os nomes visíveis só na sessão.
  final List<String> _sessionMockHorses = [];
  late Future<GuardianHomeData> _homeFuture;
  late HomeLoader<GuardianHomeData> _loader;

  // O repositório é criado sob demanda e reutilizado no carregamento e edição.
  FirebaseGuardianProfileRepository? _guardianProfileRepository;

  FirebaseGuardianProfileRepository get _profileRepository =>
      _guardianProfileRepository ??= const FirebaseGuardianProfileRepository();

  // --- Carregamento da Home e do perfil -------------------------------------
  Future<GuardianHomeData> _fetchHome() => _loader.fetchHome();

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
    if (!result.isPersisted) {
      // Não consulta o servidor após um registro que só existe no frontend.
      // Isso evita erro/desaparecimento da Home durante o teste em celular.
      setState(() => _sessionMockHorses.add(result.name));
    } else {
      // Cadastro real: atualiza a lista do servidor e o estado vazio da Home.
      _retryHome();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.warning ??
              'Cadastro de ${result.name} concluído${result.isPersisted ? '' : ' em modo de demonstração (não salvo no servidor)'}!',
        ),
      ),
    );
  }

  /// Refaz a consulta da Home após uma falha apresentada ao usuário.
  void _retryHome() {
    setState(() => _homeFuture = _fetchHome());
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
      ),
      // O último item alterna do painel inicial para o perfil do responsável.
      body: _selectedIndex == 4
          ? GuardianProfileScreen(
              loadGuardianProfile: _fetchGuardianProfile,
              onLogout: widget.onLogout,
              onEditGuardianProfile: widget.onEditGuardianProfile,
              onEditGuardianProfileData: widget.onEditGuardianProfile == null
                  ? _openGuardianProfileEditor
                  : null,
              onShowAllGuardianHorses: widget.onShowAllGuardianHorses,
              // O perfil mantém seu callback original: integração em outra etapa.
              onRegisterGuardianHorse: widget.onRegisterHorse,
            )
          : GuardianHomeContent(
              homeFuture: _homeFuture,
              onRetry: _retryHome,
              sessionMockHorses: _sessionMockHorses,
              onRegisterHorse: widget.onRegisterHorse ?? _openRegisterHorse,
            ),
      // Barra inferior de navegação.
      bottomNavigationBar: HomeBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
