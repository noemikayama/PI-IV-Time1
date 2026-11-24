// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Redirecionamento direto da barra inferior para a Home autenticada,
// removendo a propagação do destino por pop.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento da documentação e comentários explicativos para
// facilitar o entendimento da estrutura modular das seções recolhíveis,
// verificação de permissão de autoria e atualização reativa pós-edição.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela de visualização completa de exercícios
// (ExerciseDetailScreen) com seções recolhíveis (Dados do exercício, Mídias
// auxiliares com visualização de imagem/vídeo, Orientações e Materiais
// necessários), exibição condicional do botão Editar exercício apenas para o
// treinador criador e integração com ExerciseEditScreen.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/collapsible_section_card.dart';
import 'package:horse_life/core/widgets/detail_section_widgets.dart';
import 'package:horse_life/core/widgets/gradient_button.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';

import '../../application/states/exercise_material.dart';
import '../../data/models/exercise_detail_data.dart';
import '../../data/models/exercise_type.dart';
import '../../data/models/trainer_linked_horse.dart';
import '../../data/repositories/exercise_detail_repository.dart';
import '../../data/repositories/firebase_exercise_detail_repository.dart';
import '../../data/repositories/firebase_trainer_linked_horse_repository.dart';
import '../../data/repositories/trainer_linked_horse_repository.dart';
import '../widgets/exercise_media_carousel.dart';
import 'exercise_edit_screen.dart';
import 'exercise_media_screen.dart';

/// Tela de visualização completa de um exercício cadastrado no HorseLife.
///
/// Apresenta as informações do exercício organizadas em seções recolhíveis
/// ([CollapsibleSectionCard]), alinhando-se estritamente ao protótipo Figma e
/// ao padrão estabelecido nas telas de planos e treinamentos:
///
/// 1. **Dados do exercício**:
///    - Título (`Título: <título>`);
///    - Descrição (`Descrição: <descrição>`);
///    - Duração estimada (`Duração estimada: <tempo>`);
///    - Privacidade (`Privacidade: genérico` ou `específico`);
///    - Cavalo selecionado (`Cavalo selecionado: <nome do cavalo>`, renderizado
///      apenas quando a privacidade for específica e houver cavalo vinculado).
///
/// 2. **Mídias auxiliares**:
///    - Carrossel horizontal de fotos e vídeos com detecção automática de formato;
///    - Controles de reprodução para vídeo (play/pause, progresso, áudio e fullscreen);
///    - Visualizador interativo de imagens com pinch-to-zoom em tela cheia;
///    - Card de estado vazio ([DetailEmptyStateCard]) quando não houver mídias.
///
/// 3. **Orientações**:
///    - Lista de orientações de execução com ícone temático de balão de fala;
///    - Card de estado vazio quando nenhuma instrução foi informada.
///
/// 4. **Materiais necessários**:
///    - Lista de materiais em caixas arredondadas cinzas com ícone de ferramentas
///      e quantidade em destaque (ex.: `(3) Cavalete`);
///    - Card de estado vazio ("Nada além de você e seu animal é necessário...").
///
/// ### Permissão de Edição:
/// O botão "Editar exercício" ([GradientButton] com ícone de lápis) é renderizado
/// exclusivamente caso o usuário atual seja o treinador criador do exercício,
/// validado através de [ExerciseDetailData.resolveCanEdit].
class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({
    this.exerciseId,
    this.exerciseCode,
    this.currentUserId,
    this.isTrainer = false,
    this.canEditOverride,
    this.repository,
    this.horseRepository = const FirebaseTrainerLinkedHorseRepository(),
    this.initialHorses,
    this.filePicker = pickExerciseMediaFiles,
    this.fileSizeLoader,
    this.videoPlayerBuilder,
    this.imageBuilder,
    this.onNavigationSelected,
    this.onBack,
    super.key,
  });

  /// Identificador do exercício (ObjectId de 24 hex) utilizado na consulta.
  final String? exerciseId;

  /// Código numérico incremental alternativo para resolução do exercício.
  final String? exerciseCode;

  /// UID do usuário autenticado no Firebase Auth (usado para checar autoria).
  final String? currentUserId;

  /// Indica se a sessão atual pertence ao perfil de treinador.
  final bool isTrainer;

  /// Flag para sobrescrever a verificação de autoria (útil em testes automatizados).
  final bool? canEditOverride;

  /// Repositório abstrato de consulta e atualização do exercício.
  final ExerciseDetailRepository? repository;

  /// Repositório para carregamento dos cavalos vinculados ao treinador.
  final TrainerLinkedHorseRepository horseRepository;

  /// Lista pré-carregada de cavalos para testes ou transições rápidas.
  final List<TrainerLinkedHorse>? initialHorses;

  /// Função delegada para seleção de arquivos de imagem/vídeo nativos.
  final ExerciseMediaFilePicker filePicker;

  /// Carregador de tamanho de arquivo em bytes para validação de cotas.
  final ExerciseMediaFileSizeLoader? fileSizeLoader;

  /// Builder customizado para teste do reprodutor de vídeo.
  final ExerciseVideoBuilder? videoPlayerBuilder;

  /// Builder customizado para teste de exibição de imagens.
  final ExerciseImageBuilder? imageBuilder;

  /// Callback de seleção de abas na barra inferior de navegação.
  final ValueChanged<HomeNavigationDestination>? onNavigationSelected;

  /// Callback customizado de retorno para telas anteriores.
  final VoidCallback? onBack;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  late final ExerciseDetailRepository _repository;
  late Future<ExerciseDetailData> _exerciseFuture;
  bool _isSavingEdit = false;
  bool _wasExerciseModified = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FirebaseExerciseDetailRepository();
    _exerciseFuture = _loadExercise();
  }

  /// Dispara a busca remota pelo id ou código numérico do exercício.
  Future<ExerciseDetailData> _loadExercise() {
    return _repository.getExercise(
      id: widget.exerciseId,
      code: widget.exerciseCode,
    );
  }

  /// Recarrega os dados em caso de falha de conexão ou ação do usuário.
  void _reload() {
    setState(() {
      _exerciseFuture = _loadExercise();
    });
  }

  /// Retorna para a tela anterior propagando se o exercício foi modificado.
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(_wasExerciseModified);
    }
  }

  /// Direciona a navegação inferior para a tela selecionada.
  void _selectNavigationDestination(HomeNavigationDestination destination) {
    final callback = widget.onNavigationSelected;
    if (callback != null) {
      callback(destination);
      return;
    }
    navigateToHomeDestination(context, destination);
  }

  /// Abre o formulário de edição ([ExerciseEditScreen]) e aplica as alterações.
  Future<void> _editExercise(ExerciseDetailData exercise) async {
    if (_isSavingEdit) return;

    final update = await Navigator.of(context).push<ExerciseUpdate>(
      MaterialPageRoute<ExerciseUpdate>(
        builder: (_) => ExerciseEditScreen(
          exercise: exercise,
          horseRepository: widget.horseRepository,
          initialHorses: widget.initialHorses,
          filePicker: widget.filePicker,
          fileSizeLoader: widget.fileSizeLoader,
        ),
      ),
    );
    if (update == null || !mounted) return;

    setState(() => _isSavingEdit = true);
    try {
      final result = await _repository.updateExercise(
        original: exercise,
        update: update,
      );
      if (!mounted) return;
      _wasExerciseModified = true;
      setState(() {
        _exerciseFuture = Future.value(result.exercise);
      });
      if (result.hasWarning) {
        AppSnackBar.show(
          context,
          backgroundColor: AppColors.error,
          icon: Icons.warning_amber_rounded,
          message: result.warning!,
        );
      } else {
        AppSnackBar.show(
          context,
          backgroundColor: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
          message: 'Exercício atualizado com sucesso.',
        );
      }
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
                child: FutureBuilder<ExerciseDetailData>(
                  future: _exerciseFuture,
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
                            child: DetailLoadError(
                              message: _errorMessage(snapshot.error),
                              onRetry: _reload,
                            ),
                          ),
                        ],
                      );
                    }

                    final exercise = snapshot.data!;
                    final canEdit = exercise.resolveCanEdit(
                      currentUserId: widget.currentUserId,
                      canEditOverride: widget.canEditOverride,
                    );
                    final showHorse =
                        exercise.privacy == ExerciseType.specific &&
                        exercise.horse != null;

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
                                exercise.name,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              // Botão "Editar exercício" condicionado à permissão do treinador criador
                              if (canEdit) ...[
                                const SizedBox(height: 22),
                                Row(
                                  children: [
                                    Expanded(
                                      child: GradientButton(
                                        key: const Key('edit-exercise-button'),
                                        onPressed: () =>
                                            _editExercise(exercise),
                                        icon: Icons.edit_rounded,
                                        label: 'Editar exercício',
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(child: SizedBox.shrink()),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 24),
                              // Seção 1: Dados do exercício
                              CollapsibleSectionCard(
                                key: const Key('exercise-detail-data-section'),
                                title: 'Dados do exercício',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DetailInfoLine('Título', exercise.name),
                                    DetailInfoLine(
                                      'Descrição',
                                      exercise.displayDescription,
                                    ),
                                    DetailInfoLine(
                                      'Duração estimada',
                                      exercise.formattedDuration,
                                    ),
                                    DetailInfoLine(
                                      'Privacidade',
                                      exercise.privacyDisplayLabel,
                                      bottomPadding: showHorse ? 6 : 0,
                                    ),
                                    if (showHorse)
                                      DetailInfoLine(
                                        'Cavalo selecionado',
                                        exercise.horse!.name,
                                        bottomPadding: 0,
                                      ),
                                  ],
                                ),
                              ),
                              // Seção 2: Mídias auxiliares (carrossel de imagens e vídeos)
                              CollapsibleSectionCard(
                                key: const Key('exercise-detail-media-section'),
                                title: 'Mídias auxiliares',
                                child: ExerciseMediaCarousel(
                                  media: exercise.allMedia,
                                  canEdit: canEdit,
                                  videoPlayerBuilder: widget.videoPlayerBuilder,
                                  imageBuilder: widget.imageBuilder,
                                ),
                              ),
                              // Seção 3: Orientações
                              CollapsibleSectionCard(
                                key: const Key(
                                  'exercise-detail-guidelines-section',
                                ),
                                title: 'Orientações',
                                child: _GuidelinesSectionContent(
                                  guidelines: exercise.guidelines,
                                ),
                              ),
                              // Seção 4: Materiais necessários
                              CollapsibleSectionCard(
                                key: const Key(
                                  'exercise-detail-materials-section',
                                ),
                                title: 'Materiais necessários',
                                margin: EdgeInsets.zero,
                                child: _MaterialsSectionContent(
                                  materials: exercise.materials,
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
              // Bloqueio visual durante persistência assíncrona das alterações
              if (_isSavingEdit) ...[
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
                        key: Key('save-exercise-edit-progress'),
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

/// Conteúdo interno da seção colapsável de orientações.
class _GuidelinesSectionContent extends StatelessWidget {
  const _GuidelinesSectionContent({required this.guidelines});

  final List<String> guidelines;

  @override
  Widget build(BuildContext context) {
    if (guidelines.isEmpty) {
      return const DetailEmptyStateCard(
        cardKey: Key('exercise-detail-guidelines-empty'),
        title: 'Nenhuma orientação adicionada',
        message: 'Nenhuma orientação foi registrada para este exercício.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < guidelines.length; index++) ...[
          DetailIconTextTile(
            tileKey: ValueKey('exercise-detail-guideline-$index'),
            icon: Icons.chat_bubble_outline_rounded,
            text: guidelines[index],
          ),
          if (index < guidelines.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Conteúdo interno da seção colapsável de materiais necessários.
class _MaterialsSectionContent extends StatelessWidget {
  const _MaterialsSectionContent({required this.materials});

  final List<ExerciseMaterial> materials;

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) {
      return const DetailEmptyStateCard(
        cardKey: Key('exercise-detail-materials-empty'),
        title: 'Nenhum',
        message:
            'Nada além de você e seu animal é necessário para a realização desse exercício',
      );
    }

    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: 17,
      color: AppColors.text,
      height: 1.32,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < materials.length; index++) ...[
          DetailIconTextTile(
            tileKey: ValueKey('exercise-detail-material-$index'),
            icon: Icons.handyman_outlined,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '(${materials[index].quantity}) ',
                    style: baseStyle?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: materials[index].name, style: baseStyle),
                ],
              ),
            ),
          ),
          if (index < materials.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

String _errorMessage(Object? error) {
  if (error is ExerciseDetailFailure) {
    return error.message;
  }
  if (error is TimeoutException) {
    return 'O servidor demorou para responder. Tente novamente.';
  }
  if (error is FirebaseFunctionsException) {
    return error.message ??
        'Não foi possível carregar os detalhes do exercício.';
  }
  return 'Não foi possível carregar os detalhes do exercício. Tente novamente.';
}
