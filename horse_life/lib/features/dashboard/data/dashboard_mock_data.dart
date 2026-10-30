// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// HISTÓRICO DE ALTERAÇÕES
// 29/10/2026 - Criação do mock do dashboard.
// 29/10/2026 - Mock relacional de cavalos, treinos e feedbacks e snapshots por período.

class DashboardHorse {
  const DashboardHorse({required this.id, required this.name});
  final String id;
  final String name;
}

enum DashboardTrainingStatus { completed, partial }

class DashboardTraining {
  const DashboardTraining({
    required this.id,
    required this.horseId,
    required this.name,
    required this.plan,
    required this.date,
    required this.status,
  });
  final String id, horseId, name, plan;
  final DateTime date;
  final DashboardTrainingStatus status;
}

class DashboardFeedback {
  const DashboardFeedback({
    required this.id,
    required this.trainingId,
    required this.date,
    required this.comment,
  });
  final String id, trainingId, comment;
  final DateTime date;
}

/// Valores PRONTOS, simulando o payload agregado devolvido pela Cloud Function.
/// O Flutter apenas seleciona um snapshot, sem calcular porcentagens.
class DashboardStatistics {
  const DashboardStatistics({
    required this.completedPercent,
    required this.partialPercent,
    required this.total,
    required this.compliancePercent,
    required this.frequencyPercent,
  });
  final double completedPercent,
      partialPercent,
      compliancePercent,
      frequencyPercent;
  final int total;
  static const empty = DashboardStatistics(
    completedPercent: 0,
    partialPercent: 0,
    total: 0,
    compliancePercent: 0,
    frequencyPercent: 0,
  );
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.statistics,
    required this.trainings,
    required this.feedbacks,
  });
  final DashboardStatistics statistics;
  final List<DashboardTraining> trainings;
  final List<DashboardFeedback> feedbacks;
}

abstract final class DashboardMockData {
  static const horses = <DashboardHorse>[
    DashboardHorse(id: 'h1', name: 'Apolo'),
    DashboardHorse(id: 'h2', name: 'Luna'),
    DashboardHorse(id: 'h3', name: 'Thor'),
    DashboardHorse(id: 'h4', name: 'Estrela'),
    DashboardHorse(id: 'h5', name: 'Mel'), // Treinos, nenhum feedback
    DashboardHorse(id: 'h6', name: 'Ícaro'), // Sem treinos nem feedbacks
  ];
  static const periods = <String>[
    'Desde sempre',
    'Diário',
    'Semanal',
    'Último mês',
    'Últimos 6 meses',
    'Último ano',
  ];

  // Datas próximas ao dia do protótipo (29/10/2026), para testar todos os períodos.
  static final trainings = <DashboardTraining>[
    DashboardTraining(
      id: 't1',
      horseId: 'h1',
      name: 'Adestramento básico',
      plan: 'Plano de adestramento',
      date: DateTime(2026, 10, 29),
      status: DashboardTrainingStatus.completed,
    ),
    DashboardTraining(
      id: 't2',
      horseId: 'h1',
      name: 'Transições de marcha',
      plan: 'Plano de adestramento',
      date: DateTime(2026, 10, 26),
      status: DashboardTrainingStatus.partial,
    ),
    DashboardTraining(
      id: 't3',
      horseId: 'h1',
      name: 'Equilíbrio e postura',
      plan: 'Plano de adestramento',
      date: DateTime(2026, 9, 14),
      status: DashboardTrainingStatus.completed,
    ),
    DashboardTraining(
      id: 't4',
      horseId: 'h2',
      name: 'Resistência',
      plan: 'Condicionamento',
      date: DateTime(2026, 10, 28),
      status: DashboardTrainingStatus.completed,
    ),
    DashboardTraining(
      id: 't5',
      horseId: 'h2',
      name: 'Caminhada longa',
      plan: 'Condicionamento',
      date: DateTime(2026, 10, 17),
      status: DashboardTrainingStatus.completed,
    ),
    DashboardTraining(
      id: 't6',
      horseId: 'h2',
      name: 'Circuito',
      plan: 'Condicionamento',
      date: DateTime(2026, 7, 12),
      status: DashboardTrainingStatus.partial,
    ),
    DashboardTraining(
      id: 't7',
      horseId: 'h3',
      name: 'Saltos leves',
      plan: 'Preparação de saltos',
      date: DateTime(2026, 10, 24),
      status: DashboardTrainingStatus.completed,
    ),
    DashboardTraining(
      id: 't8',
      horseId: 'h3',
      name: 'Obstáculos',
      plan: 'Preparação de saltos',
      date: DateTime(2026, 5, 9),
      status: DashboardTrainingStatus.partial,
    ),
    DashboardTraining(
      id: 't9',
      horseId: 'h4',
      name: 'Alongamento',
      plan: 'Mobilidade',
      date: DateTime(2026, 10, 8),
      status: DashboardTrainingStatus.completed,
    ),
    DashboardTraining(
      id: 't10',
      horseId: 'h4',
      name: 'Coordenação',
      plan: 'Mobilidade',
      date: DateTime(2025, 12, 11),
      status: DashboardTrainingStatus.completed,
    ),
    DashboardTraining(
      id: 't11',
      horseId: 'h5',
      name: 'Passeio leve',
      plan: 'Rotina inicial',
      date: DateTime(2026, 10, 27),
      status: DashboardTrainingStatus.completed,
    ),
    DashboardTraining(
      id: 't12',
      horseId: 'h5',
      name: 'Trotes',
      plan: 'Rotina inicial',
      date: DateTime(2026, 8, 3),
      status: DashboardTrainingStatus.partial,
    ),
  ];

  // Cada feedback pertence a um treino pelo trainingId, nunca a um cavalo avulso.
  static final feedbacks = <DashboardFeedback>[
    DashboardFeedback(
      id: 'f1',
      trainingId: 't1',
      date: DateTime(2026, 10, 29),
      comment: 'Boa evolução no adestramento.',
    ),
    DashboardFeedback(
      id: 'f2',
      trainingId: 't2',
      date: DateTime(2026, 10, 27),
      comment: 'Reforçar transições.',
    ),
    DashboardFeedback(
      id: 'f3',
      trainingId: 't3',
      date: DateTime(2026, 9, 15),
      comment: 'Postura melhorou.',
    ),
    DashboardFeedback(
      id: 'f4',
      trainingId: 't4',
      date: DateTime(2026, 10, 29),
      comment: 'Ótima resistência.',
    ),
    DashboardFeedback(
      id: 'f5',
      trainingId: 't6',
      date: DateTime(2026, 7, 13),
      comment: 'Ajustar o ritmo.',
    ),
    DashboardFeedback(
      id: 'f6',
      trainingId: 't7',
      date: DateTime(2026, 10, 25),
      comment: 'Saltos consistentes.',
    ),
    DashboardFeedback(
      id: 'f7',
      trainingId: 't9',
      date: DateTime(2026, 10, 9),
      comment: 'Boa mobilidade.',
    ),
  ];

  static String horseName(String horseId) {
    for (final horse in horses) {
      if (horse.id == horseId) return horse.name;
    }
    return 'Cavalo';
  }

  static DashboardTraining? trainingById(String id) {
    for (final training in trainings) {
      if (training.id == id) return training;
    }
    return null;
  }

  // Snapshots estáticos de exemplo: todos os percentuais abaixo foram preenchidos
  // manualmente, NÃO são resultados de cálculos realizados pelo Flutter.
  // As contagens correspondem aos registros exibidos em cada período.
  static const Map<String, List<DashboardStatistics>> _stats = {
    'Todos': [
      DashboardStatistics(
        completedPercent: 67,
        partialPercent: 33,
        total: 12,
        compliancePercent: 83,
        frequencyPercent: 76,
      ),
      DashboardStatistics(
        completedPercent: 100,
        partialPercent: 0,
        total: 1,
        compliancePercent: 100,
        frequencyPercent: 100,
      ),
      DashboardStatistics(
        completedPercent: 80,
        partialPercent: 20,
        total: 5,
        compliancePercent: 90,
        frequencyPercent: 80,
      ),
      DashboardStatistics(
        completedPercent: 86,
        partialPercent: 14,
        total: 7,
        compliancePercent: 88,
        frequencyPercent: 78,
      ),
      DashboardStatistics(
        completedPercent: 64,
        partialPercent: 36,
        total: 11,
        compliancePercent: 85,
        frequencyPercent: 77,
      ),
      DashboardStatistics(
        completedPercent: 67,
        partialPercent: 33,
        total: 12,
        compliancePercent: 83,
        frequencyPercent: 76,
      ),
    ],
    'h1': [
      DashboardStatistics(
        completedPercent: 67,
        partialPercent: 33,
        total: 3,
        compliancePercent: 89,
        frequencyPercent: 80,
      ),
      DashboardStatistics(
        completedPercent: 100,
        partialPercent: 0,
        total: 1,
        compliancePercent: 100,
        frequencyPercent: 100,
      ),
      DashboardStatistics(
        completedPercent: 50,
        partialPercent: 50,
        total: 2,
        compliancePercent: 75,
        frequencyPercent: 70,
      ),
      DashboardStatistics(
        completedPercent: 50,
        partialPercent: 50,
        total: 2,
        compliancePercent: 75,
        frequencyPercent: 70,
      ),
      DashboardStatistics(
        completedPercent: 67,
        partialPercent: 33,
        total: 3,
        compliancePercent: 89,
        frequencyPercent: 80,
      ),
      DashboardStatistics(
        completedPercent: 67,
        partialPercent: 33,
        total: 3,
        compliancePercent: 89,
        frequencyPercent: 80,
      ),
    ],
    'h2': [
      DashboardStatistics(
        completedPercent: 67,
        partialPercent: 33,
        total: 3,
        compliancePercent: 83,
        frequencyPercent: 72,
      ),
      DashboardStatistics.empty,
      DashboardStatistics(
        completedPercent: 100,
        partialPercent: 0,
        total: 1,
        compliancePercent: 100,
        frequencyPercent: 100,
      ),
      DashboardStatistics(
        completedPercent: 100,
        partialPercent: 0,
        total: 2,
        compliancePercent: 100,
        frequencyPercent: 90,
      ),
      DashboardStatistics(
        completedPercent: 67,
        partialPercent: 33,
        total: 3,
        compliancePercent: 83,
        frequencyPercent: 72,
      ),
      DashboardStatistics(
        completedPercent: 67,
        partialPercent: 33,
        total: 3,
        compliancePercent: 83,
        frequencyPercent: 72,
      ),
    ],
    'h3': [
      DashboardStatistics(
        completedPercent: 50,
        partialPercent: 50,
        total: 2,
        compliancePercent: 75,
        frequencyPercent: 60,
      ),
      DashboardStatistics.empty,
      DashboardStatistics(
        completedPercent: 100,
        partialPercent: 0,
        total: 1,
        compliancePercent: 100,
        frequencyPercent: 100,
      ),
      DashboardStatistics(
        completedPercent: 100,
        partialPercent: 0,
        total: 1,
        compliancePercent: 100,
        frequencyPercent: 100,
      ),
      DashboardStatistics(
        completedPercent: 50,
        partialPercent: 50,
        total: 2,
        compliancePercent: 75,
        frequencyPercent: 60,
      ),
      DashboardStatistics(
        completedPercent: 50,
        partialPercent: 50,
        total: 2,
        compliancePercent: 75,
        frequencyPercent: 60,
      ),
    ],
    'h4': [
      DashboardStatistics(
        completedPercent: 100,
        partialPercent: 0,
        total: 2,
        compliancePercent: 100,
        frequencyPercent: 65,
      ),
      DashboardStatistics.empty,
      DashboardStatistics.empty,
      DashboardStatistics(
        completedPercent: 100,
        partialPercent: 0,
        total: 1,
        compliancePercent: 100,
        frequencyPercent: 75,
      ),
      DashboardStatistics(
        completedPercent: 100,
        partialPercent: 0,
        total: 1,
        compliancePercent: 100,
        frequencyPercent: 75,
      ),
      DashboardStatistics(
        completedPercent: 100,
        partialPercent: 0,
        total: 2,
        compliancePercent: 100,
        frequencyPercent: 65,
      ),
    ],
    'h5': [
      DashboardStatistics(
        completedPercent: 50,
        partialPercent: 50,
        total: 2,
        compliancePercent: 75,
        frequencyPercent: 55,
      ),
      DashboardStatistics.empty,
      DashboardStatistics(
        completedPercent: 100,
        partialPercent: 0,
        total: 1,
        compliancePercent: 100,
        frequencyPercent: 100,
      ),
      DashboardStatistics(
        completedPercent: 100,
        partialPercent: 0,
        total: 1,
        compliancePercent: 100,
        frequencyPercent: 100,
      ),
      DashboardStatistics(
        completedPercent: 50,
        partialPercent: 50,
        total: 2,
        compliancePercent: 75,
        frequencyPercent: 55,
      ),
      DashboardStatistics(
        completedPercent: 50,
        partialPercent: 50,
        total: 2,
        compliancePercent: 75,
        frequencyPercent: 55,
      ),
    ],
    'h6': [
      DashboardStatistics.empty,
      DashboardStatistics.empty,
      DashboardStatistics.empty,
      DashboardStatistics.empty,
      DashboardStatistics.empty,
      DashboardStatistics.empty,
    ],
  };

  /// Recorte temporal baseado em data de referência FIXA para testes repetíveis.
  /// O backend futuramente aplicará este recorte e retornará todas as métricas.
  static bool inPeriod(DateTime date, String period) {
    final today = DateTime(2026, 10, 29);
    final day = DateTime(date.year, date.month, date.day);
    if (day.isAfter(today)) return false;
    switch (period) {
      case 'Diário':
        return day == today;
      case 'Semanal':
        return !day.isBefore(today.subtract(const Duration(days: 6)));
      case 'Último mês':
        return !day.isBefore(today.subtract(const Duration(days: 29)));
      case 'Últimos 6 meses':
        return !day.isBefore(DateTime(2026, 4, 29));
      case 'Último ano':
        return !day.isBefore(DateTime(2025, 10, 29));
      default:
        return true;
    }
  }

  static DashboardSnapshot snapshot({
    required String horseId,
    required String period,
  }) {
    final matching =
        trainings
            .where(
              (t) =>
                  (horseId == 'Todos' || t.horseId == horseId) &&
                  inPeriod(t.date, period),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final validIds = matching.map((e) => e.id).toSet();
    final relatedFeedbacks =
        feedbacks
            .where(
              (f) =>
                  validIds.contains(f.trainingId) && inPeriod(f.date, period),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final periodIndex = periods.indexOf(period);
    final stats =
        _stats[horseId]?[periodIndex < 0 ? 0 : periodIndex] ??
        DashboardStatistics.empty;
    return DashboardSnapshot(
      statistics: stats,
      trainings: matching,
      feedbacks: relatedFeedbacks,
    );
  }
}
