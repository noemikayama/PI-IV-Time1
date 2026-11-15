// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Propagação de repositório e controller pela árvore de navegação
// conectada à ExerciseRegistrationFlowRoute.
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela inicial de seleção do tipo de exercício (nível de
// privacidade), com validação de animais vinculados ao avançar pelo fluxo
// específico e direcionamento para a trilha de 8 ou 7 etapas.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_dropdown_field.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../authentication/presentation/widgets/auth_header.dart';
import '../../../authentication/presentation/widgets/auth_next_button.dart';
import '../../../authentication/presentation/widgets/profile_information_row.dart';
import '../../application/controllers/exercise_registration_controller.dart';
import '../../data/models/exercise_type.dart';
import '../../data/models/trainer_linked_horse.dart';
import '../../data/repositories/trainer_linked_horse_repository.dart';
import '../widgets/no_linked_horses_dialog.dart';
import 'exercise_horse_screen.dart';
import 'exercise_name_screen.dart';

typedef ExerciseTypeSelectionCallback = void Function(ExerciseType exerciseType);

// Tela preliminar que coleta o nível de privacidade do exercício e define se o
// fluxo subsequente terá 8 etapas (específico, iniciando pelo cavalo) ou
// 7 etapas (genérico, iniciando diretamente pelo nome).
class ExerciseTypeSelectionScreen extends StatefulWidget {
  const ExerciseTypeSelectionScreen({
    this.onContinue,
    this.onBack,
    this.registrationController,
    this.horseRepository = const LocalTrainerLinkedHorseRepository(),
    super.key,
  });

  // Contratos opcionais para testes, coordenação externa e consulta de cavalos.
  final ExerciseTypeSelectionCallback? onContinue;
  final VoidCallback? onBack;
  final ExerciseRegistrationController? registrationController;
  final TrainerLinkedHorseRepository horseRepository;

  @override
  State<ExerciseTypeSelectionScreen> createState() =>
      _ExerciseTypeSelectionScreenState();
}

class _ExerciseTypeSelectionScreenState
    extends State<ExerciseTypeSelectionScreen> {
  // O tipo específico é a opção inicial apresentada na prototipação.
  ExerciseType _selectedType = ExerciseType.specific;
  bool _isMenuOpen = false;
  bool _isCheckingHorses = false;

  // Retorno injetável com fallback para a pilha de navegação.
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  // Consulta os animais vinculados pelo controller ou pelo repositório injetado.
  Future<List<TrainerLinkedHorse>> _fetchLinkedHorses() async {
    final controller = widget.registrationController;
    if (controller != null) {
      return controller.fetchLinkedHorses();
    }

    final response = await widget.horseRepository.fetchLinkedHorses();
    return response
        .map(
          (horse) => TrainerLinkedHorse(
            id: horse.id.trim(),
            name: horse.name.trim(),
          ),
        )
        .where((horse) => horse.name.isNotEmpty)
        .toList(growable: false);
  }

  // Valida a existência de cavalos vinculados quando o exercício é específico e
  // encaminha para a primeira etapa correspondente ao tipo selecionado.
  Future<void> _continue() async {
    if (_isCheckingHorses) return;

    if (_selectedType == ExerciseType.generic) {
      final onContinue = widget.onContinue;
      if (onContinue != null) {
        onContinue(ExerciseType.generic);
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => ExerciseNameScreen.generic(
            registrationController: widget.registrationController,
          ),
        ),
      );
      return;
    }

    setState(() => _isCheckingHorses = true);
    try {
      final horses = await _fetchLinkedHorses();
      if (!mounted) return;

      if (horses.isEmpty) {
        setState(() => _isCheckingHorses = false);
        await showNoLinkedHorsesDialog(context);
        return;
      }

      setState(() => _isCheckingHorses = false);
      final onContinue = widget.onContinue;
      if (onContinue != null) {
        onContinue(ExerciseType.specific);
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => ExerciseHorseScreen(
            horseRepository: widget.horseRepository,
            initialHorses: horses,
            registrationController: widget.registrationController,
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      setState(() => _isCheckingHorses = false);
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Não foi possível verificar os animais vinculados.',
      );
    }
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
                    const SizedBox(height: 64),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Tipo de exercício',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Antes dos próximos passos,\n'
                              'precisamos saber qual será o nível\n'
                              'de privacidade do exercício criado.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Seletor arredondado compartilhado com rótulo de
                            // borda ativo quando o menu está aberto.
                            AppDropdownField<ExerciseType>(
                              style: AppDropdownStyle.rounded,
                              label: 'Selecionar privacidade',
                              dropdownKey: const Key('exercise-type-dropdown'),
                              value: _selectedType,
                              options: ExerciseType.values,
                              labelFor: (type) => type.label,
                              isOpen: _isMenuOpen,
                              onTap: () => setState(() => _isMenuOpen = true),
                              onChanged: (value) => setState(() {
                                _selectedType = value;
                                _isMenuOpen = false;
                              }),
                            ),
                            const SizedBox(height: 36),
                            // Orientações que diferenciam os dois níveis de
                            // privacidade do exercício.
                            const InformationRow(
                              text:
                                  'Exercícios específicos são aqueles '
                                  'criados para apenas um cavalo e '
                                  'que não ficam disponíveis em seu '
                                  'acervo pessoal.',
                            ),
                            const SizedBox(height: 24),
                            const InformationRow(
                              text:
                                  'Exercícios genéricos são aqueles '
                                  'que podem ser reutilizados na '
                                  'criação de treinamentos e planos, '
                                  'envolvendo as práticas comumente '
                                  'realizadas.',
                            ),
                            const SizedBox(height: 64),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-exercise-type-selection',
                              ),
                              isLoading: _isCheckingHorses,
                              onPressed: _continue,
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
}
