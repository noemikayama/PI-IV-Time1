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
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários pontuais sobre a responsabilidade do arquivo.
//
// -----------------------------------------------------------------------------

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Desenha o gráfico de distribuição dos planos do profissional.
class DashboardPlansDonut extends StatelessWidget {
  const DashboardPlansDonut({
    super.key,
    required this.active,
    required this.completed,
    required this.cancelled,
  });
  final int active, completed, cancelled;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: CustomPaint(painter: _PlansPainter(active, completed, cancelled)),
  );
}

class _PlansPainter extends CustomPainter {
  const _PlansPainter(this.active, this.completed, this.cancelled);
  final int active, completed, cancelled;
  @override
  void paint(Canvas canvas, Size size) {
    final total = active + completed + cancelled;
    if (total == 0) return;
    final side = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = side * .23;
    final radius = side * .49 - stroke / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final painter = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    var angle = -math.pi / 2;
    for (final (quantity, color) in <(int, Color)>[
      (cancelled, AppColors.inferno),
      (completed, AppColors.blueSpruce),
      (active, AppColors.pearlAqua),
    ]) {
      if (quantity <= 0) continue;
      final sweep = 2 * math.pi * quantity / total;
      painter.color = color;
      canvas.drawArc(rect, angle, sweep, false, painter);
      final percentage = quantity / total * 100;
      if (percentage >= 8) {
        final text = TextPainter(
          text: TextSpan(
            text: '${percentage.round()}%',
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: side * .115,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final middle = angle + sweep / 2;
        final pos =
            center +
            Offset(math.cos(middle) * radius, math.sin(middle) * radius);
        text.paint(canvas, pos - Offset(text.width / 2, text.height / 2));
      }
      angle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PlansPainter old) =>
      old.active != active ||
      old.completed != completed ||
      old.cancelled != cancelled;
}
