// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do campo e seletor de data padronizado e localizado em
// português (DD/MM/AAAA) em core/widgets para reutilização no aplicativo.
// -----------------------------------------------------------------------------

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Formata uma data no padrão brasileiro DD/MM/AAAA ou retorna o placeholder.
String formatAppDate(DateTime? date, {String placeholder = 'DD/MM/AAAA'}) {
  if (date == null) return placeholder;
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year.toString().padLeft(4, '0')}';
}

/// Localização nativa em português (Brasil) com formato DD/MM/AAAA para o DatePicker.
class PtBrMaterialLocalizations extends DefaultMaterialLocalizations {
  const PtBrMaterialLocalizations();

  static const List<String> _months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

  static const List<String> _shortMonths = [
    'jan.',
    'fev.',
    'mar.',
    'abr.',
    'mai.',
    'jun.',
    'jul.',
    'ago.',
    'set.',
    'out.',
    'nov.',
    'dez.',
  ];

  static const List<String> _weekdays = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo',
  ];

  static const List<String> _shortWeekdays = [
    'Seg.',
    'Ter.',
    'Qua.',
    'Qui.',
    'Sex.',
    'Sáb.',
    'Dom.',
  ];

  @override
  List<String> get narrowWeekdays => const <String>[
    'D',
    'S',
    'T',
    'Q',
    'Q',
    'S',
    'S',
  ];

  @override
  int get firstDayOfWeekIndex => 0;

  @override
  String get cancelButtonLabel => 'Cancelar';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get saveButtonLabel => 'Salvar';

  @override
  String get datePickerHelpText => 'Selecionar data';

  @override
  String get dateHelpText => 'dd/mm/aaaa';

  @override
  String get dateInputLabel => 'Informe a data';

  @override
  String get invalidDateFormatLabel => 'Formato inválido. Use dd/mm/aaaa.';

  @override
  String get dateOutOfRangeLabel => 'Data fora do intervalo permitido.';

  @override
  String formatCompactDate(DateTime date) => formatAppDate(date);

  @override
  DateTime? parseCompactDate(String? inputString) {
    if (inputString == null) return null;
    final parts = inputString.trim().split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  @override
  String formatMonthYear(DateTime date) =>
      '${_months[date.month - 1]} de ${date.year}';

  @override
  String formatMediumDate(DateTime date) =>
      '${_shortWeekdays[date.weekday - 1]}, ${date.day} de ${_shortMonths[date.month - 1]}';

  @override
  String formatFullDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]}, ${date.day} de ${_months[date.month - 1].toLowerCase()} de ${date.year}';
}

class _PtBrMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _PtBrMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(
        const PtBrMaterialLocalizations(),
      );

  @override
  bool shouldReload(_PtBrMaterialLocalizationsDelegate old) => false;
}

/// Exibe o seletor de data localizado em português (DD/MM/AAAA) com identidade HorseLife.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String title = 'Selecionar data',
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: title,
    cancelText: 'Cancelar',
    confirmText: 'OK',
    fieldLabelText: title,
    fieldHintText: 'dd/mm/aaaa',
    errorFormatText: 'Formato inválido. Use dd/mm/aaaa.',
    errorInvalidText: 'Data fora do intervalo permitido.',
    builder: (context, child) {
      return Localizations.override(
        context: context,
        delegates: const [_PtBrMaterialLocalizationsDelegate()],
        child: Theme(
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
              todayBorder: const BorderSide(
                color: AppColors.seaGreen,
                width: 1.5,
              ),
              dayBackgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.seaGreen
                    : null,
              ),
              dayForegroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled)
                    ? AppColors.grey
                    : states.contains(WidgetState.selected)
                    ? Colors.white
                    : AppColors.prussianBlue,
              ),
              yearBackgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.seaGreen
                    : null,
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
    },
  );
}

/// Campo de formulário reutilizável que exibe data DD/MM/AAAA e abre o DatePicker.
class AppDatePickerField extends StatelessWidget {
  const AppDatePickerField({
    required this.value,
    this.hintText = 'DD/MM/AAAA',
    this.labelText,
    this.onTap,
    this.onDateSelected,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.helpText = 'Selecionar data',
    this.enabled = true,
    super.key,
  });

  final DateTime? value;
  final String hintText;
  final String? labelText;
  final VoidCallback? onTap;
  final ValueChanged<DateTime>? onDateSelected;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String helpText;
  final bool enabled;

  Future<void> _handleTap(BuildContext context) async {
    if (!enabled) return;
    if (onTap != null) {
      onTap!();
      return;
    }
    final onDateSelected = this.onDateSelected;
    if (onDateSelected == null) return;

    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context: context,
      initialDate: value ?? initialDate ?? now,
      firstDate: firstDate ?? DateTime(now.year - 100),
      lastDate: lastDate ?? DateTime(now.year + 20),
      title: helpText,
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayStyle = value == null
        ? theme.textTheme.headlineSmall?.copyWith(color: AppColors.grey)
        : theme.textTheme.headlineSmall;

    return InkWell(
      onTap: enabled ? () => _handleTap(context) : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          contentPadding: const EdgeInsets.only(top: 14, bottom: 12),
          suffixIcon: const Icon(
            Symbols.event,
            color: AppColors.seaGreen,
            size: 28,
          ),
        ),
        child: Text(
          value == null
              ? hintText
              : formatAppDate(value, placeholder: hintText),
          style: displayStyle,
        ),
      ),
    );
  }
}
