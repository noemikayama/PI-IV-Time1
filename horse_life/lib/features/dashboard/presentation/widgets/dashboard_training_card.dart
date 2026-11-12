// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 29/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Card de treinos realizados com donut modular.
//
// Data: 30/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Ajustes de margens, legenda e total segundo protótipo Figma.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários pontuais sobre a responsabilidade do arquivo.
//
// Data: 11/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Aplicação do tema no título do card, preservando as medidas do Figma.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'dashboard_donut_chart.dart';

/// Mostra o total de treinos e o donut dos percentuais de realização.
class DashboardTrainingCard extends StatelessWidget {
  const DashboardTrainingCard({
    super.key,
    required this.completedPercent,
    required this.partialPercent,
    required this.total,
  });
  final double completedPercent, partialPercent;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 18, 12, 18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: [AppColors.seaGreen, AppColors.pearlAqua],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Treinos\nrealizados',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.0,
              letterSpacing: 0,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(9, 12, 9, 12),
            decoration: BoxDecoration(
              color: AppColors.whiteSmoke,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                DashboardDonutChart(
                  completedPercent: completedPercent,
                  partialPercent: partialPercent,
                ),
                const SizedBox(height: 8),
                _legend(AppColors.pearlAqua, 'Realizados'),
                _legend(AppColors.blueSpruce, 'Parciais'),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Text(
                          'total: ',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 19,
                            height: 1,
                          ),
                        ),
                      ),
                      Text(
                        '$total',
                        style: const TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 54,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _legend(Color color, String text) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 13, height: 13, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontFamily: 'Urbanist', fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
