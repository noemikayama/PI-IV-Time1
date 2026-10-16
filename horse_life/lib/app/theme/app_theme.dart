// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Substituição do carregamento dinâmico pela aplicação das famílias
// locais LeagueSpartan e Urbanist na escala tipográfica central do tema.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do tema claro do HorseLife com paleta, tipografia e
// estilos globais para controles, campos e mensagens.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'app_colors.dart';

// Constrói os temas globais da aplicação a partir dos tokens institucionais.
abstract final class AppTheme {
  // Tema claro utilizado atualmente pelo MaterialApp.
  static ThemeData get light {
    // Mapeamento das cores da marca para os papéis semânticos do Material.
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

    // Aplicação das famílias tipográficas sobre a escala definida abaixo.
    final headingTextTheme = _textTheme.apply(fontFamily: 'LeagueSpartan');
    final bodyTextTheme = _textTheme.apply(fontFamily: 'Urbanist');

    // Combinação de League Spartan nos títulos e Urbanist nos demais textos.
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

    // Reúne as definições globais consumidas pelos widgets Material.
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.whiteSmoke,
      textTheme: textTheme,
      // Superfícies e barras de navegação.
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.whiteSmoke,
        foregroundColor: AppColors.prussianBlue,
        surfaceTintColor: Colors.transparent,
      ),
      // Estados visuais dos campos de formulário.
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
      // Botões primários e secundários.
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
      // Feedback de carregamento e mensagens temporárias.
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.seaGreen,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.prussianBlue,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      // Elementos auxiliares de separação de conteúdo.
      dividerTheme: const DividerThemeData(
        color: AppColors.alabasterGray,
        thickness: 1,
      ),
    );
  }

  // Escala tipográfica base; as famílias locais são aplicadas por categoria.
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
    labelLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    labelMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
  );
}
