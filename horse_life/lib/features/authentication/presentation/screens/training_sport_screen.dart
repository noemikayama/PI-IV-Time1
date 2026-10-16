// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da terceira etapa do treinador para carregamento e seleção
// da modalidade de treinos, com padronização para o termo sport, atualização do
// estado exclusivo do treinador e navegação para experiências profissionais.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../application/controllers/registration_controller.dart';
import '../../application/states/registration_draft.dart';
import '../../data/repositories/training_sport_repository.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_next_button.dart';
import '../widgets/registration_progress_indicator.dart';
import 'trainer_experience_screen.dart';

typedef TrainingSportCallback =
    void Function(TrainerRegistrationDraft registration);

// Terceira etapa do treinador, alimentada por uma fonte assíncrona de opções.
class TrainingSportScreen extends StatefulWidget {
  const TrainingSportScreen({
    required this.registration,
    required this.sportRepository,
    this.registrationController,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainerRegistrationDraft registration;
  final TrainingSportRepository sportRepository;
  final RegistrationController? registrationController;
  final TrainingSportCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<TrainingSportScreen> createState() => _TrainingSportScreenState();
}

class _TrainingSportScreenState extends State<TrainingSportScreen> {
  List<String> _sports = const [];
  String? _selectedSport;
  bool _isLoading = true;
  bool _hasLoadError = false;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _loadSports();
  }

  // Normaliza e remove duplicatas do array recebido antes de exibi-lo.
  Future<void> _loadSports() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
    });

    try {
      final response = await widget.sportRepository.fetchSports();
      final sports = response
          .map((sport) => sport.trim())
          .where((sport) => sport.isNotEmpty)
          .toSet()
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _sports = sports;
        _selectedSport = sports.firstOrNull;
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

  // Preserva a modalidade escolhida no draft entregue à próxima etapa.
  void _continue() {
    final selectedSport = _selectedSport;
    if (selectedSport == null) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Selecione uma modalidade para continuar.',
      );
      return;
    }

    final updatedRegistration = widget.registration.withSport(selectedSport);
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedRegistration);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TrainerExperienceScreen(
          registration: updatedRegistration,
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
                            const RegistrationProgressIndicator(
                              configuration:
                                  RegistrationProgressConfiguration.trainer,
                              currentStep: 3,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Modalidade de treinos',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Selecione qual modalidade de\nesporte você leciona.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            _buildSportField(context),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key('continue-training-sport'),
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

  Widget _buildSportField(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('training-sports-loading')),
      );
    }

    if (_hasLoadError) {
      return Column(
        children: [
          const Text(
            'Não foi possível carregar as modalidades.',
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: _loadSports,
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    }

    if (_sports.isEmpty) {
      return const Text(
        'Nenhuma modalidade disponível no momento.',
        textAlign: TextAlign.center,
      );
    }

    return InputDecorator(
      decoration: InputDecoration(
        labelText: _isMenuOpen ? 'Selecionar Modalidade' : null,
        labelStyle: const TextStyle(color: AppColors.seaGreen),
        filled: true,
        fillColor: const Color(0xFFE9E9E9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: _isMenuOpen ? AppColors.seaGreen : Colors.transparent,
            width: 2,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(18)),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: const Key('training-sport-dropdown'),
          value: _selectedSport,
          isExpanded: true,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          dropdownColor: Colors.white,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.text,
            size: 32,
          ),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.text,
            fontSize: 20,
          ),
          selectedItemBuilder: (context) => [
            for (final sport in _sports)
              Align(alignment: Alignment.centerLeft, child: Text(sport)),
          ],
          items: [
            for (final sport in _sports)
              DropdownMenuItem<String>(
                value: sport,
                child: Container(
                  height: 52,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: sport == _selectedSport
                        ? AppColors.seaGreen
                        : Colors.transparent,
                    borderRadius: const BorderRadius.all(Radius.circular(13)),
                  ),
                  child: Row(
                    children: [
                      if (sport == _selectedSport) ...[
                        const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        sport,
                        style: TextStyle(
                          color: sport == _selectedSport
                              ? Colors.white
                              : AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          onTap: () => setState(() => _isMenuOpen = true),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedSport = value;
              _isMenuOpen = false;
            });
          },
        ),
      ),
    );
  }
}
