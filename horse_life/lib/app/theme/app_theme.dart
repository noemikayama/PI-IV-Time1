// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do tema claro do HorseLife com paleta, tipografia e
// estilos globais para controles, campos e mensagens.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.seaGreen,
      onPrimary: Colors.white,
      secondary: AppColors.blueSpruce,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.whiteSmoke,
      onSurface: AppColors.prussianBlue,
    );

    final headingTextTheme = GoogleFonts.leagueSpartanTextTheme(_textTheme);
    final bodyTextTheme = GoogleFonts.urbanistTextTheme(_textTheme);
    
    final textTheme = TextTheme(
      displayLarge: headingTextTheme.displayLarge,
      displayMedium: headingTextTheme.displayMedium,
      displaySmall: headingTextTheme.displaySmall,
      headlineLarge: headingTextTheme.headlineLarge,
      headlineMedium: headingTextTheme.headlineMedium,
      headlineSmall: bodyTextTheme.headlineSmall,
      titleLarge: headingTextTheme.titleLarge,
      titleMedium: headingTextTheme.titleMedium,
      titleSmall: headingTextTheme.titleSmall,
      bodyLarge: bodyTextTheme.bodyLarge,
      bodyMedium: bodyTextTheme.bodyMedium,
      bodySmall: bodyTextTheme.bodySmall,
      labelLarge: bodyTextTheme.labelLarge,
      labelMedium: bodyTextTheme.labelMedium,
      labelSmall: bodyTextTheme.labelSmall,
    ).apply(bodyColor: AppColors.text, displayColor: AppColors.text);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.whiteSmoke,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.whiteSmoke,
        foregroundColor: AppColors.prussianBlue,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: AppColors.grey),
        labelStyle: TextStyle(color: AppColors.grey),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.seaGreen, width: 2),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.seaGreen, width: 2.5),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.seaGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.alabasterGray,
          disabledForegroundColor: AppColors.grey,
          minimumSize: const Size(48, 48),
          textStyle: textTheme.labelLarge,
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.seaGreen,
          textStyle: textTheme.labelLarge,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.seaGreen,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.prussianBlue,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.alabasterGray,
        thickness: 1,
      ),
    );
  }

  static const _textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
    displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
    displaySmall: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
    headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  );
}
