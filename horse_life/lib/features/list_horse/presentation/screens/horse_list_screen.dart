// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// 07/11/2026: Criação da listagem de cavalos para ambos os perfis.
// 12/11/2026: Integração exclusiva com Firebase callable listHorses.
//   Busca e ordenação remotas; sem dados mockados, nem cadastro temporário.
//   Botões de cadastro reutilizam a rota real de features/horses.
// 12/11/2026: Reutiliza HomeAppBar, HomeBottomNavBar e AppColors;
//   sem cópia de logos, imagens ou barra de navegação.
// 12/11/2026: Atualiza URLs temporárias de fotos ao retomar o aplicativo
//   e mantém estado vazio conforme os protótipos de Responsável/Profissional.
// 13/11/2026: Ajusta botão de cadastro para 60 x 60 conforme o Figma.
// -----------------------------------------------------------------------------

import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/home_app_bar.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/features/horses/data/repositories/horse_registration_repository.dart';
import 'package:horse_life/features/horses/presentation/routes/horse_registration_flow_route.dart';
import '../../domain/models/horse_list_item.dart';
import '../../domain/repositories/horse_list_repository.dart';
import '../../list_horse_composition.dart';
import '../widgets/horse_list_card.dart';
import '../widgets/horse_list_empty_state.dart';
import '../widgets/horse_list_search_bar.dart';
import '../widgets/horse_list_sort_sheet.dart';

/// Consultas dependem de sessão Firebase válida e da callable listHorses publicada.
/// O repositório opcional serve à composição, não há fallback para Mock API.
class HorseListScreen extends StatefulWidget {
  final HorseListProfile profile;
  final HorseListRepository? repository;
  final ValueChanged<HorseRegistrationResult>? onRegistrationCompleted;
  final ValueChanged<HorseListItem>? onHorseSelected;
  final VoidCallback? onMenuPressed;
  final ValueChanged<int>? onNavigationSelected;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? drawer;

  const HorseListScreen({
    super.key,
    required this.profile,
    this.repository,
    this.onRegistrationCompleted,
    this.onHorseSelected,
    this.onMenuPressed,
    this.onNavigationSelected,
    this.appBar,
    this.bottomNavigationBar,
    this.drawer,
  });

  @override
  State<HorseListScreen> createState() => _HorseListScreenState();
}

class _HorseListScreenState extends State<HorseListScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<HorseListItem>> _horsesFuture;
  Timer? _searchDebounce;
  String _query = '';
  HorseSortOrder _sortOrder = HorseSortOrder.alphabeticalAsc;
  bool _openingRegistration = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadFromFirebase();
  }

  void _loadFromFirebase() {
    final repository = widget.repository ?? ListHorseComposition.productionRepository();
    _horsesFuture = repository.listHorses(
      profile: widget.profile,
      search: _query,
      order: _sortOrder,
    );
  }

  @override
  void didUpdateWidget(covariant HorseListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile || oldWidget.repository != widget.repository) {
      _searchDebounce?.cancel();
      _loadFromFirebase();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // As URLs de leitura do backend duram 15 minutos. Ao voltar para o app,
    // consulta listHorses outra vez para receber URLs de leitura renovadas.
    if (state == AppLifecycleState.resumed && mounted) {
      _searchDebounce?.cancel();
      setState(_loadFromFirebase);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshHorses() async {
    _searchDebounce?.cancel();
    setState(_loadFromFirebase);
    try {
      await _horsesFuture;
    } catch (_) {
      // O erro fica visível no FutureBuilder, sem apresentar dados fictícios.
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _query = value;
    // A Function recebe busca por nome: reduz chamadas enquanto a pessoa digita.
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(_loadFromFirebase);
    });
    // Redesenha apenas o botão de limpar e mantém o mesmo TextField em foco.
    setState(() {});
  }

  Future<void> _chooseSortOrder() async {
    final selected = await showHorseListSortSheet(
      context: context,
      currentOrder: _sortOrder,
    );
    if (!mounted || selected == null || selected == _sortOrder) return;
    _searchDebounce?.cancel();
    setState(() {
      _sortOrder = selected;
      _loadFromFirebase();
    });
  }

  Future<void> _registerHorse() async {
    if (widget.profile != HorseListProfile.guardian || _openingRegistration) return;
    setState(() => _openingRegistration = true);
    try {
      // Não injeta repositório de demonstração: o formulário usa Firebase.
      final result = await Navigator.of(context).push<HorseRegistrationResult>(
        HorseRegistrationFlowRoute.build(),
      );
      if (!mounted || result == null) return;
      if (!result.isPersisted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O cadastro não foi confirmado pelo servidor.')),
        );
        return;
      }
      // Registro gravado: consulta novamente o servidor antes de exibir o animal.
      setState(_loadFromFirebase);
      widget.onRegistrationCompleted?.call(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.warning ?? 'Cadastro de ${result.name} concluído!')),
      );
    } finally {
      if (mounted) setState(() => _openingRegistration = false);
    }
  }

  String _describeError(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'unauthenticated':
          return 'Sua sessão expirou. Entre novamente para consultar os cavalos.';
        case 'permission-denied':
          return 'Sua conta não tem permissão para consultar esses cavalos.';
        case 'not-found':
          return 'A função listHorses não está disponível neste projeto Firebase.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'Firebase indisponível no momento. Verifique a conexão e tente novamente.';
        default:
          return error.message ?? 'Não foi possível consultar a lista no Firebase.';
      }
    }
    if (error is FormatException) return error.message;
    return 'Não foi possível consultar os cavalos. Tente novamente.';
  }

  void _navigate(int tab) {
    if (tab == 2) return;
    widget.onNavigationSelected?.call(tab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.appBar ?? (widget.drawer != null
          ? const HomeAppBar()
          : AppBar(title: const Text('Meus cavalos'))),
      drawer: widget.drawer,
      bottomNavigationBar: widget.bottomNavigationBar ??
          HomeBottomNavBar(
            selectedDestination: HomeNavigationDestination.horses,
            onDestinationSelected: (destination) => _navigate(destination.index),
          ),
      floatingActionButton: widget.profile == HorseListProfile.guardian
          ? FutureBuilder<List<HorseListItem>>(
              future: _horsesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done ||
                    !snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                // Proporção do botão "+" no Figma: 60 x 60.
                // Não usar FloatingActionButton.large (96 x 96).
                return SizedBox(
                  width: 60,
                  height: 60,
                  child: FloatingActionButton(
                    key: const Key('horse-list-register-fab'),
                    onPressed: _openingRegistration ? null : _registerHorse,
                    tooltip: 'Cadastrar animal',
                    backgroundColor: AppColors.seaGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.add_rounded, size: 32),
                  ),
                );
              },
            )
          : null,
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 6, 20, 22),
                  child: Text(
                    'Meus cavalos',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                  ),
                ),
                FutureBuilder<List<HorseListItem>>(
                  future: _horsesFuture,
                  builder: (context, snapshot) {
                    // No Figma o estado vazio inicial não exibe a busca.
                    // Durante uma busca sem resultados, ela permanece para
                    // que o usuário consiga limpar o filtro.
                    if (snapshot.hasData &&
                        snapshot.data!.isEmpty &&
                        _query.trim().isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: HorseListSearchBar(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onSortPressed: _chooseSortOrder,
                      ),
                    );
                  },
                ),
                Expanded(
                  child: FutureBuilder<List<HorseListItem>>(
                    future: _horsesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(Icons.cloud_off_outlined, size: 42),
                                const SizedBox(height: 12),
                                Text(_describeError(snapshot.error!), textAlign: TextAlign.center),
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  onPressed: () => setState(_loadFromFirebase),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Tentar novamente'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final horses = snapshot.data ?? const <HorseListItem>[];
                      if (horses.isEmpty) {
                        if (_query.trim().isNotEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(Icons.search_off_rounded, size: 42),
                                const Text('Nenhum cavalo encontrado.'),
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                  child: const Text('Limpar busca'),
                                ),
                              ],
                            ),
                          );
                        }
                        return Align(
                          alignment: Alignment.topCenter,
                          child: HorseListEmptyState(
                            profile: widget.profile,
                            onAddHorse: widget.profile == HorseListProfile.guardian &&
                                    !_openingRegistration
                                ? _registerHorse
                                : null,
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _refreshHorses,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(20, 2, 20, 100),
                          itemCount: horses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 18),
                          itemBuilder: (context, index) {
                            final horse = horses[index];
                            return HorseListCard(
                              key: ValueKey(horse.id),
                              horse: horse,
                              profile: widget.profile,
                              onTap: widget.onHorseSelected == null
                                  ? null
                                  : () => widget.onHorseSelected!(horse),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
