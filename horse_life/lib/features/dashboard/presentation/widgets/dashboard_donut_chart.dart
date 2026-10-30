// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// HISTÓRICO DE ALTERAÇÕES
// 29/10/2026 - Modularização do Dashboard Guardian e preparação para dados da Cloud Function.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Proporções recebidas prontas da fonte de dados; não realiza cálculo de negócio.
class DashboardDonutChart extends StatelessWidget {
  const DashboardDonutChart({
    super.key,
    required this.completedPercent,
    required this.partialPercent,
  });
  final double completedPercent, partialPercent;
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1,
    child: CustomPaint(
      painter: _DonutPainter(completedPercent, partialPercent),
    ),
  );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter(this.completed, this.partial);
  final double completed, partial;
  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = side * .49;
    final stroke = side * .23;
    final rect = Rect.fromCircle(
      center: center,
      radius: outerRadius - stroke / 2,
    );
    final p = (partial / 100).clamp(0.0, 1.0);
    final c = (completed / 100).clamp(0.0, 1.0);
    final total = p + c;
    final pSweep = total > 0 ? 2 * math.pi * p / total : 0.0;
    final cSweep = total > 0 ? 2 * math.pi * c / total : 0.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    paint.color = AppColors.blueSpruce;
    canvas.drawArc(rect, -math.pi / 2, pSweep, false, paint);
    paint.color = AppColors.pearlAqua;
    canvas.drawArc(rect, -math.pi / 2 + pSweep, cSweep, false, paint);
    // Os rótulos acompanham o ângulo central de cada fatia.
    final labelRadius = outerRadius - stroke / 2;
    void label(double value, double angle) {
      if (value <= 0) return;
      final text = TextPainter(
        text: TextSpan(
          text: '${value.round()}%',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Urbanist',
            fontSize: side * .115,
            fontWeight: FontWeight.w400,
            height: 1.0,
            letterSpacing: 0,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      final position =
          center +
          Offset(math.cos(angle) * labelRadius, math.sin(angle) * labelRadius);
      text.paint(canvas, position - Offset(text.width / 2, text.height / 2));
    }

    label(partial, -math.pi / 2 + pSweep / 2);
    label(completed, -math.pi / 2 + pSweep + cSweep / 2);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.completed != completed || old.partial != partial;
}
