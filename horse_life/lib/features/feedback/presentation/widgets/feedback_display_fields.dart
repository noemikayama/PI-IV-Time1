// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Extração das linhas de informação e caixas de relato utilizadas
// tanto no registro de execução quanto na consulta de feedback.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Linha rotulada, para metadados curtos de execução e feedback.
class FeedbackDetailLine extends StatelessWidget {
  const FeedbackDetailLine({
    required this.label,
    required this.value,
    this.bottomPadding = 8,
    super.key,
  });

  final String label;
  final String value;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: bottomPadding),
    child: Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 19),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    ),
  );
}

/// Texto de resposta somente leitura no padrão visual dos cards da feature.
class FeedbackReadOnlyField extends StatelessWidget {
  const FeedbackReadOnlyField({
    required this.label,
    required this.value,
    this.description,
    super.key,
  });

  final String label;
  final String value;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: textTheme.titleLarge?.copyWith(fontSize: 20)),
        if (description != null) ...[
          const SizedBox(height: 5),
          Text(description!, style: textTheme.bodyLarge),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.whiteSmoke,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: textTheme.bodyLarge?.copyWith(fontSize: 19),
          ),
        ),
      ],
    );
  }
}

String formatFeedbackDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year}';

String trainingExecutionStatusLabel(String value) => switch (value) {
  'REALIZADO' => 'Realizado',
  'PARCIAL' => 'Parcial',
  'NAO_REALIZADO' => 'Não realizado',
  'CANCELADO' => 'Cancelado',
  _ => 'Planejado',
};
