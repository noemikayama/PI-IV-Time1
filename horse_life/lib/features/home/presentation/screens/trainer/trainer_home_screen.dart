// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
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

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/core/widgets/trainer_sidebar.dart';
import '../../../application/controllers/home_loader.dart';
import '../../../data/models/trainer_home_data.dart';
import '../../../data/repositories/trainer_repository.dart';
import '../../../home_composition.dart';
import '../../widgets/trainer_home_content.dart';

/// Coordena os dados, ações e navegação da área inicial do treinador.
class TrainerHomeScreen extends StatefulWidget {
  const TrainerHomeScreen({
    super.key,
    required this.onLogout,
    this.mockScenario,
    this.loader,
    this.repository,
    this.onViewTraining,
    this.onSelectHorse,
    this.onSelectClient,
    this.onShowAllTrainings,
    this.onShowAllHorses,
    this.onShowAllClients,
    this.onNavigationSelected,
  });

  // --- Fontes de dados -------------------------------------------------------
  /// `null` usa o Firebase; os demais cenários habilitam dados simulados.
  final String? mockScenario;

  /// Preferencialmente injetado pela raiz do aplicativo.
  final HomeLoader<TrainerHomeData>? loader;

  /// Injeção opcional de repositório (por exemplo, em testes).
  final TrainerRepository? repository;

  // --- Ações fornecidas pela composição do aplicativo -----------------------
  final Future<void> Function() onLogout;
  final ValueChanged<TrainerTraining>? onViewTraining;
  final ValueChanged<TrainerHorse>? onSelectHorse;
  final ValueChanged<TrainerClient>? onSelectClient;
  final VoidCallback? onShowAllTrainings;
  final VoidCallback? onShowAllHorses;
  final VoidCallback? onShowAllClients;
  final ValueChanged<int>? onNavigationSelected;

  @override
  State<TrainerHomeScreen> createState() => _TrainerHomeScreenState();
}

class _TrainerHomeScreenState extends State<TrainerHomeScreen> {
  // --- Estado compartilhado --------------------------------------------------
  late Future<TrainerHomeData> _homeFuture;
  int _selectedIndex = 0;
  late HomeLoader<TrainerHomeData> _loader;

  /// A sidebar e o conteúdo usam uma única Future, evitando chamadas duplicadas.
  Future<TrainerHomeData> _fetchHome() => _loader.fetchHome();

  // --- Seleção da fonte de dados --------------------------------------------
  // Respeita dependências injetadas antes de recorrer à composição padrão.
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
  void _retry() => setState(() => _homeFuture = _fetchHome());

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

  // --- Composição visual e navegação ----------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const HomeAppBar(),
      drawer: TrainerSidebar(
        onLogout: widget.onLogout,
        homeFuture: _homeFuture,
      ),
      // Enquanto o perfil do treinador não é implementado, o item mantém a
      // estrutura da tela e oculta apenas o conteúdo da Home.
      body: _selectedIndex == 4
          ? const SizedBox.shrink()
          : TrainerHomeContent(
              homeFuture: _homeFuture,
              onRetry: _retry,
              onViewTraining: widget.onViewTraining,
              onSelectHorse: widget.onSelectHorse,
              onSelectClient: widget.onSelectClient,
              onShowAllTrainings: widget.onShowAllTrainings,
              onShowAllHorses: widget.onShowAllHorses,
              onShowAllClients: widget.onShowAllClients,
            ),
      bottomNavigationBar: HomeBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: (index) {
          setState(() => _selectedIndex = index);
          widget.onNavigationSelected?.call(index);
        },
      ),
    );
  }
}
