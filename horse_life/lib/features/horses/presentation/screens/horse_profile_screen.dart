// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos segmentos de carregamento, permissões, abas,
// edição, vínculos e exclusão; integração de deleteHorse com progresso e
// proteção contra chamadas duplicadas.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Conversão das seções em cards recolhíveis, adequação
// visual dos vínculos, inclusão da remoção com o aviso do protótipo e da
// navegação inferior com Cavalos selecionado. Validação da galeria lateral de
// fotos com indicador da imagem ativa. Integração da nova tela de edição.
// Restrição das ações de inclusão ao proprietário e adoção dos modais de
// limitação, observação de saúde e lesão conforme o protótipo.
//
// Data: 12/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão das ações de adicionar limitações, observações de saúde
// e lesões diretamente nas respectivas seções do perfil.
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do perfil responsivo do cavalo, com dados, plano,
// avaliações, permissões e edição integrada às callables existentes.
// Alteração: Inclusão do botão Editar vínculos e da consulta dos vínculos
// atuais, sem simular uma operação de escrita ausente no backend.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/collapsible_section_card.dart';
import 'package:horse_life/core/widgets/destructive_confirmation_dialog.dart';
import 'package:horse_life/core/widgets/gradient_button.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/core/widgets/inline_add_button.dart';
import 'package:horse_life/features/horses/data/models/horse_profile_data.dart';
import 'package:horse_life/features/horses/data/repositories/horse_profile_repository.dart';
import 'package:horse_life/features/horses/presentation/widgets/horse_injury_dialog.dart';
import 'package:horse_life/features/horses/presentation/widgets/horse_relationships_dialog.dart';
import 'package:horse_life/features/horses/presentation/widgets/horse_text_entry_dialog.dart';
import 'package:horse_life/features/horses/presentation/screens/horse_profile_edit_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

typedef HorseRemovalRequested = Future<void> Function(HorseProfileData horse);

/// Tela de detalhe aberta por qualquer resumo que preserve o id do cavalo.
///
/// Coordena consulta, permissões e ações remotas; os widgets privados abaixo
/// recebem dados prontos e cuidam somente da apresentação de cada aba.
class HorseProfileScreen extends StatefulWidget {
  const HorseProfileScreen({
    required this.horseId,
    this.currentUserId,
    this.isTrainer = false,
    this.repository = const FirebaseHorseProfileRepository(),
    this.onEditRelationships,
    this.onRemoveHorse,
    this.onNavigationSelected,
    super.key,
  });

  final String horseId;
  final String? currentUserId;
  final bool isTrainer;
  final HorseProfileRepository repository;

  /// Permite conectar uma futura rota de edição quando houver contrato remoto.
  final ValueChanged<HorseProfileData>? onEditRelationships;

  /// Substitui a remoção remota em integrações ou testes específicos.
  final HorseRemovalRequested? onRemoveHorse;

  /// Mantém a navegação da tela de origem sincronizada ao fechar o perfil.
  final ValueChanged<HomeNavigationDestination>? onNavigationSelected;

  @override
  State<HorseProfileScreen> createState() => _HorseProfileScreenState();
}

class _HorseProfileScreenState extends State<HorseProfileScreen>
    with SingleTickerProviderStateMixin {
  // --- Estado de carregamento, abas e operações bloqueantes -----------------
  late Future<HorseProfileData> _horseFuture;
  late final TabController _tabs;
  int _imageIndex = 0;
  bool _isDeleting = false;

  // --- Ciclo de vida e recarregamento ---------------------------------------

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _horseFuture = widget.repository.getHorse(widget.horseId);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _imageIndex = 0;
      _horseFuture = widget.repository.getHorse(widget.horseId);
    });
  }

  // --- Edição completa e atualizações pontuais ------------------------------
  // Toda alteração substitui a Future exibida; em caso de falha, o último
  // perfil válido volta à tela para que os dados não desapareçam.

  Future<void> _edit(HorseProfileData horse) async {
    final update = await Navigator.of(context).push<HorseProfileUpdate>(
      MaterialPageRoute(
        builder: (_) =>
            HorseProfileEditScreen(horse: horse, repository: widget.repository),
      ),
    );
    if (update == null || !mounted) return;
    await _updateHorse(horse, update);
  }

  Future<void> _updateHorse(
    HorseProfileData horse,
    HorseProfileUpdate update,
  ) async {
    if (update.isEmpty) return;
    try {
      final future = widget.repository.updateHorse(horse.id, update);
      setState(() {
        _horseFuture = future;
      });
      await future;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados do cavalo atualizados.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _horseFuture = Future.value(horse);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  Future<void> _addLimitation(HorseProfileData horse) async {
    if (horse.physicalLimitations.length >= 30) {
      _showLimitMessage('São permitidas até 30 limitações.');
      return;
    }
    final value = await showHorseTextEntryDialog(
      context,
      title: 'Adicionar limitação',
    );
    if (!mounted || value == null || value.isEmpty) return;
    await _updateHorse(
      horse,
      HorseProfileUpdate(
        physicalLimitations: HorseProfileListChanges(added: [value]),
      ),
    );
  }

  Future<void> _addHealthNote(HorseProfileData horse) async {
    if (horse.healthNotes.length >= 30) {
      _showLimitMessage('São permitidas até 30 observações de saúde.');
      return;
    }
    final value = await showHorseTextEntryDialog(
      context,
      title: 'Adicionar observação',
    );
    if (!mounted || value == null || value.isEmpty) return;
    await _updateHorse(
      horse,
      HorseProfileUpdate(healthNotes: HorseProfileListChanges(added: [value])),
    );
  }

  Future<void> _addInjury(HorseProfileData horse) async {
    if (horse.injuries.length >= 50) {
      _showLimitMessage('São permitidas até 50 lesões.');
      return;
    }
    final injury = await showHorseInjuryDialog(
      context: context,
      birthDate: horse.birthDate,
    );
    if (!mounted || injury == null) return;
    final record = HorseInjuryRecord(
      date: injury.date,
      description: injury.description,
      prescription: injury.prescription,
    );
    await _updateHorse(
      horse,
      HorseProfileUpdate(injuries: HorseProfileListChanges(added: [record])),
    );
  }

  void _showLimitMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // --- Vínculos e exclusão --------------------------------------------------
  // A edição de vínculos devolve o perfil atualizado. A exclusão exige
  // confirmação, bloqueia novas chamadas e só fecha a rota após sucesso.

  Future<void> _editRelationships(HorseProfileData horse) async {
    final externalAction = widget.onEditRelationships;
    if (externalAction != null) {
      externalAction(horse);
      return;
    }
    final updated = await showHorseRelationshipsDialog(
      context,
      horse: horse,
      repository: widget.repository,
    );
    if (!mounted || updated == null) return;
    final removed =
        (horse.athlete != null && updated.athlete?.id != horse.athlete?.id) ||
        horse.trainers.any(
          (person) => !updated.trainers.any((item) => item.id == person.id),
        );
    setState(() {
      _horseFuture = Future.value(updated);
    });
    AppSnackBar.show(
      context,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline,
      message: removed
          ? 'Vínculo removido com sucesso!'
          : 'Vínculo estabelecido com sucesso!',
    );
  }

  Future<void> _requestRemoval(HorseProfileData horse) async {
    if (_isDeleting) return;
    final confirmed = await showDestructiveConfirmationDialog(
      context,
      title: 'Tem certeza que quer excluir esse animal?',
      message:
          'Se você continuar essa operação, todos os dados relacionados ao '
          'seu cavalo serão perdidos e os usuários vinculados perderão o '
          'acesso a ele.\nEssa remoção depende apenas de você. Tem certeza que '
          'deseja prosseguir?',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    var deleted = false;
    try {
      final removeHorse = widget.onRemoveHorse;
      if (removeHorse != null) {
        await removeHorse(horse);
      } else {
        await widget.repository.deleteHorse(horse.id);
      }
      deleted = true;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
    if (deleted && mounted) Navigator.of(context).pop(true);
  }

  // --- Integração com navegação e permissões --------------------------------

  void _selectNavigationDestination(HomeNavigationDestination destination) {
    if (destination == HomeNavigationDestination.horses) return;
    widget.onNavigationSelected?.call(destination);
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  String _currentUserId(HorseProfileData horse) {
    final injectedId = widget.currentUserId?.trim() ?? '';
    if (injectedId.isNotEmpty) return injectedId;
    if (horse.responsibilities.contains('PROPRIETARIO')) {
      return horse.owner.id;
    }
    if (horse.responsibilities.contains('ATLETA')) {
      return horse.athlete?.id ?? '';
    }
    return '';
  }

  // --- Composição assíncrona da tela ----------------------------------------
  // O Stack mantém o conteúdo e sobrepõe uma barreira durante a exclusão para
  // impedir interações concorrentes enquanto a callable estiver pendente.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: HomeBottomNavBar(
        selectedDestination: HomeNavigationDestination.horses,
        onDestinationSelected: _selectNavigationDestination,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<HorseProfileData>(
              future: _horseFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return _LoadError(
                    message: _errorMessage(snapshot.error),
                    retry: _reload,
                  );
                }
                final horse = snapshot.data!;
                return NestedScrollView(
                  headerSliverBuilder: (context, innerScrolled) => [
                    SliverAppBar(
                      expandedHeight: 330,
                      pinned: true,
                      backgroundColor: AppColors.whiteSmoke,
                      foregroundColor: Colors.white,
                      leading: IconButton(
                        tooltip: 'Voltar',
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: _HorseGallery(
                          horse: horse,
                          imageIndex: _imageIndex,
                          onChanged: (index) =>
                              setState(() => _imageIndex = index),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                        child: Text(
                          horse.name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _TabsHeaderDelegate(
                        TabBar(
                          controller: _tabs,
                          indicatorColor: AppColors.seaGreen,
                          labelColor: AppColors.seaGreen,
                          unselectedLabelColor: AppColors.grey,
                          tabs: const [
                            Tab(icon: Icon(Icons.dns_outlined), text: 'Dados'),
                            Tab(
                              icon: Icon(Icons.calendar_month),
                              text: 'Plano atual',
                            ),
                            Tab(
                              icon: Icon(Icons.analytics_outlined),
                              text: 'Avaliações',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    controller: _tabs,
                    children: [
                      _DataTab(
                        horse: horse,
                        currentUserId: _currentUserId(horse),
                        onEdit: () => _edit(horse),
                        onEditRelationships: () => _editRelationships(horse),
                        onAddLimitation: () => _addLimitation(horse),
                        onAddHealthNote: () => _addHealthNote(horse),
                        onAddInjury: () => _addInjury(horse),
                        onRemove: () => _requestRemoval(horse),
                      ),
                      _PlanTab(
                        plan: horse.currentPlan,
                        showTrainerAction: widget.isTrainer,
                      ),
                      _EvaluationsTab(
                        evaluations: horse.evaluations,
                        showTrainerAction: widget.isTrainer,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isDeleting) ...[
            const Positioned.fill(
              child: ModalBarrier(dismissible: false, color: Colors.black26),
            ),
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: SizedBox(
                    key: Key('delete-horse-progress'),
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// --- Galeria e indicador ----------------------------------------------------

class _HorseGallery extends StatelessWidget {
  const _HorseGallery({
    required this.horse,
    required this.imageIndex,
    required this.onChanged,
  });

  final HorseProfileData horse;
  final int imageIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final images = horse.images;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (images.isEmpty)
          ColoredBox(
            color: AppColors.alabasterGray,
            child: Center(
              child: Image.asset('assets/black-head-horse.png', width: 150),
            ),
          )
        else
          PageView.builder(
            key: const Key('horse-image-gallery'),
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            onPageChanged: onChanged,
            itemBuilder: (_, index) => Image.network(
              images[index].url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: AppColors.alabasterGray,
                child: Center(
                  child: Image.asset('assets/black-head-horse.png', width: 120),
                ),
              ),
            ),
          ),
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: _GalleryPageIndicator(
              count: images.length,
              selectedIndex: imageIndex,
            ),
          ),
      ],
    );
  }
}

class _GalleryPageIndicator extends StatelessWidget {
  const _GalleryPageIndicator({
    required this.count,
    required this.selectedIndex,
  });

  final int count;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => Semantics(
    key: const Key('horse-gallery-page-indicator'),
    label: 'Foto ${selectedIndex + 1} de $count',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          key: ValueKey(
            'horse-gallery-indicator-$index-'
            '${index == selectedIndex ? 'active' : 'inactive'}',
          ),
          duration: const Duration(milliseconds: 180),
          width: index == selectedIndex ? 32 : 12,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: index == selectedIndex ? Colors.white : Colors.white70,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
  );
}

// --- Aba de dados e vínculos ------------------------------------------------

class _DataTab extends StatelessWidget {
  const _DataTab({
    required this.horse,
    required this.currentUserId,
    required this.onEdit,
    required this.onEditRelationships,
    required this.onAddLimitation,
    required this.onAddHealthNote,
    required this.onAddInjury,
    required this.onRemove,
  });

  final HorseProfileData horse;
  final String currentUserId;
  final VoidCallback onEdit;
  final VoidCallback onEditRelationships;
  final VoidCallback onAddLimitation;
  final VoidCallback onAddHealthNote;
  final VoidCallback onAddInjury;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      children: [
        if (horse.canEdit) ...[
          Row(
            children: [
              Expanded(
                child: GradientButton(
                  key: const Key('edit-horse-profile-button'),
                  onPressed: onEdit,
                  icon: Icons.edit_rounded,
                  label: 'Editar dados',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  key: const Key('edit-horse-relationships-button'),
                  onPressed: onEditRelationships,
                  icon: Symbols.link_2,
                  label: 'Editar vínculos',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        CollapsibleSectionCard(
          key: const Key('horse-animal-data-section'),
          title: 'Dados do animal',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line('Microchip', horse.microchip),
              _line('Idade', _age(horse.age)),
              _line('Raça', horse.breed),
              _line('Pelagem', horse.coat),
              _line('Sexo', horse.sex == 'FEMEA' ? 'Fêmea' : 'Macho'),
            ],
          ),
        ),
        CollapsibleSectionCard(
          key: const Key('horse-sports-data-section'),
          title: 'Dados esportivos',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _line('Modalidade', horse.modality?.name ?? 'Não informada'),
              _line(
                'Plano ativo',
                horse.currentPlan?.title ?? 'Nenhum plano ativo',
              ),
            ],
          ),
        ),
        CollapsibleSectionCard(
          key: const Key('horse-relationships-section'),
          title: 'Vínculos',
          child: _RelationshipUsers(horse: horse, currentUserId: currentUserId),
        ),
        _ListSection(
          title: 'Limitações',
          items: horse.physicalLimitations,
          onAdd: horse.canEdit ? onAddLimitation : null,
          addButtonKey: const Key('add-horse-limitation-button'),
        ),
        _ListSection(
          title: 'Observações de saúde',
          items: horse.healthNotes,
          onAdd: horse.canEdit ? onAddHealthNote : null,
          addButtonKey: const Key('add-horse-health-note-button'),
        ),
        CollapsibleSectionCard(
          key: const Key('horse-injuries-section'),
          title: 'Histórico de lesões',
          child: Column(
            key: const Key('horse-injuries-content'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (horse.canEdit)
                InlineAddButton(
                  key: const Key('add-horse-injury-button'),
                  onPressed: onAddInjury,
                ),
              if (horse.injuries.isEmpty)
                const Text('Nenhuma lesão registrada.')
              else
                ...horse.injuries.map(
                  (injury) => Container(
                    key: ValueKey(
                      'horse-injury-${injury.date.toIso8601String()}-'
                      '${injury.description}',
                    ),
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_date(injury.date)),
                        Text(
                          injury.description,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (injury.prescription != null)
                          Text(injury.prescription!),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (horse.canEdit)
          SizedBox(
            height: 64,
            child: FilledButton.icon(
              key: const Key('remove-horse-button'),
              onPressed: onRemove,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.delete_rounded),
              label: const Text('Excluir animal'),
            ),
          ),
      ],
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.items,
    this.onAdd,
    this.addButtonKey,
  });
  final String title;
  final List<String> items;
  final VoidCallback? onAdd;
  final Key? addButtonKey;

  @override
  Widget build(BuildContext context) => CollapsibleSectionCard(
    key: ValueKey('horse-section-$title'),
    title: title,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onAdd != null)
          InlineAddButton(key: addButtonKey, onPressed: onAdd!),
        if (items.isEmpty)
          const Text('Nenhum registro.')
        else
          ...items.map((item) => Text('• $item')),
      ],
    ),
  );
}

class _RelationshipUsers extends StatelessWidget {
  const _RelationshipUsers({required this.horse, required this.currentUserId});

  final HorseProfileData horse;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final users = [
      if (horse.owner.id != currentUserId)
        (label: 'Proprietário', person: horse.owner),
      if (horse.athlete != null && horse.athlete!.id != currentUserId)
        (label: 'Atleta', person: horse.athlete!),
      for (final trainer in horse.trainers)
        if (trainer.id != currentUserId) (label: 'Treinador', person: trainer),
    ];
    if (users.isEmpty) {
      return const Text('Nenhum outro usuário vinculado.');
    }
    return Wrap(
      alignment: WrapAlignment.spaceAround,
      runAlignment: WrapAlignment.start,
      spacing: 18,
      runSpacing: 18,
      children: [
        for (final user in users)
          _RelationshipUser(label: user.label, person: user.person),
      ],
    );
  }
}

class _RelationshipUser extends StatelessWidget {
  const _RelationshipUser({required this.label, required this.person});

  final String label;
  final HorseProfilePerson person;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 120,
    child: Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.grey,
          foregroundColor: Colors.white,
          child: Text(
            person.name.characters.first.toUpperCase(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(person.name, textAlign: TextAlign.center),
      ],
    ),
  );
}

// --- Abas de plano e avaliações --------------------------------------------

class _PlanTab extends StatelessWidget {
  const _PlanTab({required this.plan, required this.showTrainerAction});
  final HorseProfilePlan? plan;
  final bool showTrainerAction;

  @override
  Widget build(BuildContext context) => plan == null
      ? _HorseEmptyState(
          key: Key('horse-plan-empty-state'),
          title: 'Nenhum plano ativo',
          message:
              'Parece que este animal não possui nenhum plano ativo no '
              'momento. Volte aqui depois que algum treinador prescrever a '
              'rotina ideal para ele.',
          action: showTrainerAction
              ? const _TrainerTabAction(
                  key: Key('add-horse-plan-button'),
                  label: 'Adicionar plano',
                )
              : null,
        )
      : ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (showTrainerAction) ...[
              const _TrainerTabAction(
                key: Key('add-horse-plan-button'),
                label: 'Adicionar plano',
              ),
              const SizedBox(height: 24),
            ],
            CollapsibleSectionCard(
              title: 'Plano atual',
              child: Text(plan!.title),
            ),
          ],
        );
}

class _EvaluationsTab extends StatelessWidget {
  const _EvaluationsTab({
    required this.evaluations,
    required this.showTrainerAction,
  });
  final List<HorseProfileEvaluation> evaluations;
  final bool showTrainerAction;

  @override
  Widget build(BuildContext context) => evaluations.isEmpty
      ? _HorseEmptyState(
          key: Key('horse-evaluations-empty-state'),
          title: 'Nenhuma avaliação realizada',
          message:
              'Parece que este animal não passou por nenhuma avaliação ainda. '
              'Volte aqui depois que algum treinador tiver averiguado a '
              'condição física do seu cavalo.',
          action: showTrainerAction
              ? const _TrainerTabAction(
                  key: Key('add-horse-evaluation-button'),
                  label: 'Nova avaliação',
                )
              : null,
        )
      : ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (showTrainerAction) ...[
              const _TrainerTabAction(
                key: Key('add-horse-evaluation-button'),
                label: 'Nova avaliação',
              ),
              const SizedBox(height: 24),
            ],
            for (var index = 0; index < evaluations.length; index++) ...[
              if (index > 0) const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: Text('Avaliação de ${_date(evaluations[index].date)}'),
                  subtitle: Text(
                    'Treinador: ${evaluations[index].trainer.name}',
                  ),
                ),
              ),
            ],
          ],
        );
}

class _TrainerTabAction extends StatelessWidget {
  const _TrainerTabAction({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: SizedBox(
      width: 400,
      child: GradientButton(label: label, icon: Icons.add, onPressed: () {}),
    ),
  );
}

// --- Estados vazios e falha de carregamento --------------------------------

class _HorseEmptyState extends StatelessWidget {
  const _HorseEmptyState({
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(24, action == null ? 40 : 20, 24, 24),
    children: [
      if (action case final action?) ...[action, const SizedBox(height: 20)],
      Container(
        decoration: BoxDecoration(
          color: AppColors.alabasterGray,
          borderRadius: BorderRadius.circular(38),
        ),
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.whiteSmoke,
            borderRadius: BorderRadius.circular(34),
          ),
          padding: const EdgeInsets.fromLTRB(28, 34, 28, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.block_outlined,
                      size: 38,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.text,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// --- Suporte ao cabeçalho fixo das abas -------------------------------------

class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabsHeaderDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(color: AppColors.whiteSmoke, child: tabBar);
  @override
  bool shouldRebuild(covariant _TabsHeaderDelegate oldDelegate) => false;
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: retry, child: const Text('Tentar novamente')),
        ],
      ),
    ),
  );
}

Widget _line(String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 5),
  child: Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        TextSpan(text: value),
      ],
    ),
  ),
);

String _age(HorseProfileAge age) {
  final years = '${age.years} ano${age.years == 1 ? '' : 's'}';
  if (age.months == 0) return years;
  return '$years e ${age.months} ${age.months == 1 ? 'mês' : 'meses'}';
}

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

String _errorMessage(Object? error) {
  if (error is TimeoutException) {
    return 'O servidor demorou para responder. Tente novamente.';
  }
  if (error is FirebaseFunctionsException) {
    return error.message ?? 'Não foi possível carregar o cavalo.';
  }
  return 'Não foi possível carregar o cavalo. Tente novamente.';
}
