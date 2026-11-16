// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Restrição de extensões (JPEG, PNG, MP4) e limites de tamanho
// (5 MB para fotos, 50 MB para vídeos) conforme contrato das Cloud Functions.
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adoção dos widgets centralizados FormProgressIndicator,
// AppAddItemButton e AppRemovableItemTile provenientes de core/widgets.
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da etapa de adição de mídias auxiliares (imagens e vídeos)
// usando o explorador nativo de arquivos sem modal intermediário, operando como
// etapa 6 de 7 (genérico) ou etapa 7 de 8 (específico).
// -----------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_item_list_widgets.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/form_progress_indicator.dart';
import '../../../authentication/presentation/widgets/auth_header.dart';
import '../../../authentication/presentation/widgets/auth_next_button.dart';
import '../../application/controllers/exercise_registration_controller.dart';
import '../../application/states/exercise_media.dart';
import '../../application/states/exercise_registration_draft.dart';
import 'exercise_confirmation_screen.dart';

typedef ExerciseMediaCallback = void Function(ExerciseRegistrationDraft draft);

// Permite substituir o seletor nativo por uma implementação controlada em testes.
typedef ExerciseMediaFilePicker = Future<List<XFile>> Function();

// Permite injetar a leitura do tamanho de arquivo em testes sem depender de disco.
typedef ExerciseMediaFileSizeLoader = Future<int> Function(XFile file);

const _maxImageBytes = 5 * 1024 * 1024; // 5 MB
const _maxVideoBytes = 50 * 1024 * 1024; // 50 MB
const _maxImages = 10;
const _maxVideos = 3;

const _supportedImageExtensions = <String>{
  'png',
  'jpg',
  'jpeg',
};

const _supportedVideoExtensions = <String>{
  'mp4',
};

const _exerciseMediaTypeGroup = XTypeGroup(
  label: 'Imagens e vídeos',
  extensions: [
    'png',
    'jpg',
    'jpeg',
    'mp4',
  ],
  mimeTypes: [
    'image/png',
    'image/jpeg',
    'video/mp4',
  ],
);

// Abre diretamente o explorador nativo do dispositivo para seleção múltipla de
// imagens e vídeos auxiliares.
Future<List<XFile>> pickExerciseMediaFiles() {
  return openFiles(acceptedTypeGroups: const [_exerciseMediaTypeGroup]);
}

// Etapa de mídias auxiliares (imagens e vídeos), operando como etapa 6 de 7 no
// fluxo genérico ou etapa 7 de 8 no fluxo específico.
class ExerciseMediaScreen extends StatefulWidget {
  const ExerciseMediaScreen({
    required this.draft,
    this.filePicker = pickExerciseMediaFiles,
    this.fileSizeLoader,
    this.registrationController,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final ExerciseRegistrationDraft draft;
  final ExerciseMediaFilePicker filePicker;
  final ExerciseMediaFileSizeLoader? fileSizeLoader;
  final ExerciseRegistrationController? registrationController;
  final ExerciseMediaCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<ExerciseMediaScreen> createState() => _ExerciseMediaScreenState();
}

class _ExerciseMediaScreenState extends State<ExerciseMediaScreen> {
  static const _mediaHeight = 64.0;
  static const _mediaSpacing = 12.0;
  static const _maximumVisibleMedia = 3;

  final ScrollController _mediaScrollController = ScrollController();
  late final List<ExerciseMedia> _mediaItems;
  bool _isPicking = false;

  FormProgressConfiguration get _progressConfiguration =>
      switch (widget.draft) {
        GenericExerciseRegistrationDraft() =>
          FormProgressConfiguration.genericExercise,
        SpecificExerciseRegistrationDraft() =>
          FormProgressConfiguration.specificExercise,
      };

  int get _currentStep => switch (widget.draft) {
    GenericExerciseRegistrationDraft() => 6,
    SpecificExerciseRegistrationDraft() => 7,
  };

  @override
  void initState() {
    super.initState();
    _mediaItems = List.of(widget.draft.mediaItems);
  }

  @override
  void dispose() {
    _mediaScrollController.dispose();
    super.dispose();
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  // Classifica a extensão do arquivo selecionado em imagem ou vídeo, ou retorna
  // nulo quando o formato não é suportado.
  ExerciseMediaType? _classifyMediaFile(XFile file) {
    final parts = file.name.toLowerCase().split('.');
    if (parts.length < 2) return null;
    final extension = parts.last;
    if (_supportedImageExtensions.contains(extension)) {
      return ExerciseMediaType.image;
    }
    if (_supportedVideoExtensions.contains(extension)) {
      return ExerciseMediaType.video;
    }
    return null;
  }

  // Aciona diretamente o seletor de arquivos do dispositivo, como na etapa de
  // certificações do treinador, sem abrir modal intermediário.
  Future<void> _pickMediaFiles() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final files = await widget.filePicker();
      if (!mounted || files.isEmpty) return;

      var imageCount =
          _mediaItems.where((m) => m.type == ExerciseMediaType.image).length;
      var videoCount =
          _mediaItems.where((m) => m.type == ExerciseMediaType.video).length;

      final validEntries = <(XFile, ExerciseMediaType, int)>[];

      for (final file in files) {
        final mediaType = _classifyMediaFile(file);
        if (mediaType == null) {
          AppSnackBar.show(
            context,
            backgroundColor: AppColors.error,
            icon: Icons.error_outline_rounded,
            message:
                'Formato não suportado. Utilize imagens JPG/PNG ou vídeos MP4.',
          );
          continue;
        }

        final size = await (widget.fileSizeLoader?.call(file) ?? file.length());

        if (mediaType == ExerciseMediaType.image) {
          if (imageCount >= _maxImages) {
            AppSnackBar.show(
              context,
              backgroundColor: AppColors.error,
              icon: Icons.error_outline_rounded,
              message: 'Limite máximo de $_maxImages imagens atingido.',
            );
            continue;
          }
          if (size > _maxImageBytes) {
            AppSnackBar.show(
              context,
              backgroundColor: AppColors.error,
              icon: Icons.error_outline_rounded,
              message: 'A foto ${file.name} excede o limite máximo de 5 MB.',
            );
            continue;
          }
          imageCount++;
        } else {
          if (videoCount >= _maxVideos) {
            AppSnackBar.show(
              context,
              backgroundColor: AppColors.error,
              icon: Icons.error_outline_rounded,
              message: 'Limite máximo de $_maxVideos vídeos atingido.',
            );
            continue;
          }
          if (size > _maxVideoBytes) {
            AppSnackBar.show(
              context,
              backgroundColor: AppColors.error,
              icon: Icons.error_outline_rounded,
              message: 'O vídeo ${file.name} excede o limite máximo de 50 MB.',
            );
            continue;
          }
          videoCount++;
        }

        validEntries.add((file, mediaType, size));
      }

      if (validEntries.isEmpty) return;

      final newMediaItems = [
        for (final entry in validEntries)
          ExerciseMedia(
            name: entry.$1.name,
            path: entry.$1.path,
            type: entry.$2,
            sizeInBytes: entry.$3,
            mimeType: entry.$1.mimeType,
            readBytes: entry.$1.readAsBytes,
          ),
      ];

      if (!mounted) return;
      setState(() => _mediaItems.addAll(newMediaItems));
    } on Object {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Não foi possível acessar os arquivos selecionados.',
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<ExerciseMedia> _createExerciseMedia(
    XFile file,
    ExerciseMediaType type,
  ) async {
    final size = await (widget.fileSizeLoader?.call(file) ?? file.length());
    return ExerciseMedia(
      name: file.name,
      path: file.path,
      type: type,
      sizeInBytes: size,
      mimeType: file.mimeType,
      readBytes: file.readAsBytes,
    );
  }

  void _removeMediaItem(int index) {
    setState(() => _mediaItems.removeAt(index));
  }

  // Consolida as mídias anexadas no draft e avança para a revisão final.
  void _continue() {
    final updatedDraft = widget.draft.withMediaItems(_mediaItems);
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedDraft);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ExerciseConfirmationScreen(
          draft: updatedDraft,
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
                            FormProgressIndicator(
                              configuration: _progressConfiguration,
                              currentStep: _currentStep,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Mídias auxiliares',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Anexe uma ou mais imagens e\n'
                              'vídeos da execução do exercício\n'
                              'que sirvam como guia para que\n'
                              'seus atletas possam executá-lo.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 46),
                            AppAddItemButton(
                              buttonKey: const Key('pick-exercise-media-files'),
                              label: 'Adicionar mídia',
                              semanticsLabel:
                                  'Adicionar arquivos de imagem ou vídeo',
                              isLoading: _isPicking,
                              onPressed: _pickMediaFiles,
                            ),
                            if (_mediaItems.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildMediaList(context),
                            ],
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key('continue-exercise-media'),
                              onPressed: _isPicking ? null : _continue,
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

  // Exibe os arquivos anexados com ícone diferenciado para imagem ou vídeo e
  // barra de rolagem visível quando há múltiplos itens.
  Widget _buildMediaList(BuildContext context) {
    final visibleCount = math.min(_mediaItems.length, _maximumVisibleMedia);
    final listHeight =
        visibleCount * _mediaHeight + (visibleCount - 1) * _mediaSpacing;
    final isScrollable = _mediaItems.length > _maximumVisibleMedia;

    return SizedBox(
      key: const Key('exercise-media-list'),
      height: listHeight,
      child: Scrollbar(
        controller: _mediaScrollController,
        thumbVisibility: _mediaItems.length >= _maximumVisibleMedia,
        child: ListView.separated(
          controller: _mediaScrollController,
          primary: false,
          padding: EdgeInsets.only(
            right: _mediaItems.length >= _maximumVisibleMedia ? 14 : 0,
          ),
          itemCount: _mediaItems.length,
          separatorBuilder: (_, _) => const SizedBox(height: _mediaSpacing),
          itemBuilder: (context, index) {
            final media = _mediaItems[index];
            return AppRemovableItemTile(
              key: ValueKey('exercise-media-item-$index'),
              icon: media.type == ExerciseMediaType.video
                  ? Icons.movie_outlined
                  : Icons.image_outlined,
              label: media.name,
              removeKey: ValueKey('remove-exercise-media-$index'),
              onRemove: () => _removeMediaItem(index),
            );
          },
        ),
      ),
    );
  }
}
