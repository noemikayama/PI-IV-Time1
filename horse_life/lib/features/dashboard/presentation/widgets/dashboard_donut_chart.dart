// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 29/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Modularização do Dashboard Guardian e preparação para dados da Cloud Function.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários
// pontuais sobre a responsabilidade do arquivo.
//
// Data: 11/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Substituição do CustomPainter por fl_chart, mantendo as proporções,
// a identidade visual do Figma e os valores recebidos do backend.
// -----------------------------------------------------------------------------

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Exibe a distribuição de treinos realizados e parciais.
/// Os percentuais já chegam calculados pela Cloud Function getDashboard.
class DashboardDonutChart extends StatelessWidget {
  const DashboardDonutChart({
    super.key,
    required this.completedPercent,
    required this.partialPercent,
  });

  final double completedPercent;
  final double partialPercent;

  @override
  Widget build(BuildContext context) {
    // Mantém a área quadrada e calcula apenas tamanhos visuais do gráfico.
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final completed = _positivePercent(completedPercent);
          final partial = _positivePercent(partialPercent);

          // Não cria uma fatia fictícia quando não existem dados.
          if (completed + partial == 0) {
            return const SizedBox.expand();
          }

          final labelSize = (side * 0.115).clamp(10.0, 22.0).toDouble();
          final outerRadius = side * 0.49;

          return PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: side * 0.26,
              centerSpaceColor: AppColors.whiteSmoke,
              pieTouchData: PieTouchData(enabled: false),
              // A fatia parcial começa no topo, conforme o protótipo.
              sections: [
                if (partial > 0)
                  _section(
                    value: partial,
                    color: AppColors.blueSpruce,
                    outerRadius: outerRadius,
                    labelSize: labelSize,
                  ),
                if (completed > 0)
                  _section(
                    value: completed,
                    color: AppColors.pearlAqua,
                    outerRadius: outerRadius,
                    labelSize: labelSize,
                  ),
              ],
            ),
            // Evita animação no primeiro carregamento ou na troca dos filtros.
            duration: Duration.zero,
          );
        },
      ),
    );
  }

  /// Proteção apenas visual contra valores negativos ou não finitos.
  static double _positivePercent(double value) {
    return value.isFinite && value > 0 ? value : 0.0;
  }

  static PieChartSectionData _section({
    required double value,
    required Color color,
    required double outerRadius,
    required double labelSize,
  }) {
    return PieChartSectionData(
      value: value,
      color: color,
      radius: outerRadius,
      title: '${value.round()}%',
      // Os rótulos permanecem horizontais e centralizados no anel.
      titlePositionPercentageOffset: 0.76,
      titleStyle: TextStyle(
        color: Colors.white,
        fontFamily: 'Urbanist',
        fontSize: labelSize,
        fontWeight: FontWeight.w400,
        height: 1,
        letterSpacing: 0,
      ),
      // Uma fatia muito pequena não comporta um rótulo legível.
      showTitle: value >= 3,
    );
  }
}
