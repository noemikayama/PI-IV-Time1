// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do teste de regressão da navegação semanal para garantir
// que o callback de setState não retorne Future; documentação do cenário e do
// carregador determinístico usado no teste.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';
import 'package:horse_life/features/training/data/repositories/training_agenda_repository.dart';
import 'package:horse_life/features/training/presentation/screens/connected_training_agenda_screen.dart';

void main() {
  // Aciona a mesma seta usada na interface e captura exceções do framework para
  // detectar especificamente retornos assíncronos indevidos em setState.
  testWidgets('loads another week without returning a Future from setState', (
    tester,
  ) async {
    final loader = _FakeTrainingAgendaLoader();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ConnectedTrainingAgendaScreen(loader: loader)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('agenda-next-week')));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(loader.requestedDates, [null, DateTime(2026, 11, 25)]);
  });
}

// Registra as datas solicitadas e responde imediatamente com uma semana fixa,
// isolando o teste de Firebase, rede e relógio.
class _FakeTrainingAgendaLoader implements TrainingAgendaLoader {
  final requestedDates = <DateTime?>[];

  @override
  Future<TrainingAgendaData> fetchAgenda({DateTime? date}) {
    requestedDates.add(date);
    return Future.value(
      TrainingAgendaData(
        audience: TrainingAgendaAudience.guardian,
        today: DateTime(2026, 11, 18),
        weekStart: DateTime(2026, 11, 16),
        weekEnd: DateTime(2026, 11, 22),
        activePlansCount: 0,
        plans: const [],
        weekTrainings: const [],
        todayTrainings: const [],
        history: const [],
      ),
    );
  }
}
