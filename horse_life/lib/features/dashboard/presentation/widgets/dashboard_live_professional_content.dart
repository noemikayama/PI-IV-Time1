// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 01/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do getDashboard com contrato real e modo mock.
//
// Data: 01/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Correção do setState síncrono na atualização do painel profissional.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Substituição do modelo mock pelo DTO real dos indicadores profissionais.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários pontuais sobre a responsabilidade do arquivo.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../data/models/dashboard_response.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/models/trainer_professional_snapshot.dart';
import 'trainer_professional_content.dart';

/// Solicita à Function os indicadores exclusivos do painel profissional.
class DashboardLiveProfessionalContent extends StatefulWidget {
  const DashboardLiveProfessionalContent({super.key, required this.repository});
  final DashboardRepository repository;
  @override
  State<DashboardLiveProfessionalContent> createState() =>
      _DashboardLiveProfessionalContentState();
}

class _DashboardLiveProfessionalContentState
    extends State<DashboardLiveProfessionalContent> {
  String _period = 'SEMPRE';
  late Future<DashboardResponse> _future;
  static const _periods = {
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
      professional: true,
    );
  }

  void _reload() {
    setState(() {
      _fetch();
    });
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<DashboardResponse>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting)
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: CircularProgressIndicator(),
          ),
        );
      if (snapshot.hasError)
        return Center(
          child: Column(
            children: [
              const Text('Falha ao carregar painel profissional.'),
              TextButton(
                onPressed: _reload,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        );
      final data = snapshot.data;
      if (data == null) return const SizedBox.shrink();
      final plans = data.section('planosCriados');
      final feedback = data.section('feedbacksDados');
      final mapped = TrainerProfessionalSnapshot(
        createdPlans: DashboardResponse.numeric(plans, 'total').toInt(),
        activePlans: DashboardResponse.numeric(plans, 'ativos').toInt(),
        completedPlans: DashboardResponse.numeric(plans, 'concluidos').toInt(),
        cancelledPlans: DashboardResponse.numeric(plans, 'cancelados').toInt(),
        feedbackPercent: DashboardResponse.numeric(
          feedback,
          'percentual',
        ).toInt(),
        clients: data.number('clientesVinculados'),
        linkedHorses: data.number('cavalosVinculados'),
        evaluations: data.number('avaliacoesFeitas'),
        exercises: data.number('exerciciosCriados'),
      );
      return TrainerProfessionalContent(
        liveData: mapped,
        onPeriodChanged: (selection) {
          _period = _periods[selection] ?? 'SEMPRE';
          _reload();
        },
      );
    },
  );
}
