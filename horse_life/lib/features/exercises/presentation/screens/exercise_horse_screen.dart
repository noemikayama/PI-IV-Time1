// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Usa dependências reais por padrão e conserva injeção para testes.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Injeção flexível de TrainerLinkedHorseRepository com fallback
// local para isolamento de testes de widget.
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adoção do componente unificado FormProgressIndicator proveniente
// de core/widgets.
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da primeira etapa do fluxo de exercício específico para
// carregamento e seleção do cavalo vinculado ao treinador, inicializando a
// trilha de 8 etapas e navegando para a etapa de nome do exercício.
// -----------------------------------------------------------------------------

import 'package:horse_life/features/exercises/data/repositories/firebase_trainer_linked_horse_repository.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_dropdown_field.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/form_progress_indicator.dart';
import '../../../authentication/presentation/widgets/auth_header.dart';
import '../../../authentication/presentation/widgets/auth_next_button.dart';
import '../../application/controllers/exercise_registration_controller.dart';
import '../../application/states/exercise_registration_draft.dart';
import '../../data/models/trainer_linked_horse.dart';
import '../../data/repositories/trainer_linked_horse_repository.dart';
import '../widgets/no_linked_horses_dialog.dart';
import 'exercise_name_screen.dart';

typedef ExerciseHorseCallback =
    void Function(SpecificExerciseRegistrationDraft draft);

// Primeira etapa exclusiva do fluxo de exercício específico (etapa 1 de 8),
// alimentada pela fonte assíncrona de animais vinculados ao treinador.
class ExerciseHorseScreen extends StatefulWidget {
  const ExerciseHorseScreen({
    this.horseRepository = const FirebaseTrainerLinkedHorseRepository(),
    this.initialHorses,
    this.initialSelectedHorse,
    this.registrationController,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainerLinkedHorseRepository horseRepository;
  final List<TrainerLinkedHorse>? initialHorses;
  final TrainerLinkedHorse? initialSelectedHorse;
  final ExerciseRegistrationController? registrationController;
  final ExerciseHorseCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<ExerciseHorseScreen> createState() => _ExerciseHorseScreenState();
}

class _ExerciseHorseScreenState extends State<ExerciseHorseScreen> {
  // Coleção de cavalos vinculados, seleção atual e estados visuais do seletor.
  List<TrainerLinkedHorse> _horses = const [];
  TrainerLinkedHorse? _selectedHorse;
  bool _isLoading = true;
  bool _hasLoadError = false;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    final initialHorses = widget.initialHorses;
    if (initialHorses != null && initialHorses.isNotEmpty) {
      _horses = List.unmodifiable(initialHorses);
      _selectedHorse = widget.initialSelectedHorse ?? _horses.first;
      _isLoading = false;
      return;
    }
    _loadHorses();
  }

  // Busca e normaliza os cavalos vinculados ao treinador a partir da fonte
  // configurada (repositório Firebase ou implementação injetada).
  Future<void> _loadHorses() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final response = widget.registrationController != null
          ? await widget.registrationController!.fetchLinkedHorses()
          : await widget.horseRepository.fetchLinkedHorses();
      final horses = response
          .map(
            (horse) => TrainerLinkedHorse(
              id: horse.id.trim(),
              name: horse.name.trim(),
            ),
          )
          .where((horse) => horse.name.isNotEmpty)
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _horses = horses;
        _selectedHorse = widget.initialSelectedHorse ?? horses.firstOrNull;
        _isLoading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasLoadError = true;
      });
    }
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  // Consolida o cavalo selecionado no draft específico e avança para o nome.
  Future<void> _continue() async {
    if (_horses.isEmpty) {
      await showNoLinkedHorsesDialog(context);
      return;
    }

    final selectedHorse = _selectedHorse;
    if (selectedHorse == null) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Selecione um cavalo para continuar.',
      );
      return;
    }

    final draft = SpecificExerciseRegistrationDraft(horse: selectedHorse);
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(draft);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ExerciseNameScreen.specific(
          draft: draft,
          registrationController: widget.registrationController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 18, 32, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(onBack: _goBack),
                    const SizedBox(height: 44),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const FormProgressIndicator(
                              configuration:
                                  FormProgressConfiguration.specificExercise,
                              currentStep: 1,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Cavalo vinculado',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Selecione para qual animal o\n'
                              'exercício está sendo prescrito.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            _buildHorseField(context),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key('continue-exercise-horse'),
                              onPressed: _isLoading ? null : _continue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHorseField(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('exercise-linked-horses-loading'),
        ),
      );
    }

    if (_hasLoadError) {
      return Column(
        children: [
          const Text(
            'Não foi possível carregar os animais vinculados.',
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: _loadHorses,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }

    if (_horses.isEmpty) {
      return const Text(
        'Nenhum animal vinculado no momento.',
        textAlign: TextAlign.center,
      );
    }

    return AppDropdownField<TrainerLinkedHorse>(
      style: AppDropdownStyle.rounded,
      label: 'Selecionar cavalo',
      dropdownKey: const Key('exercise-horse-dropdown'),
      value: _selectedHorse,
      options: _horses,
      labelFor: (horse) => horse.name,
      isOpen: _isMenuOpen,
      onTap: () => setState(() => _isMenuOpen = true),
      onChanged: (value) => setState(() {
        _selectedHorse = value;
        _isMenuOpen = false;
      }),
    );
  }
}
