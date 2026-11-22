// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos estados, cronômetro, diálogos, mídias e transição
// entre a execução ativa e o formulário final.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da execução ativa com cronômetro, acompanhamento dos
// exercícios, orientações, materiais, mídias e confirmação de finalização.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/features/training/data/models/training_completion_data.dart';
import 'package:horse_life/features/training/data/models/training_execution_data.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';
import 'package:horse_life/features/training/presentation/screens/training_completion_screen.dart';
import 'package:video_player/video_player.dart';

/// Conduz uma execução iniciada, mede o tempo e registra exercícios concluídos.
class ActiveTrainingScreen extends StatefulWidget {
  const ActiveTrainingScreen({
    required this.training,
    required this.completionSubmitter,
    super.key,
  });

  /// Conteúdo consolidado exibido durante toda a sessão.
  final TrainingExecutionData training;

  /// Destino do formulário aberto após a confirmação de encerramento.
  final TrainingCompletionSubmitter completionSubmitter;

  @override
  State<ActiveTrainingScreen> createState() => _ActiveTrainingScreenState();
}

class _ActiveTrainingScreenState extends State<ActiveTrainingScreen> {
  // O cronômetro mede tempo real; o Timer apenas solicita a atualização visual.
  final Stopwatch _stopwatch = Stopwatch();

  // Página atual e índices concluídos formam o estado local dos exercícios.
  final PageController _exerciseController = PageController();
  final Set<int> _completedExercises = <int>{};
  Timer? _timer;
  int _exercisePage = 0;
  bool _finishDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _exerciseController.dispose();
    super.dispose();
  }

  // Alterna a marcação sem alterar a ordem original dos exercícios.
  void _toggleExercise(int index) {
    setState(() {
      if (!_completedExercises.add(index)) _completedExercises.remove(index);
    });
  }

  // Pausa o tempo enquanto o diálogo está aberto. Cancelar retoma a medição;
  // confirmar substitui a rota pela tela de conclusão com um snapshot do estado.
  Future<void> _requestFinishTraining() async {
    if (_finishDialogOpen) return;
    _finishDialogOpen = true;
    _stopwatch.stop();
    if (mounted) setState(() {});
    // Aguarda a reconstrução que exibe o cronômetro pausado antes de inserir
    // a rota do diálogo. Isso evita competir com o fim do gesto e com o
    // PageView/player de vídeo no mesmo frame.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (context) => _FinishTrainingDialog(
        hasPendingExercises:
            _completedExercises.length < widget.training.exercises.length,
      ),
    );
    if (!mounted) return;
    _finishDialogOpen = false;
    if (confirmed == true) {
      final elapsed = _stopwatch.elapsed;
      final exercises = [
        for (var index = 0; index < widget.training.exercises.length; index++)
          TrainingCompletionExercise(
            code: widget.training.exercises[index].code,
            completed: _completedExercises.contains(index),
          ),
      ];
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (context) => TrainingCompletionScreen(
            submitter: widget.completionSubmitter,
            initialInput: TrainingCompletionInput(
              recordId: widget.training.recordId,
              elapsed: elapsed,
              performancePerception: '',
              difficulty: '',
              notes: '',
              exercises: exercises,
            ),
          ),
        ),
      );
      return;
    }
    _stopwatch.start();
    setState(() {});
  }

  // Reapresenta os dados gerais sem interromper o cronômetro da sessão.
  Future<void> _showTrainingInformation() => showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (context) => _TrainingInformationDialog(training: widget.training),
  );

  @override
  Widget build(BuildContext context) {
    final training = widget.training;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(onBack: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 26),
                  Text(
                    training.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 28),
                  KeyedSubtree(
                    key: ValueKey<String>(
                      _stopwatch.isRunning
                          ? 'training-timer-running'
                          : 'training-timer-paused',
                    ),
                    child: _StatusLine(
                      icon: Icons.timer_outlined,
                      label: 'Tempo decorrido:',
                      value: _formatElapsed(_stopwatch.elapsed),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _StatusLine(
                    icon: Icons.assignment_turned_in_outlined,
                    label: 'Exercícios realizados:',
                    value:
                        '${_completedExercises.length}/${training.exercises.length}',
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _showTrainingInformation,
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 34),
                    label: const Text('Ver informações do treino'),
                  ),
                  const SizedBox(height: 16),
                  if (training.exercises.isEmpty)
                    const _EmptyExerciseExecution()
                  else ...[
                    SizedBox(
                      height: 900,
                      child: PageView.builder(
                        controller: _exerciseController,
                        itemCount: training.exercises.length,
                        onPageChanged: (index) =>
                            setState(() => _exercisePage = index),
                        itemBuilder: (context, index) => _ExecutionCard(
                          key: ValueKey('execution-exercise-$index'),
                          exercise: training.exercises[index],
                          position: index + 1,
                          total: training.exercises.length,
                          completed: _completedExercises.contains(index),
                          onToggle: () => _toggleExercise(index),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PageDots(
                      count: training.exercises.length,
                      selected: _exercisePage,
                    ),
                  ],
                  const SizedBox(height: 38),
                  SizedBox(
                    height: 62,
                    child: OutlinedButton.icon(
                      key: const Key('finish-training-button'),
                      onPressed: _requestFinishTraining,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.seaGreen,
                        side: const BorderSide(
                          color: AppColors.seaGreen,
                          width: 2.5,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 31),
                      label: const Text('Finalizar treinamento'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Modal rolável com duração, descrição e orientações gerais do treino.
class _TrainingInformationDialog extends StatelessWidget {
  const _TrainingInformationDialog({required this.training});

  final TrainingExecutionData training;

  @override
  Widget build(BuildContext context) => Dialog(
    key: const Key('training-information-dialog'),
    insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    elevation: 14,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'Informações',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    key: const Key('close-training-information'),
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 42),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 34),
            Text.rich(
              TextSpan(
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontSize: 22),
                children: [
                  const TextSpan(
                    text: 'Duração estimada: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: _duration(training.durationMinutes)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Descrição:',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 23,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              training.description.isEmpty
                  ? 'Sem descrição.'
                  : training.description,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontSize: 21),
            ),
            const SizedBox(height: 24),
            Text(
              'Orientações:',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 23,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            if (training.guidelines.isEmpty)
              const _DialogGuideline(text: 'Nenhuma orientação informada.')
            else
              for (final guideline in training.guidelines) ...[
                _DialogGuideline(text: guideline),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 28),
            SizedBox(
              height: 58,
              child: OutlinedButton(
                key: const Key('confirm-training-information'),
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.seaGreen,
                  side: const BorderSide(color: AppColors.seaGreen, width: 2.5),
                  shape: const StadiumBorder(),
                  textStyle: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                child: const Text('Ok'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Confirma o encerramento e alerta quando ainda existem exercícios pendentes.
class _FinishTrainingDialog extends StatelessWidget {
  const _FinishTrainingDialog({required this.hasPendingExercises});

  final bool hasPendingExercises;

  @override
  Widget build(BuildContext context) => Dialog(
    key: const Key('finish-training-dialog'),
    insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 14,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(34, 32, 34, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tem certeza que deseja\nfinalizar o treino?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 34),
            Text(
              hasPendingExercises
                  ? 'Percebemos que você possui um ou mais exercícios não '
                        'finalizados. Você quer mesmo finalizar? Não será '
                        'possível continuar de onde você parou.'
                  : 'Todos os exercícios foram finalizados. Você quer mesmo '
                        'finalizar o treino? Não será possível continuar de '
                        'onde você parou.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontSize: 21, height: 1.22),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 58,
                    child: OutlinedButton(
                      key: const Key('cancel-finish-training'),
                      onPressed: () => Navigator.of(context).pop(false),
                      style: _confirmationButtonStyle(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: SizedBox(
                    height: 58,
                    child: OutlinedButton(
                      key: const Key('confirm-finish-training'),
                      onPressed: () => Navigator.of(context).pop(true),
                      style: _confirmationButtonStyle(context),
                      child: const Text('Sim'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  ButtonStyle _confirmationButtonStyle(BuildContext context) =>
      OutlinedButton.styleFrom(
        foregroundColor: AppColors.seaGreen,
        side: const BorderSide(color: AppColors.seaGreen, width: 2.5),
        shape: const StadiumBorder(),
        textStyle: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
      );
}

// Apresentação reutilizável de uma orientação dentro do modal informativo.
class _DialogGuideline extends StatelessWidget {
  const _DialogGuideline({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    decoration: BoxDecoration(
      color: AppColors.alabasterGray,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        const Icon(Icons.chat_bubble_outline_rounded, size: 34),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 20),
          ),
        ),
      ],
    ),
  );
}

// Cabeçalho compacto que mantém retorno e identidade visual da aplicação.
class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton(
        onPressed: onBack,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.seaGreen,
          size: 34,
        ),
      ),
      Image.asset('assets/Logo_somente_simbolo.png', width: 70, height: 70),
    ],
  );
}

// Linha de resumo usada para tempo decorrido e progresso dos exercícios.
class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 34),
      const SizedBox(width: 12),
      Expanded(
        child: Text.rich(
          TextSpan(
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 21),
            children: [
              TextSpan(
                text: '$label ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      ),
    ],
  );
}

// Cartão da página atual com conteúdo, recursos e ação de conclusão do exercício.
class _ExecutionCard extends StatelessWidget {
  const _ExecutionCard({
    required this.exercise,
    required this.position,
    required this.total,
    required this.completed,
    required this.onToggle,
    super.key,
  });

  final TrainingExecutionExercise exercise;
  final int position;
  final int total;
  final bool completed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
    decoration: BoxDecoration(
      color: AppColors.alabasterGray,
      borderRadius: BorderRadius.circular(28),
    ),
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.name,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              Text(
                '$position/$total',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _RichLine(
            label: 'Duração estimada:',
            value: _duration(exercise.durationMinutes),
          ),
          const SizedBox(height: 18),
          Text('Descrição:', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            exercise.description.isEmpty
                ? 'Sem descrição.'
                : exercise.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text(
            'Mídias auxiliares',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _ExerciseMediaCarousel(media: exercise.media),
          const SizedBox(height: 24),
          Text('Orientações', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (exercise.guidelines.isEmpty)
            const _InformationTile(
              icon: Icons.chat_bubble_outline_rounded,
              text: 'Nenhuma orientação informada.',
            )
          else
            for (final guideline in exercise.guidelines) ...[
              _InformationTile(
                icon: Icons.chat_bubble_outline_rounded,
                text: guideline,
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 20),
          Text(
            'Materiais necessários',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          if (exercise.materials.isEmpty)
            const _InformationTile(
              icon: Icons.handyman_outlined,
              text: 'Nenhum material informado.',
            )
          else
            for (final material in exercise.materials) ...[
              _InformationTile(
                icon: Icons.handyman_outlined,
                text: '(${material.quantity}) ${material.description}',
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 28),
          SizedBox(
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: completed ? AppColors.grey : null,
                gradient: completed
                    ? null
                    : const LinearGradient(
                        colors: [AppColors.seaGreen, AppColors.blueSpruce],
                      ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  key: Key('toggle-exercise-${position - 1}'),
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(32),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          completed
                              ? Icons.replay_rounded
                              : Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 31,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          completed
                              ? 'Reiniciar exercício'
                              : 'Finalizar exercício',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// Alterna imagens e vídeos remotos mantendo um indicador da página selecionada.
class _ExerciseMediaCarousel extends StatefulWidget {
  const _ExerciseMediaCarousel({required this.media});
  final List<TrainingExerciseMedia> media;

  @override
  State<_ExerciseMediaCarousel> createState() => _ExerciseMediaCarouselState();
}

class _ExerciseMediaCarouselState extends State<_ExerciseMediaCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) {
      return Container(
        height: 235,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_outline, color: Colors.white, size: 68),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 235,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.media.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) {
              final media = widget.media[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: media.type == TrainingExerciseMediaType.video
                    ? _NetworkVideoPlayer(url: media.url)
                    : Image.network(
                        media.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: Colors.black,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
              );
            },
          ),
        ),
        if (widget.media.length > 1) ...[
          const SizedBox(height: 10),
          _PageDots(count: widget.media.length, selected: _page),
        ],
      ],
    );
  }
}

// Encapsula ciclo de vida, carregamento, reprodução e volume de um vídeo remoto.
class _NetworkVideoPlayer extends StatefulWidget {
  const _NetworkVideoPlayer({required this.url});
  final String url;

  @override
  State<_NetworkVideoPlayer> createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<_NetworkVideoPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialization;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _initialization = _controller.initialize().then((_) {
      _controller.setVolume(1);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Colors.black,
    child: FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Icon(
              Icons.videocam_off_outlined,
              color: Colors.white,
              size: 48,
            ),
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio == 0
                    ? 16 / 9
                    : _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            ),
            Center(
              child: IconButton.filled(
                onPressed: () => setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                }),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                iconSize: 46,
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: AppColors.seaGreen,
                        bufferedColor: Colors.white54,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _muted ? 'Ativar áudio' : 'Silenciar',
                    onPressed: () {
                      setState(() => _muted = !_muted);
                      _controller.setVolume(_muted ? 0 : 1);
                    },
                    color: Colors.white,
                    icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

// Bloco visual de uma orientação ou material do exercício.
class _InformationTile extends StatelessWidget {
  const _InformationTile({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 7,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(icon, size: 31),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );
}

// Combina rótulo destacado e valor em uma única linha sem duplicar estilos.
class _RichLine extends StatelessWidget {
  const _RichLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      style: Theme.of(context).textTheme.bodyLarge,
      children: [
        TextSpan(
          text: '$label ',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        TextSpan(text: value),
      ],
    ),
  );
}

// Indicador animado compartilhado pelos carrosséis da execução.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.selected});
  final int count;
  final int selected;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      count,
      (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: index == selected ? 40 : 13,
        height: 13,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.grey,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  );
}

// Estado explícito para treinamentos que não possuem exercícios disponíveis.
class _EmptyExerciseExecution extends StatelessWidget {
  const _EmptyExerciseExecution();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: AppColors.alabasterGray,
      borderRadius: BorderRadius.circular(28),
    ),
    child: const Text('Nenhum exercício disponível.'),
  );
}

// Formata o cronômetro sempre como HH:MM:SS, inclusive antes de uma hora.
String _formatElapsed(Duration elapsed) {
  final hours = elapsed.inHours.toString().padLeft(2, '0');
  final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

// Aplica singular somente à unidade exata usada nos textos da interface.
String _duration(int minutes) => minutes == 1 ? '1 minuto' : '$minutes minutos';
