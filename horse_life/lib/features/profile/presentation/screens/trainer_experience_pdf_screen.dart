// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Download prévio dos PDFs com progresso, tratamento de erro e
// nova tentativa antes da abertura dos bytes pelo PdfViewer.data.
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/features/profile/data/models/trainer_profile_data.dart';
import 'package:http/http.dart' as http;
import 'package:pdfrx/pdfrx.dart';

/// Constrói um documento alternativo em testes sem iniciar acesso à rede.
typedef ExperienceDocumentBuilder =
    Widget Function(BuildContext context, Uri documentUri);

/// Notifica bytes recebidos e tamanho total, quando o servidor o informa.
typedef PdfDownloadProgressCallback =
    void Function(int bytesDownloaded, int? totalBytes);

/// Baixa um PDF e devolve bytes completos para o PdfViewer.data.
typedef ExperiencePdfDownloader =
    Future<Uint8List> Function(
      Uri documentUri,
      PdfDownloadProgressCallback onProgress,
    );

/// Constrói um visualizador de dados injetável para testes de widget.
typedef ExperiencePdfDataViewerBuilder =
    Widget Function(
      BuildContext context,
      Uint8List data,
      String sourceName,
      Key viewerKey,
    );

const _downloadTimeout = Duration(seconds: 30);

/// Faz download por streaming, aplica timeout por etapa e valida a assinatura.
///
/// A validação de `%PDF-` evita entregar ao PDFium páginas HTML de erro ou
/// respostas inesperadas do Storage, que produziriam mensagens pouco úteis.
Future<Uint8List> downloadPdfBytes(
  Uri documentUri,
  PdfDownloadProgressCallback onProgress,
) async {
  final client = http.Client();
  try {
    final request = http.Request('GET', documentUri);
    final response = await client.send(request).timeout(_downloadTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw http.ClientException(
        'O servidor recusou o download (${response.statusCode}).',
        documentUri,
      );
    }

    final bytes = BytesBuilder(copy: false);
    var downloaded = 0;
    final total = response.contentLength;
    await for (final chunk in response.stream.timeout(_downloadTimeout)) {
      bytes.add(chunk);
      downloaded += chunk.length;
      onProgress(downloaded, total);
    }

    final data = bytes.takeBytes();
    final isPdf =
        data.length >= 5 &&
        data[0] == 0x25 &&
        data[1] == 0x50 &&
        data[2] == 0x44 &&
        data[3] == 0x46 &&
        data[4] == 0x2D;
    if (!isPdf) {
      throw const FormatException('O arquivo recebido não é um PDF válido.');
    }
    return data;
  } finally {
    client.close();
  }
}

/// Baixa o PDF completamente e então o exibe pelo [PdfViewer.data].
class TrainerExperiencePdfScreen extends StatefulWidget {
  const TrainerExperiencePdfScreen({
    required this.document,
    this.documentBuilder,
    this.pdfDownloader = downloadPdfBytes,
    this.pdfDataViewerBuilder,
    super.key,
  });

  final TrainerExperienceDocument document;

  /// Substituição completa do documento usada pelos testes legados do perfil.
  final ExperienceDocumentBuilder? documentBuilder;

  /// Estratégia de download; injetável para simular progresso e falhas.
  final ExperiencePdfDownloader pdfDownloader;

  /// Estratégia de renderização dos bytes; produção usa PdfViewer.data.
  final ExperiencePdfDataViewerBuilder? pdfDataViewerBuilder;

  @override
  State<TrainerExperiencePdfScreen> createState() =>
      _TrainerExperiencePdfScreenState();
}

class _TrainerExperiencePdfScreenState
    extends State<TrainerExperiencePdfScreen> {
  late Future<Uint8List>? _downloadFuture;
  int _bytesDownloaded = 0;
  int? _totalBytes;
  int _loadAttempt = 0;

  @override
  void initState() {
    super.initState();
    _downloadFuture = widget.documentBuilder == null ? _download() : null;
  }

  @override
  void didUpdateWidget(covariant TrainerExperiencePdfScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.url != widget.document.url ||
        oldWidget.pdfDownloader != widget.pdfDownloader ||
        oldWidget.documentBuilder != widget.documentBuilder) {
      _bytesDownloaded = 0;
      _totalBytes = null;
      _downloadFuture = widget.documentBuilder == null ? _download() : null;
    }
  }

  Future<Uint8List> _download() {
    final uri = Uri.parse(widget.document.url);
    final completer = Completer<Uint8List>();
    // O download começa após o primeiro frame para que FutureBuilder esteja
    // inscrito antes de uma estratégia injetada falhar de forma síncrona.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        completer.complete(await widget.pdfDownloader(uri, _updateProgress));
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  void _updateProgress(int bytesDownloaded, int? totalBytes) {
    if (!mounted) return;
    setState(() {
      _bytesDownloaded = bytesDownloaded;
      _totalBytes = totalBytes;
    });
  }

  void _retry() {
    setState(() {
      _loadAttempt++;
      _bytesDownloaded = 0;
      _totalBytes = null;
      _downloadFuture = _download();
    });
  }

  @override
  Widget build(BuildContext context) {
    final documentUri = Uri.parse(widget.document.url);
    return Scaffold(
      backgroundColor: AppColors.whiteSmoke,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 68,
        leading: IconButton(
          key: const Key('close-experience-pdf-button'),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.seaGreen,
            size: 30,
          ),
        ),
        title: Text(
          widget.document.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.text,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
      body:
          widget.documentBuilder?.call(context, documentUri) ??
          FutureBuilder<Uint8List>(
            future: _downloadFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) return _buildPdfViewer(snapshot.data!);
              if (snapshot.hasError) return _PdfLoadError(onRetry: _retry);
              return _PdfLoadingBanner(
                bytesDownloaded: _bytesDownloaded,
                totalBytes: _totalBytes,
              );
            },
          ),
    );
  }

  Widget _buildPdfViewer(Uint8List data) {
    final viewerKey = ValueKey('trainer-experience-pdf-viewer-$_loadAttempt');
    final builder = widget.pdfDataViewerBuilder;
    if (builder != null) {
      return builder(context, data, widget.document.url, viewerKey);
    }
    return PdfViewer.data(
      data,
      sourceName: widget.document.url,
      key: viewerKey,
      params: PdfViewerParams(
        errorBannerBuilder: (context, error, stackTrace, documentRef) {
          return _PdfLoadError(onRetry: _retry);
        },
      ),
    );
  }
}

class _PdfLoadingBanner extends StatelessWidget {
  const _PdfLoadingBanner({
    required this.bytesDownloaded,
    required this.totalBytes,
  });

  final int bytesDownloaded;
  final int? totalBytes;

  @override
  Widget build(BuildContext context) {
    final total = totalBytes;
    final progress = total != null && total > 0
        ? (bytesDownloaded / total).clamp(0.0, 1.0)
        : null;
    return ColoredBox(
      color: AppColors.whiteSmoke,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 48,
              child: CircularProgressIndicator(value: progress),
            ),
            const SizedBox(height: 18),
            Text(
              'Carregando PDF...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PdfLoadError extends StatelessWidget {
  const _PdfLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: AppColors.whiteSmoke,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 56,
              ),
              const SizedBox(height: 18),
              Text(
                'Não foi possível carregar o PDF.',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Verifique sua conexão e tente novamente.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                key: const Key('retry-pdf-button'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.seaGreen,
                  side: const BorderSide(color: AppColors.seaGreen, width: 2),
                  minimumSize: const Size(220, 52),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
