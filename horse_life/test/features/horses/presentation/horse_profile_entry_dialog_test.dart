// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Revisão da documentação dos cenários de validação e retorno dos
// modais compartilhados pelo perfil do cavalo.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura dos modais compartilhados de texto e lesão do perfil.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/horses/presentation/widgets/horse_injury_dialog.dart';
import 'package:horse_life/features/horses/presentation/widgets/horse_text_entry_dialog.dart';

void main() {
  testWidgets('modal de observação segue a estrutura compartilhada', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showHorseTextEntryDialog(
              context,
              title: 'Adicionar observação',
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('horse-text-entry-dialog')), findsOneWidget);
    expect(find.text('Adicionar observação'), findsOneWidget);
    expect(find.byTooltip('Fechar'), findsOneWidget);
    final save = tester.widget<OutlinedButton>(
      find.byKey(const Key('horse-entry-dialog-save-button')),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('modal de lesão apresenta os três campos do protótipo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showHorseInjuryDialog(context: context),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('horse-injury-entry-dialog')), findsOneWidget);
    expect(find.text('Data da lesão'), findsOneWidget);
    expect(find.text('Detalhes da lesão'), findsOneWidget);
    expect(find.text('Prescrição veterinária'), findsOneWidget);
    expect(find.text('DD/MM/AAAA'), findsOneWidget);
  });
}
