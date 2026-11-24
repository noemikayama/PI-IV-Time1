// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Suporte à exibição opcional do seletor de cavalo para reuso
// do filtro em painéis exclusivos de período (como o painel profissional).
//
// Data: 29/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Modularização do Dashboard Guardian e preparação para dados da Cloud Function.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários pontuais sobre a responsabilidade do arquivo.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Seletores independentes; a Screen controla o estado e a futura requisição.
class DashboardFilters extends StatelessWidget {
  const DashboardFilters({
    super.key,
    this.horse = 'Todos',
    required this.period,
    this.horses = const ['Todos'],
    required this.periods,
    this.onHorseChanged,
    required this.onPeriodChanged,
    this.showHorse = true,
  });
  final String horse, period;
  final List<String> horses, periods;
  final ValueChanged<String>? onHorseChanged;
  final ValueChanged<String> onPeriodChanged;
  final bool showHorse;

  void _show(BuildContext context, {required bool selectHorse}) {
    final options = selectHorse ? horses : periods;
    final selected = selectHorse ? horse : period;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.whiteSmoke,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Icon(
                    selectHorse
                        ? Icons.filter_alt_outlined
                        : Icons.hourglass_empty,
                    size: 27,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectHorse ? 'Selecionar cavalo' : 'Selecionar período',
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: options
                      .map(
                        (option) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: option == selected
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.seaGreen,
                                )
                              : const SizedBox(width: 24),
                          title: Text(
                            option,
                            style: TextStyle(
                              fontSize: 19,
                              color: option == selected
                                  ? AppColors.seaGreen
                                  : AppColors.text,
                            ),
                          ),
                          onTap: () {
                            if (selectHorse) {
                              onHorseChanged?.call(option);
                            } else {
                              onPeriodChanged(option);
                            }
                            Navigator.pop(sheetContext);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback tap,
  ) => Material(
    color: AppColors.alabasterGray,
    borderRadius: BorderRadius.circular(32),
    child: InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 9,
    children: [
      if (showHorse)
        _chip(
          context,
          Icons.filter_alt_outlined,
          horse,
          () => _show(context, selectHorse: true),
        ),
      _chip(
        context,
        Icons.hourglass_empty,
        period,
        () => _show(context, selectHorse: false),
      ),
    ],
  );
}
