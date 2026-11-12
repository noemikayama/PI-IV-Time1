// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura do download prévio, progresso, PdfViewer.data e nova
// tentativa após falha ao carregar documentos.
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/profile/data/models/trainer_profile_data.dart';
import 'package:horse_life/features/profile/presentation/screens/trainer_experience_pdf_screen.dart';

void main() {
  const document = TrainerExperienceDocument(
    fileName: 'experiencia_1.pdf',
    url: 'https://storage.example/experiencia_1.pdf',
  );

  testWidgets('downloads the PDF before opening it with PdfViewer.data', (
    tester,
  ) async {
    final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]);
    Uri? downloadedUri;
    Uint8List? renderedBytes;
    String? sourceName;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TrainerExperiencePdfScreen(
          document: document,
          pdfDownloader: (uri, onProgress) async {
            downloadedUri = uri;
            onProgress(5, 5);
            return bytes;
          },
          pdfDataViewerBuilder: (context, data, source, viewerKey) {
            renderedBytes = data;
            sourceName = source;
            return const SizedBox(key: Key('fake-pdf-data-viewer'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(downloadedUri, Uri.parse(document.url));
    expect(renderedBytes, bytes);
    expect(sourceName, document.url);
    expect(find.byKey(const Key('fake-pdf-data-viewer')), findsOneWidget);
  });

  testWidgets('shows progress while downloading PDF bytes', (tester) async {
    final download = Completer<Uint8List>();
    void Function(int, int?)? reportProgress;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TrainerExperiencePdfScreen(
          document: document,
          pdfDownloader: (uri, onProgress) {
            reportProgress = onProgress;
            return download.future;
          },
        ),
      ),
    );

    reportProgress!(25, 100);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Carregando PDF...'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
  });

  testWidgets('allows a failed download to retry', (tester) async {
    var downloadAttempts = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: TrainerExperiencePdfScreen(
          document: document,
          pdfDownloader: (uri, onProgress) async {
            downloadAttempts++;
            throw TimeoutException('Future not completed');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar o PDF.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.textContaining('TimeoutException'), findsNothing);

    await tester.tap(find.byKey(const Key('retry-pdf-button')));
    await tester.pumpAndSettle();

    expect(downloadAttempts, 2);
  });
}
