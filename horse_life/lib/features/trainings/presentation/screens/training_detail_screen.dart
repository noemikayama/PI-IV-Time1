// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento da documentação e comentários explicativos para
// facilitar a leitura e manutenção da tela de visualização de treinamentos.
//
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela de visualização de treinamentos com seções
// recolhíveis (CollapsibleSectionCard), carrossel horizontal de exercícios
// selecionados, orientações da sessão, permissão exclusiva para edição pelo
// treinador proprietário e integração com TrainingEditScreen.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/collapsible_section_card.dart';
import 'package:horse_life/core/widgets/gradient_button.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';

import '../../../exercises/application/controllers/exercise_registration_controller.dart';
import '../../../training_plans/data/models/training_plan_gallery_item.dart';
import '../../application/controllers/training_registration_controller.dart';
import '../../data/models/training_detail_data.dart';
import '../../data/repositories/firebase_training_detail_repository.dart';
import '../../data/repositories/training_detail_repository.dart';
import 'training_edit_screen.dart';

/// Tela de visualização completa de um treinamento cadastrado.
///
/// Apresenta as informações em seções colapsáveis com o mesmo padrão visual da
/// visualização de planos ([TrainingPlanDetailScreen]):
/// 1. **Dados do treinamento**: título, descrição e tempo de duração estimada;
/// 2. **Exercícios selecionados**: carrossel com swipe horizontal (e indicador por
///    pontos) contendo nome, duração, descrição e botão "Ver detalhes" para cada
///    exercício anexado;
/// 3. **Orientações**: lista de instruções e recomendações da sessão.
///
/// O botão "Editar treino" só é exibido caso o usuário autenticado seja o treinador
/// proprietário do treinamento.
class TrainingDetailScreen extends StatefulWidget {
  const TrainingDetailScreen({
    required this.trainingCode,
    this.initialTraining,
    this.currentUserId,
    this.trainerId,
    this.isTrainer = false,
    this.isOwner,
    this.repository = const FirebaseTrainingDetailRepository(),
    this.trainingRegistrationController,
    this.exerciseRegistrationController,
    this.onViewExerciseDetails,
    this.onNavigationSelected,
    this.onBack,
    super.key,
  });

  /// Código sequencial do treinamento ou identificador do registro.
  final String trainingCode;

  /// Dados preliminares opcionais provindos do plano de treino ou da agenda.
  final TrainingPlanGalleryItem? initialTraining;

  /// UID do usuário autenticado para conferência de autoria.
  final String? currentUserId;

  /// UID do treinador proprietário do treinamento.
  final String? trainerId;

  /// Indica se a visão atual pertence ao perfil de treinador.
  final bool isTrainer;

  /// Sobrescreve explicitamente a verificação de propriedade (usado em testes).
  final bool? isOwner;

  /// Repositório de dados para busca e atualização do treinamento.
  final TrainingDetailRepository repository;

  /// Controlador compartilhado para fluxo de criação de treinos, se injetado.
  final TrainingRegistrationController? trainingRegistrationController;

  /// Controlador compartilhado para fluxo de criação de exercícios.
  final ExerciseRegistrationController? exerciseRegistrationController;

  /// Callback acionado ao tocar em "Ver detalhes" de um exercício.
  final ValueChanged<TrainingDetailExercise>? onViewExerciseDetails;

  /// Callback para navegação externa via barra inferior da Home.
  final ValueChanged<HomeNavigationDestination>? onNavigationSelected;

  /// Ação executada ao solicitar retorno para a tela anterior.
  final VoidCallback? onBack;

  @override
  State<TrainingDetailScreen> createState() => _TrainingDetailScreenState();
}

class _TrainingDetailScreenState extends State<TrainingDetailScreen> {
  // --- Estado do carregamento e interação ------------------------------------
  late Future<TrainingDetailData> _trainingFuture;
  int _currentExerciseIndex = 0;
  bool _isSavingEdit = false;
  bool _wasTrainingModified = false;

  @override
  void initState() {
    super.initState();
    _trainingFuture = _loadTraining();
  }

  /// Consulta os detalhes do treinamento no repositório.
  Future<TrainingDetailData> _loadTraining() {
    return widget.repository.getTrainingDetails(
      widget.trainingCode,
      fallbackTraining: widget.initialTraining,
    );
  }

  /// Recarrega os dados do treinamento resetando a navegação do carrossel.
  void _reload() {
    setState(() {
      _currentExerciseIndex = 0;
      _trainingFuture = _loadTraining();
    });
  }

  /// Retorna para a tela anterior informando se houve alteração nos dados.
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(_wasTrainingModified);
    }
  }

  /// Redireciona para o destino escolhido na barra de navegação inferior.
  void _selectNavigationDestination(HomeNavigationDestination destination) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(destination);
    } else {
      widget.onNavigationSelected?.call(destination);
    }
  }

  /// Trata a ação de clique em "Ver detalhes" do card de exercício.
  void _handleViewExerciseDetails(TrainingDetailExercise exercise) {
    final callback = widget.onViewExerciseDetails;
    if (callback != null) {
      callback(exercise);
      return;
    }
    AppSnackBar.show(
      context,
      backgroundColor: AppColors.blueSpruce,
      icon: Icons.info_outline_rounded,
      message: 'Visualização detalhada do exercício ainda não disponível.',
    );
  }

  /// Abre o formulário de edição do treinamento e persiste as alterações no backend.
  Future<void> _editTraining(TrainingDetailData training) async {
    if (_isSavingEdit) return;

    final update = await Navigator.of(context).push<TrainingUpdate>(
      MaterialPageRoute<TrainingUpdate>(
        builder: (_) => TrainingEditScreen(
          training: training,
          controller: widget.trainingRegistrationController,
          exerciseRegistrationController: widget.exerciseRegistrationController,
        ),
      ),
    );
    if (update == null || !mounted) return;

    setState(() => _isSavingEdit = true);
    try {
      final targetCode = training.code.trim().isNotEmpty
          ? training.code
          : widget.trainingCode;
      final updated = await widget.repository.updateTraining(targetCode, update);
      if (!mounted) return;
      _wasTrainingModified = true;
      setState(() {
        _currentExerciseIndex = 0;
        _trainingFuture = Future.value(updated);
      });
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline_rounded,
        message: 'Treinamento atualizado com sucesso.',
      );
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: _errorMessage(error),
      );
    } finally {
      if (mounted) setState(() => _isSavingEdit = false);
    }
  }

  /// Resolve se o usuário atual tem permissão de gerenciar/editar o treinamento.
  bool _resolveCanManage(TrainingDetailData training) {
    final resolvedOwner = widget.isOwner ?? training.isOwner;
    final resolvedTrainerId = widget.trainerId ?? training.trainerId;
    return training
        .copyWith(isOwner: resolvedOwner, trainerId: resolvedTrainerId)
        .canManage(
          currentUserId: widget.currentUserId,
          isTrainer: widget.isTrainer,
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
                child: FutureBuilder<TrainingDetailData>(
                  future: _trainingFuture,
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

                    final training = snapshot.data!;
                    final canManage = _resolveCanManage(training);
                    final exercises = training.exercises;
                    final safeIndex = exercises.isEmpty
                        ? 0
                        : _currentExerciseIndex.clamp(0, exercises.length - 1);

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
                                training.title,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              if (canManage) ...[
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GradientButton(
                                        key: const Key('edit-training-button'),
                                        onPressed: () =>
                                            _editTraining(training),
                                        icon: Icons.edit_rounded,
                                        label: 'Editar treino',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(child: SizedBox.shrink()),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 24),
                              CollapsibleSectionCard(
                                key: const Key('training-detail-data-section'),
                                title: 'Dados do treinamento',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _DetailInfoLine('Título', training.title),
                                    _DetailInfoLine(
                                      'Descrição',
                                      training.displayDescription,
                                    ),
                                    _DetailInfoLine(
                                      'Duração estimada',
                                      training.formattedDuration,
                                      bottomPadding: 0,
                                    ),
                                  ],
                                ),
                              ),
                              CollapsibleSectionCard(
                                key: const Key(
                                  'training-detail-exercises-section',
                                ),
                                title: 'Exercícios selecionados',
                                child: _SelectedExercisesSectionContent(
                                  exercises: exercises,
                                  currentIndex: safeIndex,
                                  onIndexChanged: (index) => setState(
                                    () => _currentExerciseIndex = index,
                                  ),
                                  onViewDetails: _handleViewExerciseDetails,
                                ),
                              ),
                              CollapsibleSectionCard(
                                key: const Key(
                                  'training-detail-guidelines-section',
                                ),
                                title: 'Orientações',
                                margin: EdgeInsets.zero,
                                child: _GuidelinesSectionContent(
                                  guidelines: training.guidelines,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isSavingEdit) ...[
                const Positioned.fill(
                  child: ModalBarrier(dismissible: false, color: Colors.black26),
                ),
                const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: SizedBox(
                        key: Key('save-training-edit-progress'),
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

// Conteúdo dos exercícios selecionados (carrossel com swipe)

/// Componente visual responsável por exibir os exercícios selecionados do treinamento
/// em formato de carrossel com suporte a gestos de arrasto horizontal (swipe) e
/// paginação através de indicadores por pontos.
class _SelectedExercisesSectionContent extends StatefulWidget {
  const _SelectedExercisesSectionContent({
    required this.exercises,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onViewDetails,
  });

  /// Lista de exercícios associados a esta sessão de treinamento.
  final List<TrainingDetailExercise> exercises;

  /// Índice atual do exercício em exibição no carrossel.
  final int currentIndex;

  /// Notifica a alteração do índice do exercício em foco.
  final ValueChanged<int> onIndexChanged;

  /// Callback acionado quando o usuário clica no botão "Ver detalhes" do exercício.
  final ValueChanged<TrainingDetailExercise> onViewDetails;

  @override
  State<_SelectedExercisesSectionContent> createState() =>
      _SelectedExercisesSectionContentState();
}

class _SelectedExercisesSectionContentState
    extends State<_SelectedExercisesSectionContent> {
  /// Acúmulo do deslocamento horizontal para determinar a intenção de swipe.
  double _dragDelta = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercises = widget.exercises;

    // Estado vazio quando o treinamento não possui nenhum exercício vinculado.
    if (exercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.whiteSmoke,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text('Nenhum exercício registrado para este treinamento.'),
      );
    }

    final currentExercise = exercises[widget.currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Área sensível a gestos horizontais para avançar/retroceder no carrossel.
        GestureDetector(
          key: const Key('training-detail-exercises-swipe-area'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => _dragDelta = 0,
          onHorizontalDragUpdate: (details) {
            _dragDelta += details.primaryDelta ?? 0;
          },
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            // Avança para o próximo exercício ao arrastar para a esquerda (delta negativo ou velocidade expressiva).
            if ((_dragDelta < -40 || velocity < -150) &&
                widget.currentIndex < exercises.length - 1) {
              widget.onIndexChanged(widget.currentIndex + 1);
            }
            // Retorna ao exercício anterior ao arrastar para a direita (delta positivo).
            else if ((_dragDelta > 40 || velocity > 150) &&
                widget.currentIndex > 0) {
              widget.onIndexChanged(widget.currentIndex - 1);
            }
            _dragDelta = 0;
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Container(
              key: ValueKey(
                'training-exercise-card-${widget.currentIndex}-${currentExercise.name}',
              ),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: const BoxDecoration(
                color: AppColors.whiteSmoke,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nome do exercício
                  Text(
                    currentExercise.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Duração padrão estimada do exercício
                  _DetailInfoLine(
                    'Duração',
                    currentExercise.formattedDuration,
                    fontSize: 15,
                    bottomPadding: 2,
                  ),
                  // Descrição detalhada das orientações do exercício
                  _DetailInfoLine(
                    'Descrição',
                    currentExercise.displayDescription,
                    fontSize: 15,
                    bottomPadding: 14,
                  ),
                  // Botão de navegação para a visualização aprofundada do exercício
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton(
                      key: const Key('training-exercise-view-details-button'),
                      onPressed: () => widget.onViewDetails(currentExercise),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.seaGreen,
                        side: const BorderSide(
                          color: AppColors.seaGreen,
                          width: 1.8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.seaGreen,
                        ),
                      ),
                      child: const Text('Ver detalhes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Indicadores em pontos (dots) quando houver múltiplos exercícios.
        if (exercises.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(exercises.length, (index) {
              final isSelected = index == widget.currentIndex;
              return InkWell(
                key: Key('training-exercise-page-indicator-$index'),
                onTap: () => widget.onIndexChanged(index),
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

// Seção: conteúdo das orientações do treinamento

/// Componente visual responsável por listar cada uma das orientações ou
/// recomendações gerais definidas para o treinamento.
class _GuidelinesSectionContent extends StatelessWidget {
  const _GuidelinesSectionContent({required this.guidelines});

  final List<String> guidelines;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: 17,
      color: AppColors.text,
      height: 1.32,
    );

    // Estado vazio caso não haja orientações cadastradas.
    if (guidelines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.whiteSmoke,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text('Nenhuma orientação registrada para este treinamento.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < guidelines.length; index++) ...[
          Container(
            key: ValueKey('training-detail-guideline-$index'),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: const BoxDecoration(
              color: AppColors.whiteSmoke,
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.text,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(guidelines[index], style: textStyle)),
              ],
            ),
          ),
          if (index < guidelines.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// Componentes auxiliares de formatação e tratamento de erro

/// Linha de texto formatada com rótulo em negrito e valor informativo em estilo comum.
class _DetailInfoLine extends StatelessWidget {
  const _DetailInfoLine(
    this.label,
    this.value, {
    this.fontSize = 17,
    this.bottomPadding = 6,
  });

  final String label;
  final String value;
  final double fontSize;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: fontSize,
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

/// Estado visual exibido caso ocorra falha ao carregar os dados do treinamento.
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

/// Mapeia diferentes exceções em mensagens legíveis e amigáveis ao usuário.
String _errorMessage(Object? error) {
  if (error is TrainingDetailFailure) {
    return error.message;
  }
  if (error is TimeoutException) {
    return 'O servidor demorou para responder. Tente novamente.';
  }
  if (error is FirebaseFunctionsException) {
    return error.message ??
        'Não foi possível carregar os detalhes do treinamento.';
  }
  return 'Não foi possível carregar os detalhes do treinamento. Tente novamente.';
}
