// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do contrato e das regras de localização, intervalo
// e entrada digitável do calendário compartilhado.
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Re-exportação e delegação do seletor de data para showAppDatePicker
// em core/widgets, com localização em português e padrão DD/MM/AAAA.
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

export '../../../../core/widgets/app_date_picker_field.dart';

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';

/// Delegação retrocompatível para o seletor de data padronizado do aplicativo.
Future<DateTime?> showHorseRegistrationCalendar({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  required String title,
}) => showAppDatePicker(
  context: context,
  initialDate: initialDate,
  firstDate: firstDate,
  lastDate: lastDate,
  title: title,
);
