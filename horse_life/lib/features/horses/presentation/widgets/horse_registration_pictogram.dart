// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Ícones vetoriais locais para saúde (cruz com pulso) e lesões
// (articulação), aproximando os pictogramas do protótipo do HorseLife.
// Não requer novas dependências nem registro de arquivos no pubspec.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

enum HorsePictogram { health, injury }

/// Pequenos pictogramas vetoriais: não dependem de pacote de ícones externo.
class HorseRegistrationPictogram extends StatelessWidget {
  const HorseRegistrationPictogram({
    required this.kind,
    this.size = 24,
    super.key,
  });

  final HorsePictogram kind;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _HorsePictogramPainter(kind)),
  );
}

class _HorsePictogramPainter extends CustomPainter {
  const _HorsePictogramPainter(this.kind);
  final HorsePictogram kind;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    final line = Paint()
      ..color = AppColors.blueSpruce
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (kind == HorsePictogram.health) {
      // Cruz médica contornada + sinal de pulso, como na tela de observações.
      final cross = Path()
        ..moveTo(8, 2.5)
        ..lineTo(16, 2.5)
        ..lineTo(16, 8)
        ..lineTo(21.5, 8)
        ..lineTo(21.5, 16)
        ..lineTo(16, 16)
        ..lineTo(16, 21.5)
        ..lineTo(8, 21.5)
        ..lineTo(8, 16)
        ..lineTo(2.5, 16)
        ..lineTo(2.5, 8)
        ..lineTo(8, 8)
        ..close();
      canvas.drawPath(cross, line);
      final pulse = Path()
        ..moveTo(4.5, 12)
        ..lineTo(8.5, 12)
        ..lineTo(10, 9.5)
        ..lineTo(12.8, 15)
        ..lineTo(14.4, 12)
        ..lineTo(19.5, 12);
      canvas.drawPath(pulse, line..strokeWidth = 1.65);
    } else {
      // Articulação com linhas de dor: representa a lesão, não uma bandagem.
      final upperBone = Path()
        ..moveTo(7, 2)
        ..lineTo(7, 6)
        ..quadraticBezierTo(5, 9, 8, 11)
        ..quadraticBezierTo(12, 13, 15.5, 10)
        ..quadraticBezierTo(17, 8, 15, 6)
        ..lineTo(15, 2);
      canvas.drawPath(upperBone, line);
      final lowerBone = Path()
        ..moveTo(8, 12)
        ..quadraticBezierTo(7, 14, 9.5, 16)
        ..lineTo(9.5, 22)
        ..moveTo(15, 12)
        ..quadraticBezierTo(16.5, 14.5, 14, 16)
        ..lineTo(14, 22);
      canvas.drawPath(lowerBone, line);
      final rays = Path()
        ..moveTo(19, 6)
        ..lineTo(22, 4.5)
        ..moveTo(19.5, 11)
        ..lineTo(22.5, 11)
        ..moveTo(19, 16)
        ..lineTo(22, 17.5);
      canvas.drawPath(rays, line..strokeWidth = 1.8);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HorsePictogramPainter oldDelegate) =>
      oldDelegate.kind != kind;
}
