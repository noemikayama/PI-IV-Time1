// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição do callback onShowAllTrainings para navegação da lista de
// treinos recentes.
//
// Data: 01/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do getDashboard com contrato real e modo mock.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Remoção dos parâmetros de lista mock; consulta e filtros mantidos no repository.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários pontuais sobre a responsabilidade do arquivo.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import '../../data/models/dashboard_response.dart';
import '../../data/repositories/dashboard_repository.dart';
import 'dashboard_filters.dart';
import 'dashboard_training_card.dart';
import 'dashboard_metric_card.dart';
import 'dashboard_recent_list.dart';
import 'dashboard_empty_state.dart';

/// Consulta os indicadores de treinos por cavalo e período sem recalculá-los.
class DashboardLiveTrainingContent extends StatefulWidget {
  const DashboardLiveTrainingContent({
    super.key,
    required this.repository,
    this.onShowAllTrainings,
  });
  final DashboardRepository repository;
  final VoidCallback? onShowAllTrainings;
  @override
  State<DashboardLiveTrainingContent> createState() =>
      _DashboardLiveTrainingContentState();
}

class _DashboardLiveTrainingContentState
    extends State<DashboardLiveTrainingContent> {
  String _period = 'SEMPRE';
  String? _horseId;
  late Future<DashboardResponse> _future;
  List<Map<String, dynamic>> _horseOptions = [];
  static const periods = {
    'Desde sempre': 'SEMPRE',
    'Diário': 'DIARIO',
    'Semanal': 'SEMANAL',
    'Último mês': 'MENSAL',
    'Últimos 6 meses': 'SEMESTRAL',
    'Último ano': 'ANUAL',
  };
  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() {
    _future = widget.repository.getDashboard(
      period: _period,
      horseId: _horseId,
      professional: false,
    );
  }

  void _reload() {
    setState(_fetch);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<DashboardResponse>(
    future: _future,
    builder: (context, snapshot) {
      final data = snapshot.data;
      if (data != null) {
        _horseOptions = data.horses;
      }
      final selectedName = _horseId == null
          ? 'Todos'
          : _horseOptions
                    .where((h) => h['id'] == _horseId)
                    .map((h) => h['nome']?.toString() ?? 'Cavalo')
                    .firstOrNull ??
                'Todos';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardFilters(
            horse: selectedName,
            period: periods.keys.firstWhere((k) => periods[k] == _period),
            horses: [
              'Todos',
              ..._horseOptions.map((h) => h['nome']?.toString() ?? ''),
            ],
            periods: periods.keys.toList(),
            onHorseChanged: (name) {
              _horseId = name == 'Todos'
                  ? null
                  : _horseOptions
                        .where((h) => h['nome'] == name)
                        .map((h) => h['id']?.toString())
                        .firstOrNull;
              _reload();
            },
            onPeriodChanged: (name) {
              _period = periods[name] ?? 'SEMPRE';
              _reload();
            },
          ),
          const SizedBox(height: 22),
          if (snapshot.connectionState == ConnectionState.waiting)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(),
              ),
            )
          else if (snapshot.hasError)
            Center(
              child: Column(
                children: [
                  const Text('Não foi possível carregar o dashboard.'),
                  TextButton(
                    onPressed: _reload,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          else if (data == null || !data.hasData)
            const DashboardEmptyState()
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 18.0;
                final width = (constraints.maxWidth - gap) / 2;
                final train = data.section('treinosRealizados');
                final comp = data.section('cumprimentoTreinos');
                final freq = data.section('frequenciaExecucao');
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: width,
                      height: 478,
                      child: DashboardTrainingCard(
                        completedPercent: DashboardResponse.numeric(
                          train,
                          'percentualRealizados',
                        ).toDouble(),
                        partialPercent: DashboardResponse.numeric(
                          train,
                          'percentualParciais',
                        ).toDouble(),
                        total: DashboardResponse.numeric(
                          train,
                          'total',
                        ).toInt(),
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: Column(
                        children: [
                          DashboardMetricCard(
                            title: 'Percentual de cumprimento dos treinos',
                            value:
                                '${DashboardResponse.numeric(comp, 'percentual').round()}%',
                            gradient: const [
                              AppColors.goldenApricot,
                              Color(0xFFFFC488),
                            ],
                          ),
                          const SizedBox(height: 18),
                          DashboardMetricCard(
                            title: 'Frequência de execução dos treinos',
                            value:
                                '${DashboardResponse.numeric(freq, 'percentual').round()}%',
                            gradient: const [
                              AppColors.tropicalTeal,
                              AppColors.prussianBlue,
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 22),
            DashboardRecentList(
              title: 'Últimos treinos',
              liveTrainings: data.trainings,
              onShowAll: widget.onShowAllTrainings,
            ),
            if (data.role == 'RESPONSAVEL') ...[
              const SizedBox(height: 22),
              DashboardRecentList(
                title: 'Últimos Feedbacks',
                feedback: true,
                liveFeedbacks: data.feedbacks,
              ),
            ],
          ],
        ],
      );
    },
  );
}
