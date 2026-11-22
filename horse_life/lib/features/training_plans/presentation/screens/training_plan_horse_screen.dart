// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Usa dependências reais por padrão e conserva injeção para testes.
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da terceira etapa do cadastro de planos de treinamento
// (Seleção do animal), carregando cavalos vinculados ao treinador, exibindo
// diálogo de bloqueio quando sem vínculos e avançando para data de início.
// -----------------------------------------------------------------------------

import 'package:horse_life/features/exercises/data/repositories/firebase_trainer_linked_horse_repository.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_dropdown_field.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../../exercises/data/models/trainer_linked_horse.dart';
import '../../../exercises/data/repositories/trainer_linked_horse_repository.dart';
import '../../../exercises/presentation/widgets/no_linked_horses_dialog.dart';
import '../../application/controllers/training_plan_registration_controller.dart';
import '../../application/states/training_plan_registration_draft.dart';
import 'training_plan_start_date_screen.dart';

typedef TrainingPlanHorseCallback =
    void Function(TrainingPlanRegistrationDraft draft);

/// Etapa 3 de 7: Seleção do cavalo vinculado ao qual o plano será prescrito.
class TrainingPlanHorseScreen extends StatefulWidget {
  const TrainingPlanHorseScreen({
    required this.draft,
    this.controller,
    this.horseRepository = const FirebaseTrainerLinkedHorseRepository(),
    this.initialHorses,
    this.initialSelectedHorse,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainingPlanRegistrationDraft draft;
  final TrainingPlanRegistrationController? controller;
  final TrainerLinkedHorseRepository horseRepository;
  final List<TrainerLinkedHorse>? initialHorses;
  final TrainerLinkedHorse? initialSelectedHorse;
  final TrainingPlanHorseCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<TrainingPlanHorseScreen> createState() =>
      _TrainingPlanHorseScreenState();
}

class _TrainingPlanHorseScreenState extends State<TrainingPlanHorseScreen> {
  List<TrainerLinkedHorse> _horses = const [];
  TrainerLinkedHorse? _selectedHorse;
  bool _isLoading = true;
  bool _hasLoadError = false;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    final initialHorses = widget.initialHorses;
    if (initialHorses != null) {
      _horses = List.unmodifiable(initialHorses);
      _selectedHorse = _resolveInitialSelection(initialHorses);
      _isLoading = false;
      return;
    }
    _loadHorses();
  }

  TrainerLinkedHorse? _resolveInitialSelection(List<TrainerLinkedHorse> horses) {
    final candidate = widget.initialSelectedHorse ?? widget.draft.horse;
    if (candidate == null) return null;
    for (final horse in horses) {
      if (horse.id == candidate.id) return horse;
    }
    return null;
  }

  Future<void> _loadHorses() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final response = widget.controller != null
          ? await widget.controller!.fetchLinkedHorses()
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
        _selectedHorse = _resolveInitialSelection(horses);
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

    final updatedDraft = widget.draft.withHorse(selectedHorse);
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TrainingPlanStartDateScreen(
          draft: updatedDraft,
          controller: widget.controller,
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
                                  FormProgressConfiguration.trainingPlan,
                              currentStep: 3,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Seleção do animal',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Selecione para qual cavalo este\n'
                              'plano está sendo prescrito.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            _buildHorseField(),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-training-plan-horse',
                              ),
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

  Widget _buildHorseField() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('training-plan-linked-horses-loading'),
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
      dropdownKey: const Key('training-plan-horse-dropdown'),
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
