// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Ajuste de dimensões dos cards de métricas (altura 155px) para
// proporções quadradas e alinhamento consistente com os cards de gráficos.
//
// Data: 29/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Card modular de indicadores.
//
// Data: 30/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Ajuste de alinhamento e proporções conforme protótipo Figma.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários pontuais sobre a responsabilidade do arquivo.
//
// Data: 11/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Uso direto do tema nos títulos e valores percentuais dos cards.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// Apresenta um indicador percentual com título e fundo em degradê.
class DashboardMetricCard extends StatelessWidget {
  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.gradient,
    this.height = 155,
  });
  final String title, value;
  final List<Color> gradient;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: 0,
            color: Colors.white,
          ),
        ),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  letterSpacing: 0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
