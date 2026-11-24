// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 09/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Uso do dropdown compartilhado, preservando a busca remota e o
// visual da seleção de modalidades.
//
// Data: 27/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos e segmentos do código de autenticação,
// detalhando responsabilidades, fluxo de dados e integração entre camadas.
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Ajuste do dropdown para quebrar modalidades longas entre palavras
// e adaptar a altura dos itens sem causar overflow.
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
import '../../../../core/widgets/app_dropdown_field.dart';
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
  // Resultado remoto, seleção atual e estados visuais do dropdown assíncrono.
  List<String> _sports = const [];
  String? _selectedSport;
  bool _isLoading = true;
  bool _hasLoadError = false;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    // A consulta começa assim que a etapa entra na árvore de widgets.
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
    // Testes podem assumir o retorno; em produção a pilha é a fonte de verdade.
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
    // Cada estado remoto ocupa o mesmo espaço lógico do campo de modalidade.
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

    // O InputDecorator mantém o dropdown consistente com os demais formulários.
    return AppDropdownField<String>(
      style: AppDropdownStyle.rounded,
      label: 'Selecionar Modalidade',
      dropdownKey: const Key('training-sport-dropdown'),
      value: _selectedSport,
      options: _sports,
      labelFor: (sport) => sport,
      isOpen: _isMenuOpen,
      onTap: () => setState(() => _isMenuOpen = true),
      onChanged: (value) => setState(() {
        _selectedSport = value;
        _isMenuOpen = false;
      }),
    );
  }
}
