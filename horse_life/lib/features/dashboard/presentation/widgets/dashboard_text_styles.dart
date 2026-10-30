// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// HISTÓRICO DE ALTERAÇÕES
// 29/10/2026 - Estilos tipográficos reutilizáveis do Dashboard,
//                baseados nas famílias configuradas no AppTheme.
import 'package:flutter/material.dart';

abstract final class DashboardTextStyles {
  /// Título principal: League Spartan Bold, 32 px, line-height 100%.
  static TextStyle pageTitle(BuildContext context) =>
      Theme.of(context).textTheme.displaySmall!.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 0,
      );

  /// Títulos dos indicadores: League Spartan Bold, 22 px.
  static TextStyle cardTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 0,
        color: Colors.white,
      );

  /// Números principais: Urbanist Regular, 54 px.
  static TextStyle metricValue(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.copyWith(
        fontSize: 54,
        fontWeight: FontWeight.w400,
        height: 1.0,
        letterSpacing: 0,
        color: Colors.white,
      );
}
