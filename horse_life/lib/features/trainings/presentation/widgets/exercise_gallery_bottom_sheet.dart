// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Desacoplamento do carregamento de cavalos vinculados e exercícios,
// adicionando log de diagnóstico com debugPrint para falhas de rede/função.
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do bottom sheet da galeria de exercícios do treinamento,
// com renderização padrão de exercícios genéricos, filtro opcional por cavalo
// vinculado para exibição de específicos, busca por nome e estado vazio.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_dropdown_field.dart';

import '../../../exercises/data/models/trainer_linked_horse.dart';
import '../../application/controllers/training_registration_controller.dart';
import '../../data/models/training_exercise_item.dart';
import 'training_exercise_cards.dart';

/// Abre o bottom sheet modal da galeria de exercícios do treinador.
Future<void> showExerciseGalleryBottomSheet({
  required BuildContext context,
  required TrainingRegistrationController controller,
  required List<TrainingExerciseItem> selectedExercises,
  required ValueChanged<List<TrainingExerciseItem>> onSelectionChanged,
  required VoidCallback onCreateExercise,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => ExerciseGalleryBottomSheet(
      controller: controller,
      initialSelectedExercises: selectedExercises,
      onSelectionChanged: onSelectionChanged,
      onCreateExercise: () {
        Navigator.of(sheetContext).pop();
        onCreateExercise();
      },
    ),
  );
}

/// Bottom sheet que lista por padrão os exercícios genéricos cadastrados pelo
/// treinador e alterna para os específicos ao selecionar um cavalo vinculado.
class ExerciseGalleryBottomSheet extends StatefulWidget {
  const ExerciseGalleryBottomSheet({
    required this.controller,
    required this.initialSelectedExercises,
    required this.onSelectionChanged,
    required this.onCreateExercise,
    super.key,
  });

  final TrainingRegistrationController controller;
  final List<TrainingExerciseItem> initialSelectedExercises;
  final ValueChanged<List<TrainingExerciseItem>> onSelectionChanged;
  final VoidCallback onCreateExercise;

  @override
  State<ExerciseGalleryBottomSheet> createState() =>
      _ExerciseGalleryBottomSheetState();
}

class _ExerciseGalleryBottomSheetState
    extends State<ExerciseGalleryBottomSheet> {
  final TextEditingController _searchController = TextEditingController();

  List<TrainerLinkedHorse> _linkedHorses = const [];
  List<TrainingExerciseItem> _exercises = const [];
  late final List<TrainingExerciseItem> _selectedExercises;

  TrainerLinkedHorse? _selectedHorse;
  bool _isDropdownOpen = false;
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasGenericCatalogLoadedEmpty = false;

  @override
  void initState() {
    super.initState();
    _selectedExercises = List.of(widget.initialSelectedExercises);
    _initializeGallery();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeGallery() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // Carrega a lista de cavalos vinculados para o filtro de forma independente.
    // Falha nessa chamada secundária não deve impedir a visualização dos exercícios.
    widget.controller
        .fetchLinkedHorses()
        .then((horses) {
          if (!mounted) return;
          setState(() {
            _linkedHorses = horses;
          });
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint(
            '[ExerciseGalleryBottomSheet] Falha ao carregar cavalos vinculados: $error\n$stackTrace',
          );
        });

    try {
      final exercises = await widget.controller.fetchGalleryExercises();

      if (!mounted) return;
      setState(() {
        _exercises = exercises;
        _hasGenericCatalogLoadedEmpty = exercises.isEmpty;
        _isLoading = false;
      });
    } on Object catch (error, stackTrace) {
      debugPrint(
        '[ExerciseGalleryBottomSheet] Falha ao carregar exercícios da galeria: $error\n$stackTrace',
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final exercises = await widget.controller.fetchGalleryExercises(
        searchQuery: _searchController.text,
        horseId: _selectedHorse?.id,
      );

      if (!mounted) return;
      setState(() {
        _exercises = exercises;
        if (_searchController.text.trim().isEmpty && _selectedHorse == null) {
          _hasGenericCatalogLoadedEmpty = exercises.isEmpty;
        }
        _isLoading = false;
      });
    } on Object catch (error, stackTrace) {
      debugPrint(
        '[ExerciseGalleryBottomSheet] Falha na busca/filtro de exercícios: $error\n$stackTrace',
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _onSearchChanged(String _) {
    _loadExercises();
  }

  void _onHorseSelected(TrainerLinkedHorse horse) {
    setState(() {
      _selectedHorse = horse;
      _isDropdownOpen = false;
    });
    _loadExercises();
  }

  void _clearHorseFilter() {
    setState(() {
      _selectedHorse = null;
      _isDropdownOpen = false;
    });
    _loadExercises();
  }

  bool _isExerciseSelected(TrainingExerciseItem exercise) {
    return _selectedExercises.any((item) => item.id == exercise.id);
  }

  void _toggleExerciseSelection(TrainingExerciseItem exercise) {
    setState(() {
      final index = _selectedExercises.indexWhere(
        (item) => item.id == exercise.id,
      );
      if (index >= 0) {
        _selectedExercises.removeAt(index);
      } else {
        _selectedExercises.add(exercise);
      }
    });
    widget.onSelectionChanged(List.unmodifiable(_selectedExercises));
  }

  bool get _showGlobalEmptyState =>
      !_isLoading &&
      !_hasError &&
      _hasGenericCatalogLoadedEmpty &&
      _selectedHorse == null &&
      _searchController.text.trim().isEmpty &&
      _linkedHorses.isEmpty;

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
                      'Galeria de exercícios',
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
                  ? _EmptyExerciseGallery(
                      onCreateExercise: widget.onCreateExercise,
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                key: const Key('exercise-gallery-search-input'),
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
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(14),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(14),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(14),
                                    ),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              if (_linkedHorses.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: AppDropdownField<TrainerLinkedHorse>(
                                        dropdownKey: const Key(
                                          'exercise-gallery-horse-dropdown',
                                        ),
                                        style: AppDropdownStyle.rounded,
                                        label: 'Selecionar cavalo',
                                        value: _selectedHorse,
                                        options: _linkedHorses,
                                        isOpen: _isDropdownOpen,
                                        labelFor: (horse) => horse.name,
                                        onTap: () => setState(
                                          () => _isDropdownOpen = true,
                                        ),
                                        onChanged: _onHorseSelected,
                                      ),
                                    ),
                                    if (_selectedHorse != null) ...[
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 52,
                                        height: 52,
                                        child: Material(
                                          color: const Color(0xFFE0E0E0),
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(14),
                                          ),
                                          child: InkWell(
                                            key: const Key(
                                              'clear-exercise-gallery-horse-filter',
                                            ),
                                            borderRadius:
                                                const BorderRadius.all(
                                                  Radius.circular(14),
                                                ),
                                            onTap: _clearHorseFilter,
                                            child: const Icon(
                                              Icons.close_rounded,
                                              color: AppColors.text,
                                              size: 26,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ] else
                                      const Spacer(),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: _buildGalleryList(theme),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryList(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Não foi possível carregar os exercícios.',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const Key('retry-exercise-gallery-load'),
                onPressed: _loadExercises,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_exercises.isEmpty) {
      if (_selectedHorse == null && _searchController.text.trim().isEmpty) {
        return _EmptyExerciseGallery(onCreateExercise: widget.onCreateExercise);
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Nenhum exercício encontrado para o filtro aplicado.',
            key: const Key('empty-filtered-exercise-gallery'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.grey,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      key: const Key('exercise-gallery-list'),
      padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
      itemCount: _exercises.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final exercise = _exercises[index];
        return GalleryExerciseSelectableCard(
          cardKey: ValueKey('gallery-exercise-card-${exercise.id}'),
          exercise: exercise,
          isSelected: _isExerciseSelected(exercise),
          onToggle: () => _toggleExerciseSelection(exercise),
        );
      },
    );
  }
}

class _EmptyExerciseGallery extends StatelessWidget {
  const _EmptyExerciseGallery({required this.onCreateExercise});

  final VoidCallback onCreateExercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.block_rounded,
                  key: Key('empty-exercise-gallery-icon'),
                  color: AppColors.text,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    'Nenhum exercício criado',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Crie agora mesmo um exercício para montar a sessão de treinamento ideal para os cavalos.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.text,
                fontSize: 18,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: FilledButton.icon(
                key: const Key('gallery-empty-create-exercise-button'),
                onPressed: onCreateExercise,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.seaGreen,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.add_box_outlined, size: 24),
                label: const Text('Criar exercício'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
