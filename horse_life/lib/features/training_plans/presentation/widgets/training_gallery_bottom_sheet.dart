// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do bottom sheet da galeria de treinamentos compatíveis com
// o cavalo selecionado no plano, com busca textual e estado vazio.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

import '../../application/controllers/training_plan_registration_controller.dart';
import '../../data/models/training_plan_gallery_item.dart';
import 'training_plan_cards.dart';

/// Abre o bottom sheet modal da galeria de treinamentos do treinador.
Future<void> showTrainingGalleryBottomSheet({
  required BuildContext context,
  required TrainingPlanRegistrationController controller,
  required String horseId,
  required TrainingPlanGalleryItem? selectedTraining,
  required ValueChanged<TrainingPlanGalleryItem?> onSelectionChanged,
  required VoidCallback onCreateTraining,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => TrainingGalleryBottomSheet(
      controller: controller,
      horseId: horseId,
      initialSelectedTraining: selectedTraining,
      onSelectionChanged: onSelectionChanged,
      onCreateTraining: () {
        Navigator.of(sheetContext).pop();
        onCreateTraining();
      },
    ),
  );
}

/// Bottom sheet modal que exibe os treinamentos do treinador compatíveis com o
/// animal do plano, permitindo busca por título e seleção única para o dia.
class TrainingGalleryBottomSheet extends StatefulWidget {
  const TrainingGalleryBottomSheet({
    required this.controller,
    required this.horseId,
    required this.initialSelectedTraining,
    required this.onSelectionChanged,
    required this.onCreateTraining,
    super.key,
  });

  final TrainingPlanRegistrationController controller;
  final String horseId;
  final TrainingPlanGalleryItem? initialSelectedTraining;
  final ValueChanged<TrainingPlanGalleryItem?> onSelectionChanged;
  final VoidCallback onCreateTraining;

  @override
  State<TrainingGalleryBottomSheet> createState() =>
      _TrainingGalleryBottomSheetState();
}

class _TrainingGalleryBottomSheetState
    extends State<TrainingGalleryBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  TrainingPlanGalleryItem? _selectedTraining;
  List<TrainingPlanGalleryItem> _trainings = const [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasCatalogLoadedEmpty = false;

  @override
  void initState() {
    super.initState();
    _selectedTraining = widget.initialSelectedTraining;
    _loadTrainings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrainings() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final trainings = await widget.controller.fetchTrainingGallery(
        horseId: widget.horseId,
        searchQuery: _searchController.text,
      );

      if (!mounted) return;
      setState(() {
        _trainings = trainings;
        if (_searchController.text.trim().isEmpty) {
          _hasCatalogLoadedEmpty = trainings.isEmpty;
        }
        _isLoading = false;
      });
    } on Object catch (error, stackTrace) {
      debugPrint(
        '[TrainingGalleryBottomSheet] Falha ao carregar treinamentos da galeria: $error\n$stackTrace',
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _onSearchChanged(String _) {
    _loadTrainings();
  }

  void _toggleSelection(TrainingPlanGalleryItem training) {
    setState(() {
      if (_selectedTraining?.id == training.id) {
        _selectedTraining = null;
      } else {
        _selectedTraining = training;
      }
    });
    widget.onSelectionChanged(_selectedTraining);
  }

  bool get _showGlobalEmptyState =>
      !_isLoading &&
      !_hasError &&
      _hasCatalogLoadedEmpty &&
      _searchController.text.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FractionallySizedBox(
      heightFactor: 0.78,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.whiteSmoke,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 56,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.list_alt_rounded,
                    color: AppColors.text,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Galeria de treinamentos',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(indent: 24, endIndent: 24, height: 1),
            Expanded(
              child: _showGlobalEmptyState
                  ? _EmptyTrainingGallery(
                      onCreateTraining: widget.onCreateTraining,
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
                          child: TextField(
                            key: const Key('training-gallery-search-input'),
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 18,
                              color: AppColors.text,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Buscar...',
                              hintStyle: theme.textTheme.headlineSmall
                                  ?.copyWith(
                                    fontSize: 18,
                                    color: AppColors.grey,
                                  ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.text,
                                size: 24,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFE0E0E0),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: AppColors.seaGreen,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: _buildListBody(theme)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('training-gallery-loading'),
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Não foi possível carregar os treinamentos.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadTrainings,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_trainings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Nenhum treinamento encontrado para os filtros aplicados.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.grey),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 24),
      itemCount: _trainings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final training = _trainings[index];
        return GalleryTrainingSelectableCard(
          cardKey: ValueKey('gallery-training-card-${training.id}'),
          training: training,
          isSelected: _selectedTraining?.id == training.id,
          onToggle: () => _toggleSelection(training),
        );
      },
    );
  }
}

class _EmptyTrainingGallery extends StatelessWidget {
  const _EmptyTrainingGallery({required this.onCreateTraining});

  final VoidCallback onCreateTraining;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 42, 32, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block_rounded,
                color: AppColors.text,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'Nenhum treinamento criado',
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Crie agora mesmo um treinamento\n'
            'para montar o plano ideal para este\n'
            'cavalo.',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              fontSize: 19,
              height: 1.25,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              key: const Key('empty-gallery-create-training-button'),
              onPressed: onCreateTraining,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.seaGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
                textStyle: textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.add_box_outlined, size: 24),
              label: const Text('Criar treinamento'),
            ),
          ),
        ],
      ),
    );
  }
}
