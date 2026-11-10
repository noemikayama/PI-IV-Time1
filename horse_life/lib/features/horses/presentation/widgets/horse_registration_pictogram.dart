// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 09/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Substituição dos desenhos manuais pelos ícones oficiais do
// Material Symbols Outlined (health_metrics e rheumatology).
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Ícones vetoriais locais para saúde e lesões.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:horse_life/app/theme/app_colors.dart';

enum HorsePictogram { health, injury }

/// Mantém os tamanhos e a cor sem desenhar símbolos manualmente.
class HorseRegistrationPictogram extends StatelessWidget {
  const HorseRegistrationPictogram({
    required this.kind,
    this.size = 24,
    super.key,
  });

  final HorsePictogram kind;
  final double size;

  @override
  Widget build(BuildContext context) => Icon(
    kind == HorsePictogram.health
        ? Symbols.health_metrics
        : Symbols.rheumatology,
    size: size,
    color: AppColors.blueSpruce,
  );
}
