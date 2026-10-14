// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes dos tokens de cor, do tema claro e de
// fonte do HorseLife.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defines the institutional and semantic colors', () {
    expect(AppColors.prussianBlue, const Color(0xFF002240));
    expect(AppColors.blueSpruce, const Color(0xFF027068));
    expect(AppColors.seaGreen, const Color(0xFF009373));
    expect(AppColors.goldenApricot, const Color(0xFFCB904D));
    expect(AppColors.whiteSmoke, const Color(0xFFF4F4F4));
    expect(AppColors.grey, const Color(0xFF808080));
    expect(AppColors.alabasterGray, const Color(0xFFD9D9D9));
    expect(AppColors.pearlAqua, const Color(0xFF7AC4B4));
    expect(AppColors.tropicalTeal, const Color(0xFF38A3A5));
    expect(AppColors.success, const Color(0xFF5BBA6F));
    expect(AppColors.error, const Color(0xFFAA0000));
  });

  test('configures the brand and error colors in the light theme', () {
    final theme = AppTheme.light;

    expect(theme.scaffoldBackgroundColor, AppColors.whiteSmoke);
    expect(theme.colorScheme.primary, AppColors.seaGreen);
    expect(theme.colorScheme.error, AppColors.error);
  });

  test('uses League Spartan for headings and Urbanist for body text', () {
    final textTheme = AppTheme.light.textTheme;

    expect(textTheme.displayLarge?.fontFamily, startsWith('LeagueSpartan'));
    expect(textTheme.headlineMedium?.fontFamily, startsWith('LeagueSpartan'));
    expect(textTheme.titleSmall?.fontFamily, startsWith('LeagueSpartan'));
    expect(textTheme.bodyLarge?.fontFamily, startsWith('Urbanist'));
    expect(textTheme.bodySmall?.fontFamily, startsWith('Urbanist'));
    expect(textTheme.labelLarge?.fontFamily, startsWith('Urbanist'));
  });
}
