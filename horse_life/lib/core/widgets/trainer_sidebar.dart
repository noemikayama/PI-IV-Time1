// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Substituição do item provisório "Item 1" pelo link funcional
// "Cadastrar plano de treino" na barra lateral do treinador.
//
// Data: 17/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição do link funcional "Cadastrar treinamento" na barra lateral
// do treinador para abertura direta do fluxo de cadastro de treinamentos.
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição do link funcional "Cadastrar cavalo" na barra lateral do
// treinador para abertura direta do fluxo de cadastro de cavalos.
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Substituição do primeiro item provisório da barra lateral pelo
// link funcional para o fluxo de cadastro de exercícios.
//
// Data: 27/10/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Migração do componente para core/widgets com ajuste dos imports.
//
// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Remoção de especialidade fictícia quando getHome não informa
// a modalidade do treinador.
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão de integração e compatibilidade com a arquitetura
// Repository/Mapper/Service, sem alterar a composição visual aprovada.
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação do menu lateral do Profissional com especialidade,
// quantidade de cavalos vinculados e saída protegida contra toques repetidos.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/features/exercises/presentation/routes/exercise_registration_flow_route.dart';
import 'package:horse_life/features/home/data/models/trainer_home_data.dart';
import 'package:horse_life/features/horses/presentation/routes/horse_registration_flow_route.dart';
import 'package:horse_life/features/training_plans/presentation/routes/training_plan_registration_flow_route.dart';
import 'package:horse_life/features/trainings/presentation/routes/training_registration_flow_route.dart';

class TrainerSidebar extends StatefulWidget {
  const TrainerSidebar({
    super.key,
    required this.onLogout,
    required this.homeFuture,
    this.onCreateExercise,
    this.onRegisterHorse,
    this.onCreateTraining,
    this.onCreateTrainingPlan,
  });

  final Future<void> Function() onLogout;
  final Future<TrainerHomeData> homeFuture;

  /// Callback opcional que permite sobrescrever a abertura do fluxo de cadastro
  /// de exercícios em composições externas ou testes.
  final VoidCallback? onCreateExercise;

  /// Callback opcional que permite sobrescrever a abertura do fluxo de cadastro
  /// de cavalos em composições externas ou testes.
  final VoidCallback? onRegisterHorse;

  /// Callback opcional que permite sobrescrever a abertura do fluxo de cadastro
  /// de treinamentos em composições externas ou testes.
  final VoidCallback? onCreateTraining;

  /// Callback opcional que permite sobrescrever a abertura do fluxo de cadastro
  /// de planos de treinamento em composições externas ou testes.
  final VoidCallback? onCreateTrainingPlan;

  @override
  State<TrainerSidebar> createState() => _TrainerSidebarState();
}

class _TrainerSidebarState extends State<TrainerSidebar> {
  bool _isLoggingOut = false;

  // Fecha o menu lateral e direciona o treinador ao fluxo de criação de exercícios.
  void _handleCreateExercise() {
    final navigator = Navigator.of(context);
    navigator.pop();

    final onCreateExercise = widget.onCreateExercise;
    if (onCreateExercise != null) {
      onCreateExercise();
      return;
    }

    navigator.push(ExerciseRegistrationFlowRoute.build());
  }

  // Fecha o menu lateral e direciona o treinador ao fluxo de cadastro de cavalos.
  void _handleRegisterHorse() {
    final navigator = Navigator.of(context);
    navigator.pop();

    final onRegisterHorse = widget.onRegisterHorse;
    if (onRegisterHorse != null) {
      onRegisterHorse();
      return;
    }

    navigator.push(HorseRegistrationFlowRoute.build());
  }

  // Fecha o menu lateral e direciona o treinador ao fluxo de cadastro de treinamentos.
  void _handleCreateTraining() {
    final navigator = Navigator.of(context);
    navigator.pop();

    final onCreateTraining = widget.onCreateTraining;
    if (onCreateTraining != null) {
      onCreateTraining();
      return;
    }

    navigator.push(TrainingRegistrationFlowRoute.build());
  }

  // Fecha o menu lateral e direciona o treinador ao fluxo de cadastro de planos.
  void _handleCreateTrainingPlan() {
    final navigator = Navigator.of(context);
    navigator.pop();

    final onCreateTrainingPlan = widget.onCreateTrainingPlan;
    if (onCreateTrainingPlan != null) {
      onCreateTrainingPlan();
      return;
    }

    navigator.push(TrainingPlanRegistrationFlowRoute.build());
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await widget.onLogout();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline,
        message: 'Não foi possível sair. Tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      backgroundColor: AppColors.blueSpruce,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<TrainerHomeData>(
                future: widget.homeFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  return Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.alabasterGray,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data?.trainerName ?? '<Usuário>',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              data?.specialty?.trim().isNotEmpty == true
                                  ? 'Treinador de ${data!.specialty}'
                                  : 'Profissional',
                              maxLines: 2,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Animais vinculados: ${data?.linkedHorsesCount ?? 0}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              const Divider(color: AppColors.alabasterGray),
              const SizedBox(height: 12),
              ListTile(
                key: const Key('trainer-sidebar-create-exercise'),
                contentPadding: EdgeInsets.zero,
                minTileHeight: 48,
                leading: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                title: Text(
                  'Cadastrar exercício',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                onTap: _handleCreateExercise,
              ),
              ListTile(
                key: const Key('trainer-sidebar-register-horse'),
                contentPadding: EdgeInsets.zero,
                minTileHeight: 48,
                leading: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                title: Text(
                  'Cadastrar cavalo',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                onTap: _handleRegisterHorse,
              ),
              ListTile(
                key: const Key('trainer-sidebar-create-training'),
                contentPadding: EdgeInsets.zero,
                minTileHeight: 48,
                leading: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                title: Text(
                  'Cadastrar treinamento',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                onTap: _handleCreateTraining,
              ),
              ListTile(
                key: const Key('trainer-sidebar-create-training-plan'),
                contentPadding: EdgeInsets.zero,
                minTileHeight: 48,
                leading: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                title: Text(
                  'Cadastrar plano de treino',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                onTap: _handleCreateTrainingPlan,
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.alabasterGray),
              const SizedBox(height: 8),
              ListTile(
                enabled: !_isLoggingOut,
                contentPadding: EdgeInsets.zero,
                leading: _isLoggingOut
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.logout_rounded, color: Colors.white),
                title: Text(
                  _isLoggingOut ? 'Saindo...' : 'Sair',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                onTap: _isLoggingOut ? null : _handleLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

