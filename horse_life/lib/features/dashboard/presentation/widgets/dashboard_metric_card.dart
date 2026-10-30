// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// HISTÓRICO DE ALTERAÇÕES
// 29/10/2026 - Card modular de indicadores.
// 30/10/2026 - Ajuste de alinhamento e proporções conforme protótipo Figma.
import 'package:flutter/material.dart';
import 'dashboard_text_styles.dart';

class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.gradient,
  });
  final String title, value;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) => Container(
    height: 230,
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(15, 18, 15, 15),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        colors: gradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: DashboardTextStyles.cardTitle(context)),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: DashboardTextStyles.metricValue(context),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
