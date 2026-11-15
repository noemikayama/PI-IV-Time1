// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Revisão da documentação do cenário de localização, digitação e
// retorno da data selecionada no calendário.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da localização e do formato digitável do calendário.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/horses/presentation/widgets/horse_registration_calendar.dart';

void main() {
  testWidgets('entrada digitada usa DD/MM/AAAA e português', (tester) async {
    DateTime? selectedDate;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selectedDate = await showHorseRegistrationCalendar(
                context: context,
                initialDate: DateTime(2020, 6, 15),
                firstDate: DateTime(1980),
                lastDate: DateTime(2026, 11, 13),
                title: 'Data de nascimento',
              );
            },
            child: const Text('Abrir calendário'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir calendário'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Digite a data'), findsOneWidget);
    expect(find.text('DD/MM/AAAA'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '31/12/2020');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();

    expect(selectedDate, DateTime(2020, 12, 31));
  });
}
