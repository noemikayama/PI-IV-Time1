// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do contrato e das regras de localização, intervalo
// e entrada digitável do calendário compartilhado.
//
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Localização do seletor em português do Brasil e configuração da
// entrada digitada no formato DD/MM/AAAA.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Calendário da feature com tema HorseLife sem mudar o app inteiro.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

// Mesmo calendário para nascimento e lesões: cores locais da feature,
// sem afetar outros date pickers do aplicativo.
Future<DateTime?> showHorseRegistrationCalendar({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required String title,
}) => showDatePicker(
  context: context,
  locale: const Locale('pt', 'BR'),
  initialDate: initialDate,
  firstDate: firstDate,
  lastDate: lastDate,
  helpText: title,
  fieldLabelText: 'Digite a data',
  fieldHintText: 'DD/MM/AAAA',
  errorFormatText: 'Informe a data no formato DD/MM/AAAA.',
  errorInvalidText: 'Informe uma data válida.',
  cancelText: 'Cancelar',
  confirmText: 'Confirmar',
  keyboardType: TextInputType.datetime,
  builder: (context, child) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: AppColors.seaGreen,
        onPrimary: Colors.white,
        surface: AppColors.whiteSmoke,
        onSurface: AppColors.prussianBlue,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.whiteSmoke,
        headerBackgroundColor: AppColors.whiteSmoke,
        headerForegroundColor: AppColors.prussianBlue,
        subHeaderForegroundColor: AppColors.prussianBlue,
        surfaceTintColor: Colors.transparent,
        headerHeadlineStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 25,
        ),
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.seaGreen,
        ),
        todayBorder: const BorderSide(color: AppColors.seaGreen, width: 1.5),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.seaGreen : null,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.grey
              : states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.prussianBlue,
        ),
        yearBackgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? AppColors.seaGreen : null,
        ),
        yearForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? AppColors.grey
              : states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.prussianBlue,
        ),
        cancelButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.seaGreen,
        ),
        confirmButtonStyle: TextButton.styleFrom(
          foregroundColor: AppColors.seaGreen,
        ),
      ),
    ),
    child: child!,
  ),
);
