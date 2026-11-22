// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Conexão do botão "Ver detalhes" dos cards de treinamento à nova
// tela TrainingDetailScreen com recarregamento em caso de edição do treino.
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Retorno automático para a tela anterior com atualização de estado
// e exibição da SnackBar após cancelamento bem-sucedido do plano.
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela de visualização de plano de treinamento utilizando
// seções recolhíveis, carrossel semanal de treinamentos, empty state de
// avaliação vinculada, permissões por treinador proprietário e ações de
// edição e cancelamento integradas ao repositório.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/collapsible_section_card.dart';
import 'package:horse_life/core/widgets/destructive_confirmation_dialog.dart';
import 'package:horse_life/core/widgets/gradient_button.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';

import '../../../exercises/data/repositories/trainer_linked_horse_repository.dart';
import '../../../trainings/application/controllers/training_registration_controller.dart';
import '../../../trainings/presentation/screens/training_detail_screen.dart';
import '../../application/controllers/training_plan_registration_controller.dart';
import '../../data/models/training_plan_gallery_item.dart';
import '../../data/models/training_plan_weekday.dart';
import '../../data/repositories/firebase_training_plan_repository.dart';
import '../../data/repositories/training_plan_repository.dart';
import '../widgets/training_plan_cards.dart';
import 'training_plan_edit_screen.dart';

typedef TrainingPlanCancellationRequested =
    Future<void> Function(TrainingPlanDetailData plan);

/// Tela de visualização completa de um plano de treinamento.
class TrainingPlanDetailScreen extends StatefulWidget {
  const TrainingPlanDetailScreen({
    required this.planId,
    this.currentUserId,
    this.isTrainer = false,
    this.repository = const FirebaseTrainingPlanRepository(),
    this.horseRepository = const LocalTrainerLinkedHorseRepository(),
    this.trainingRegistrationController,
    this.onOpenTrainingAgenda,
    this.onViewTrainingDetails,
    this.onCancelPlan,
    this.onNavigationSelected,
    this.onBack,
    super.key,
  });

  final String planId;
  final String? currentUserId;
  final bool isTrainer;
  final TrainingPlanRepository repository;
  final TrainerLinkedHorseRepository horseRepository;
  final TrainingRegistrationController? trainingRegistrationController;
  final VoidCallback? onOpenTrainingAgenda;
  final ValueChanged<TrainingPlanGalleryItem>? onViewTrainingDetails;
  final TrainingPlanCancellationRequested? onCancelPlan;
  final ValueChanged<HomeNavigationDestination>? onNavigationSelected;
  final VoidCallback? onBack;

  @override
  State<TrainingPlanDetailScreen> createState() =>
      _TrainingPlanDetailScreenState();
}

class _TrainingPlanDetailScreenState extends State<TrainingPlanDetailScreen> {
  late Future<TrainingPlanDetailData> _planFuture;
  int _currentTrainingIndex = 0;
  bool _isProcessingAction = false;
  bool _wasPlanModified = false;

  @override
  void initState() {
    super.initState();
    _planFuture = widget.repository.getTrainingPlan(widget.planId);
  }

  void _reload() {
    setState(() {
      _currentTrainingIndex = 0;
      _planFuture = widget.repository.getTrainingPlan(widget.planId);
    });
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(_wasPlanModified);
    }
  }

  void _selectNavigationDestination(HomeNavigationDestination destination) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(destination);
    } else {
      widget.onNavigationSelected?.call(destination);
    }
  }

  void _openTrainingAgenda() {
    final onOpenTrainingAgenda = widget.onOpenTrainingAgenda;
    if (onOpenTrainingAgenda != null) {
      onOpenTrainingAgenda();
      return;
    }
    _selectNavigationDestination(HomeNavigationDestination.trainings);
  }

  void _handleViewTrainingDetails(TrainingPlanGalleryItem training) {
  Future<void> _handleViewTrainingDetails(
    TrainingPlanGalleryItem training, {
    TrainingPlanDetailData? plan,
  }) async {
    final callback = widget.onViewTrainingDetails;
    if (callback != null) {
      callback(training);
      return;
    }
    AppSnackBar.show(
      context,
      backgroundColor: AppColors.blueSpruce,
      icon: Icons.info_outline_rounded,
      message: 'Visualização detalhada do treinamento ainda não disponível.',
    );

    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (_) => TrainingDetailScreen(
          trainingCode: training.code > 0
              ? training.code.toString()
              : training.id,
          initialTraining: training,
          currentUserId: widget.currentUserId,
          trainerId: plan?.trainerId,
          isTrainer: widget.isTrainer,
          isOwner: plan?.canManage(
            currentUserId: widget.currentUserId,
            isTrainer: widget.isTrainer,
          ),
          trainingRegistrationController: widget.trainingRegistrationController,
          onNavigationSelected: (destination) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(destination);
            }
          },
        ),
      ),
    );
    if (!mounted || result == null) return;
    if (result is HomeNavigationDestination) {
      _selectNavigationDestination(result);
      return;
    }
    if (result == true) {
      _wasPlanModified = true;
      _reload();
    }
  }

  Future<void> _editPlan(TrainingPlanDetailData plan) async {
    if (_isProcessingAction) return;

    final update = await Navigator.of(context).push<TrainingPlanUpdate>(
      MaterialPageRoute<TrainingPlanUpdate>(
        builder: (_) => TrainingPlanEditScreen(
          plan: plan,
          controller: TrainingPlanRegistrationController(
            horseRepository: widget.horseRepository,
            planRepository: widget.repository,
          ),
          horseRepository: widget.horseRepository,
          trainingRegistrationController: widget.trainingRegistrationController,
        ),
      ),
    );
    if (update == null || !mounted) return;

    setState(() => _isProcessingAction = true);
    try {
      final updated = await widget.repository.updateTrainingPlan(
        plan.id,
        update,
      );
      if (!mounted) return;
      _wasPlanModified = true;
      setState(() {
        _currentTrainingIndex = 0;
        _planFuture = Future.value(updated);
      });
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline_rounded,
        message: 'Plano de treinamento atualizado com sucesso.',
      );
    } catch (error) {
      if (!mounted) return;
      _showError(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  Future<void> _requestCancelPlan(TrainingPlanDetailData plan) async {
    if (_isProcessingAction || !plan.isActive) return;

    final confirmed = await showDestructiveConfirmationDialog(
      context,
      title: 'Tem certeza que deseja cancelar esse plano?',
      message:
          'Após cancelá-lo, ele não estará mais disponível para seu atleta '
          'e não poderá ser reativado.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isProcessingAction = true);
    try {
      TrainingPlanDetailData updatedPlan;
      final externalAction = widget.onCancelPlan;
      if (externalAction != null) {
        await externalAction(plan);
        updatedPlan = plan.copyWith(status: TrainingPlanStatus.canceled);
      } else {
        final response = await widget.repository.cancelTrainingPlan(plan.id);
        updatedPlan = response.title.trim().isEmpty
            ? plan.copyWith(status: response.status)
            : response;
      }

      if (!mounted) return;
      _wasPlanModified = true;
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline_rounded,
        message: 'Plano cancelado com sucesso.',
      );
      final onBack = widget.onBack;
      if (onBack != null) {
        onBack();
        return;
      }
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _planFuture = Future.value(updatedPlan);
        });
      }
    } catch (error) {
      if (!mounted) return;
      _showError(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _isProcessingAction = false);
    }
  }

  void _showError(String message) {
    AppSnackBar.show(
      context,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline_rounded,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottomNavigationBar: HomeBottomNavBar(
          selectedDestination: HomeNavigationDestination.trainings,
          onDestinationSelected: _selectNavigationDestination,
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: FutureBuilder<TrainingPlanDetailData>(
                  future: _planFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                            child: AuthHeader(onBack: _goBack),
                          ),
                          Expanded(
                            child: _LoadError(
                              message: _errorMessage(snapshot.error),
                              retry: _reload,
                            ),
                          ),
                        ],
                      );
                    }

                    final plan = snapshot.data!;
                    final canManage = plan.canManage(
                      currentUserId: widget.currentUserId,
                      isTrainer: widget.isTrainer,
                    );
                    final entries = plan.selectedWeekdayEntries;
                    final safeIndex = entries.isEmpty
                        ? 0
                        : _currentTrainingIndex.clamp(0, entries.length - 1);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 620),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AuthHeader(onBack: _goBack),
                              const SizedBox(height: 24),
                              Text(
                                plan.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              if (canManage) ...[
                                const SizedBox(height: 22),
                                _ManagementActionsRow(
                                  isActive: plan.isActive,
                                  onEdit: () => _editPlan(plan),
                                  onCancel: () => _requestCancelPlan(plan),
                                ),
                              ],
                              const SizedBox(height: 24),
                              CollapsibleSectionCard(
                                key: const Key('training-plan-data-section'),
                                title: 'Dados do plano',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _DetailInfoLine('Título', plan.title),
                                    _DetailInfoLine('Objetivo', plan.objective),
                                    _DetailInfoLine(
                                      'Início',
                                      formatAppDate(plan.startDate),
                                    ),
                                    _DetailInfoLine(
                                      'Fim',
                                      formatAppDate(plan.endDate),
                                    ),
                                    _DetailInfoLine(
                                      'Cavalo vinculado',
                                      plan.horse.name,
                                    ),
                                    if (!canManage &&
                                        plan.trainerName.trim().isNotEmpty)
                                      _DetailInfoLine(
                                        'Treinador',
                                        plan.trainerName,
                                      ),
                                    _DetailInfoLine(
                                      'Status',
                                      plan.status.label,
                                      bottomPadding: 0,
                                    ),
                                  ],
                                ),
                              ),
                              CollapsibleSectionCard(
                                key: const Key(
                                  'training-plan-weekly-trainings-section',
                                ),
                                title: 'Treinos da semana',
                                child: _WeeklyTrainingsSectionContent(
                                  entries: entries,
                                  currentIndex: safeIndex,
                                  onIndexChanged: (index) => setState(
                                    () => _currentTrainingIndex = index,
                                  ),
                                  onViewAll: _openTrainingAgenda,
                                  onViewDetails: _handleViewTrainingDetails,
                                ),
                              ),
                              CollapsibleSectionCard(
                                key: const Key(
                                  'training-plan-evaluation-section',
                                ),
                                title: 'Avaliação vinculada',
                                margin: EdgeInsets.zero,
                                child: const _LinkedEvaluationEmptyState(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isProcessingAction) ...[
                const Positioned.fill(
                  child: ModalBarrier(
                    dismissible: false,
                    color: Colors.black26,
                  ),
                ),
                const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: SizedBox(
                        key: Key('cancel-training-plan-progress'),
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
        ),
      ),
    );
  }
      bottomNavigationBar: HomeBottomNavBar(
        selectedDestination: HomeNavigationDestination.trainings,
        onDestinationSelected: _selectNavigationDestination,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: FutureBuilder<TrainingPlanDetailData>(
                future: _planFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                          child: AuthHeader(onBack: _goBack),
                        ),
                        Expanded(
                          child: _LoadError(
                            message: _errorMessage(snapshot.error),
                            retry: _reload,
                          ),
                        ),
                      ],
                    );
                  }

                  final plan = snapshot.data!;
                  final canManage = plan.canManage(
                    currentUserId: widget.currentUserId,
                    isTrainer: widget.isTrainer,
                  );
                  final entries = plan.selectedWeekdayEntries;
                  final safeIndex = entries.isEmpty
                      ? 0
                      : _currentTrainingIndex.clamp(0, entries.length - 1);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AuthHeader(onBack: _goBack),
                            const SizedBox(height: 24),
                            Text(
                              plan.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (canManage) ...[
                              const SizedBox(height: 22),
                              _ManagementActionsRow(
                                isActive: plan.isActive,
                                onEdit: () => _editPlan(plan),
                                onCancel: () => _requestCancelPlan(plan),
                              ),
                            ],
                            const SizedBox(height: 24),
                            CollapsibleSectionCard(
                              key: const Key('training-plan-data-section'),
                              title: 'Dados do plano',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _DetailInfoLine('Título', plan.title),
                                  _DetailInfoLine('Objetivo', plan.objective),
                                  _DetailInfoLine(
                                    'Início',
                                    formatAppDate(plan.startDate),
                                  ),
                                  _DetailInfoLine(
                                    'Fim',
                                    formatAppDate(plan.endDate),
                                  ),
                                  _DetailInfoLine(
                                    'Cavalo vinculado',
                                    plan.horse.name,
                                  ),
                                  if (!canManage &&
                                      plan.trainerName.trim().isNotEmpty)
                                    _DetailInfoLine(
                                      'Treinador',
                                      plan.trainerName,
                                    ),
                                  _DetailInfoLine(
                                    'Status',
                                    plan.status.label,
                                    bottomPadding: 0,
                                  ),
                                ],
                              ),
                            ),
                            CollapsibleSectionCard(
                              key: const Key(
                                'training-plan-weekly-trainings-section',
                              ),
                              title: 'Treinos da semana',
                              child: _WeeklyTrainingsSectionContent(
                                entries: entries,
                                currentIndex: safeIndex,
                                onIndexChanged: (index) => setState(
                                  () => _currentTrainingIndex = index,
                                ),
                                onViewAll: _openTrainingAgenda,
                                onViewDetails: (training) =>
                                    _handleViewTrainingDetails(
                                      training,
                                      plan: plan,
                                    ),
                              ),
                            ),
                            CollapsibleSectionCard(
                              key: const Key(
                                'training-plan-evaluation-section',
                              ),
                              title: 'Avaliação vinculada',
                              margin: EdgeInsets.zero,
                              child: const _LinkedEvaluationEmptyState(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isProcessingAction) ...[
              const Positioned.fill(
                child: ModalBarrier(dismissible: false, color: Colors.black26),
              ),
              const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: SizedBox(
                      key: Key('cancel-training-plan-progress'),
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
      ),
    ),
  );
}
}

class _ManagementActionsRow extends StatelessWidget {
  const _ManagementActionsRow({
    required this.isActive,
    required this.onEdit,
    required this.onCancel,
  });

  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: GradientButton(
            key: const Key('edit-training-plan-button'),
            onPressed: onEdit,
            icon: Icons.edit_rounded,
            label: 'Editar plano',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: isActive
              ? SizedBox(
                  height: 60,
                  child: FilledButton(
                    key: const Key('cancel-training-plan-button'),
                    onPressed: onCancel,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: const StadiumBorder(),
                      textStyle: theme.textTheme.titleLarge,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cancel_outlined,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cancelar plano',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _WeeklyTrainingsSectionContent extends StatelessWidget {
  const _WeeklyTrainingsSectionContent({
    required this.entries,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onViewAll,
    required this.onViewDetails,
  });

  final List<MapEntry<TrainingPlanWeekday, TrainingPlanGalleryItem>> entries;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback onViewAll;
  final ValueChanged<TrainingPlanGalleryItem> onViewDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (entries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('training-plan-view-all-button'),
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Ver tudo'),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.whiteSmoke,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text('Nenhum treinamento programado na semana.'),
          ),
        ],
      );
    }

    final currentEntry = entries[currentIndex];
    final currentTraining = currentEntry.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${currentEntry.key.label} (${currentIndex + 1}/${entries.length})',
                key: const Key('training-plan-weekday-header'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              key: const Key('training-plan-view-all-button'),
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.seaGreen,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Ver tudo',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.seaGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          key: const Key('training-plan-weekly-swipe-area'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -50 && currentIndex < entries.length - 1) {
              onIndexChanged(currentIndex + 1);
            } else if (velocity > 50 && currentIndex > 0) {
              onIndexChanged(currentIndex - 1);
            }
          },
          onHorizontalDragUpdate: (details) {
            if (details.primaryDelta != null &&
                details.primaryDelta! < -20 &&
                currentIndex < entries.length - 1) {
              onIndexChanged(currentIndex + 1);
            } else if (details.primaryDelta != null &&
                details.primaryDelta! > 20 &&
                currentIndex > 0) {
            if (details.primaryDelta != null && details.primaryDelta! < -20 && currentIndex < entries.length - 1) {
              onIndexChanged(currentIndex + 1);
            } else if (details.primaryDelta != null && details.primaryDelta! > 20 && currentIndex > 0) {
              onIndexChanged(currentIndex - 1);
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: SelectedDayTrainingCard(
              key: ValueKey(
                'weekly-training-card-${currentEntry.key.name}-${currentTraining.id}',
              ),
              training: currentTraining,
              showDescription: true,
              viewDetailsKey: const Key('training-plan-view-details-button'),
              onViewDetails: () => onViewDetails(currentTraining),
            ),
          ),
        ),
        if (entries.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(entries.length, (index) {
              final isSelected = index == currentIndex;
              return InkWell(
                key: Key('training-plan-page-indicator-$index'),
                onTap: () => onIndexChanged(index),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isSelected ? 24 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.grey
                          : AppColors.grey.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _LinkedEvaluationEmptyState extends StatelessWidget {
  const _LinkedEvaluationEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const Key('training-plan-evaluation-empty-state'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.block_outlined, size: 32, color: AppColors.text),
              const Icon(
                Icons.block_outlined,
                size: 32,
                color: AppColors.text,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nenhuma avaliação vinculada',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Este plano de treinamento não possui nenhuma avaliação física vinculada.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.text,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailInfoLine extends StatelessWidget {
  const _DetailInfoLine(this.label, this.value, {this.bottomPadding = 6});

  final String label;
  final String value;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: 17,
      color: AppColors.text,
      height: 1.35,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: baseStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value, style: baseStyle),
          ],
        ),
      ),
    );
  }
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

String _errorMessage(Object? error) {
  if (error is TrainingPlanDetailFailure) {
    return error.message;
  }
  if (error is TimeoutException) {
    return 'O servidor demorou para responder. Tente novamente.';
  }
  if (error is FirebaseFunctionsException) {
    return error.message ?? 'Não foi possível carregar o plano de treinamento.';
  }
  return 'Não foi possível carregar o plano de treinamento. Tente novamente.';
}
