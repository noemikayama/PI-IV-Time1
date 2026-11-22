// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento da documentação e comentários explicativos para
// facilitar o entendimento do ciclo de vida de reprodução de vídeos, controles
// de tela cheia e zoom interativo de imagens.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do carrossel de mídias auxiliares do exercício com suporte
// a alternância automática entre imagens (com zoom em tela cheia) e vídeos
// remotos (com indicador de progresso arrastável, tempo decorrido, áudio e
// reprodução em tela cheia).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/detail_section_widgets.dart';
import 'package:video_player/video_player.dart';

import '../../application/states/exercise_media.dart';
import '../../data/models/exercise_detail_data.dart';

/// Builder customizável para renderização de vídeos em testes ou integrações.
typedef ExerciseVideoBuilder =
    Widget Function(BuildContext context, ExerciseDetailMedia media);

/// Builder customizável para renderização de imagens em testes ou integrações.
typedef ExerciseImageBuilder =
    Widget Function(BuildContext context, ExerciseDetailMedia media);

/// Carrossel horizontal de mídias auxiliares (imagens e vídeos) do exercício.
///
/// Características funcionais:
/// 1. **Detecção automática de formato**: Diferencia imagens de vídeos a partir da
///    extensão do arquivo (ex.: .mp4, .mov vs .jpg, .png) ou do tipo cadastrado;
/// 2. **Estado vazio contextual**: Quando a lista for vazia, exibe um card cinza
///    arredondado convidativo ([DetailEmptyStateCard]), diferenciando o texto
///    caso o usuário atual seja o treinador criador com permissão de edição;
/// 3. **Paginação e indicadores**: Integra [PageView.builder] a [DetailCarouselDots]
///    para sincronizar a transição suave entre páginas com feedback visual.
class ExerciseMediaCarousel extends StatefulWidget {
  const ExerciseMediaCarousel({
    required this.media,
    this.canEdit = false,
    this.videoPlayerBuilder,
    this.imageBuilder,
    super.key,
  });

  /// Lista de mídias persistidas no exercício.
  final List<ExerciseDetailMedia> media;

  /// Indica se o usuário atual pode editar o exercício (muda a mensagem do empty state).
  final bool canEdit;

  /// Builder injetável para reprodutor de vídeo (útil em testes automatizados).
  final ExerciseVideoBuilder? videoPlayerBuilder;

  /// Builder injetável para exibição de imagens (útil em testes automatizados).
  final ExerciseImageBuilder? imageBuilder;

  @override
  State<ExerciseMediaCarousel> createState() => _ExerciseMediaCarouselState();
}

class _ExerciseMediaCarouselState extends State<ExerciseMediaCarousel> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void didUpdateWidget(covariant ExerciseMediaCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ajusta o índice ativo caso a lista de mídias diminua após uma edição.
    if (_currentPage >= widget.media.length && widget.media.isNotEmpty) {
      _currentPage = widget.media.length - 1;
      if (_controller.hasClients) {
        _controller.jumpToPage(_currentPage);
      }
    } else if (widget.media.isEmpty) {
      _currentPage = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.media.isEmpty) {
      return DetailEmptyStateCard(
        cardKey: const Key('exercise-detail-media-empty'),
        title: 'Nenhuma mídia adicionada',
        message: widget.canEdit
            ? 'Adicione mídias para ajudar seus atletas a executarem o exercício'
            : 'Nenhuma mídia auxiliar foi adicionada a este exercício.',
      );
    }

    final safePage = _currentPage.clamp(0, widget.media.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            key: const Key('exercise-detail-media-pageview'),
            controller: _controller,
            itemCount: widget.media.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final item = widget.media[index];
              final resolvedType = ExerciseDetailMedia.inferMediaType(
                path: item.path,
                url: item.url,
                fallback: item.type,
              );
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: resolvedType == ExerciseMediaType.video
                    ? (widget.videoPlayerBuilder?.call(context, item) ??
                          ExerciseNetworkVideoPlayer(
                            key: ValueKey('exercise-video-${item.url}'),
                            url: item.url,
                          ))
                    : (widget.imageBuilder?.call(context, item) ??
                          _ExerciseNetworkImage(
                            key: ValueKey('exercise-image-${item.url}'),
                            url: item.url,
                          )),
              );
            },
          ),
        ),
        if (widget.media.length > 1) ...[
          const SizedBox(height: 10),
          DetailCarouselDots(
            keyPrefix: 'exercise-media-dot',
            count: widget.media.length,
            currentIndex: safePage,
            onDotTap: (index) {
              if (!_controller.hasClients) return;
              _controller.animateToPage(
                index,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ],
    );
  }
}

/// Exibe imagem remota do exercício com opção de abertura em tela cheia e zoom.
class _ExerciseNetworkImage extends StatelessWidget {
  const _ExerciseNetworkImage({required this.url, super.key});

  final String url;

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullscreenImagePage(url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InkWell(
            onTap: () => _openFullscreen(context),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (_, _, _) => const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: IconButton.filled(
              tooltip: 'Tela cheia',
              onPressed: () => _openFullscreen(context),
              style: IconButton.styleFrom(backgroundColor: Colors.black54),
              icon: const Icon(
                Icons.fullscreen_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Página modal em tela cheia com suporte a zoom gestual via [InteractiveViewer].
class _FullscreenImagePage extends StatelessWidget {
  const _FullscreenImagePage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 56,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton.filled(
                tooltip: 'Fechar',
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reprodutor de vídeo remoto com controle de reprodução, barra de progressão
/// arrastável, temporizador, áudio e alternância para tela cheia.
///
/// Gerencia adequadamente o ciclo de vida do [VideoPlayerController], evitando
/// vazamento de memória e garantindo reuso sem descarte acidental ao abrir a
/// tela cheia.
class ExerciseNetworkVideoPlayer extends StatefulWidget {
  const ExerciseNetworkVideoPlayer({required this.url, super.key});

  final String url;

  @override
  State<ExerciseNetworkVideoPlayer> createState() =>
      _ExerciseNetworkVideoPlayerState();
}

class _ExerciseNetworkVideoPlayerState
    extends State<ExerciseNetworkVideoPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialization;
  bool _muted = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.addListener(_onVideoTick);
    _initialization = _controller.initialize().then((_) {
      if (!_disposed) {
        _controller.setVolume(1);
      }
    });
  }

  void _onVideoTick() {
    if (!mounted || _disposed) return;
    setState(() {});
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.removeListener(_onVideoTick);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_controller.value.isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        if (_controller.value.position >= _controller.value.duration &&
            _controller.value.duration > Duration.zero) {
          _controller.seekTo(Duration.zero);
        }
        _controller.play();
      }
    });
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _controller.setVolume(_muted ? 0 : 1);
  }

  Future<void> _openFullscreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullscreenVideoPage(
          controller: _controller,
          initialMuted: _muted,
          onMuteChanged: (muted) {
            if (mounted) {
              setState(() => _muted = muted);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
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

          final value = _controller.value;
          final aspectRatio = value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio;

          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              // Botão central de Play/Pause (visível em destaque se o vídeo estiver pausado)
              Center(
                child: IconButton.filled(
                  key: const Key('exercise-video-play-pause'),
                  onPressed: _togglePlayPause,
                  iconSize: 44,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
              ),
              // Barra inferior com controles e progresso
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Barra deslizante de progresso (scrubber)
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                          activeTrackColor: AppColors.seaGreen,
                          inactiveTrackColor: Colors.white30,
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: value.duration.inMilliseconds > 0
                              ? value.position.inMilliseconds
                                  .clamp(0, value.duration.inMilliseconds)
                                  .toDouble()
                              : 0.0,
                          max: value.duration.inMilliseconds > 0
                              ? value.duration.inMilliseconds.toDouble()
                              : 1.0,
                          onChanged: (pos) {
                            _controller.seekTo(
                              Duration(milliseconds: pos.toInt()),
                            );
                          },
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: _muted ? 'Ativar áudio' : 'Mutar áudio',
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              _muted
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _toggleMute,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            key: const Key('exercise-video-fullscreen'),
                            tooltip: 'Tela cheia',
                            iconSize: 22,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                            ),
                            onPressed: _openFullscreen,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Página modal em tela cheia para exibição e controle do vídeo.
///
/// Compartilha o mesmo [VideoPlayerController] da tela de detalhes sem descartá-lo
/// ao fechar o modal, garantindo continuidade sem recarregar o vídeo.
class _FullscreenVideoPage extends StatefulWidget {
  const _FullscreenVideoPage({
    required this.controller,
    required this.initialMuted,
    required this.onMuteChanged,
  });

  final VideoPlayerController controller;
  final bool initialMuted;
  final ValueChanged<bool> onMuteChanged;

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  late bool _muted;

  @override
  void initState() {
    super.initState();
    _muted = widget.initialMuted;
    widget.controller.addListener(_onVideoTick);
  }

  void _onVideoTick() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    // Não descartar widget.controller aqui, pois ele pertence ao widget pai!
    widget.controller.removeListener(_onVideoTick);
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
      } else {
        if (widget.controller.value.position >=
                widget.controller.value.duration &&
            widget.controller.value.duration > Duration.zero) {
          widget.controller.seekTo(Duration.zero);
        }
        widget.controller.play();
      }
    });
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    widget.controller.setVolume(_muted ? 0 : 1);
    widget.onMuteChanged(_muted);
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final aspectRatio = value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),
            Center(
              child: IconButton.filled(
                iconSize: 52,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                ),
                onPressed: _togglePlayPause,
                icon: Icon(
                  value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton.filled(
                tooltip: 'Sair da tela cheia',
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.fullscreen_exit_rounded,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        activeTrackColor: AppColors.seaGreen,
                        inactiveTrackColor: Colors.white30,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: value.duration.inMilliseconds > 0
                            ? value.position.inMilliseconds
                                .clamp(0, value.duration.inMilliseconds)
                                .toDouble()
                            : 0.0,
                        max: value.duration.inMilliseconds > 0
                            ? value.duration.inMilliseconds.toDouble()
                            : 1.0,
                        onChanged: (pos) {
                          widget.controller.seekTo(
                            Duration(milliseconds: pos.toInt()),
                          );
                        },
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: _muted ? 'Ativar áudio' : 'Mutar áudio',
                          icon: Icon(
                            _muted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _toggleMute,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
