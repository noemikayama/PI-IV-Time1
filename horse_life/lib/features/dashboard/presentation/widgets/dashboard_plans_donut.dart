// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Donut reutilizável para status de planos profissionais.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários
// pontuais sobre a responsabilidade do arquivo.
//
// Data: 11/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Migração do desenho manual para fl_chart, mantendo a ordem de
// status, as cores institucionais e a apresentação dos percentuais.
// -----------------------------------------------------------------------------

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Exibe a distribuição dos planos do profissional por status.
/// Recebe as quantidades prontas do backend; calcula somente a proporção
/// necessária ao desenho e ao rótulo de cada fatia.
class DashboardPlansDonut extends StatelessWidget {
  const DashboardPlansDonut({
    super.key,
    required this.active,
    required this.completed,
    required this.cancelled,
  });

  final int active;
  final int completed;
  final int cancelled;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final validActive = active > 0 ? active : 0;
          final validCompleted = completed > 0 ? completed : 0;
          final validCancelled = cancelled > 0 ? cancelled : 0;
          final total = validActive + validCompleted + validCancelled;

          // Sem planos: mantém o espaço do gráfico, sem fatias artificiais.
          if (total == 0) {
            return const SizedBox.expand();
          }

          final side = constraints.biggest.shortestSide;
          final outerRadius = side * 0.49;
          final labelSize = (side * 0.115).clamp(10.0, 22.0).toDouble();

          return PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: side * 0.26,
              centerSpaceColor: AppColors.whiteSmoke,
              pieTouchData: PieTouchData(enabled: false),
              // A sequência reproduz o Figma: cancelados, concluídos, ativos.
              sections: [
                if (validCancelled > 0)
                  _section(
                    value: validCancelled,
                    total: total,
                    color: AppColors.inferno,
                    outerRadius: outerRadius,
                    labelSize: labelSize,
                  ),
                if (validCompleted > 0)
                  _section(
                    value: validCompleted,
                    total: total,
                    color: AppColors.blueSpruce,
                    outerRadius: outerRadius,
                    labelSize: labelSize,
                  ),
                if (validActive > 0)
                  _section(
                    value: validActive,
                    total: total,
                    color: AppColors.pearlAqua,
                    outerRadius: outerRadius,
                    labelSize: labelSize,
                  ),
              ],
            ),
            duration: Duration.zero,
          );
        },
      ),
    );
  }

  static PieChartSectionData _section({
    required int value,
    required int total,
    required Color color,
    required double outerRadius,
    required double labelSize,
  }) {
    // Apenas a representação visual: as quantidades continuam sendo do backend.
    final percent = value / total * 100;
    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      radius: outerRadius,
      title: '${percent.round()}%',
      titlePositionPercentageOffset: 0.76,
      titleStyle: TextStyle(
        color: Colors.white,
        fontFamily: 'Urbanist',
        fontSize: labelSize,
        fontWeight: FontWeight.w400,
        height: 1,
        letterSpacing: 0,
      ),
      // Mantém rótulos pequenos como o de 3% do Figma quando legíveis.
      showTitle: percent >= 3,
    );
  }
}
