// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Formulário de lesões isolado para evitar que campos grandes
// aumentem o diálogo ou saiam da tela em dispositivos pequenos.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

import '../../data/models/horse_registration_draft.dart';
import 'horse_registration_calendar.dart';

/// Abre o formulário de lesão e retorna os dados somente quando são salvos.
Future<HorseInjury?> showHorseInjuryDialog({
  required BuildContext context,
  DateTime? birthDate,
}) => showDialog<HorseInjury>(
  context: context,
  builder: (_) => HorseInjuryDialog(birthDate: birthDate),
);

/// Os campos ficam com duas linhas de altura. Textos maiores rolam por dentro
/// deles, enquanto o próprio diálogo rola se o teclado ocupar muito espaço.
class HorseInjuryDialog extends StatefulWidget {
  const HorseInjuryDialog({super.key, this.birthDate});

  final DateTime? birthDate;

  @override
  State<HorseInjuryDialog> createState() => _HorseInjuryDialogState();
}

class _HorseInjuryDialogState extends State<HorseInjuryDialog> {
  final _description = TextEditingController();
  final _prescription = TextEditingController();
  DateTime? _injuryDate;

  @override
  void dispose() {
    _description.dispose();
    _prescription.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = widget.birthDate ?? DateTime(now.year - 50);
    final picked = await showHorseRegistrationCalendar(
      context: context,
      initialDate: _injuryDate ?? now,
      firstDate: firstDate,
      lastDate: now,
      title: 'Data da lesão',
    );
    if (!mounted || picked == null) return;
    setState(() => _injuryDate = picked);
  }

  void _save() {
    final description = _description.text.trim();
    if (_injuryDate == null || description.isEmpty) return;
    Navigator.of(context).pop(
      HorseInjury(
        date: _injuryDate!,
        description: description,
        prescription: _prescription.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.whiteSmoke,
    // Limita a largura em tablets e mantém margens em celulares pequenos.
    constraints: const BoxConstraints(maxWidth: 440),
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    // A área interna rola quando aparece o teclado ou a tela é baixa.
    scrollable: true,
    title: const Text('Adicionar lesão'),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                _injuryDate == null
                    ? 'Selecionar data da lesão'
                    : _formatDate(_injuryDate!),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('horse-injury-description'),
            controller: _description,
            maxLength: 500,
            // Textos longos quebram linha e rolam sem aumentar o campo.
            minLines: 2,
            maxLines: 2,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            scrollPhysics: const ClampingScrollPhysics(),
            decoration: const InputDecoration(labelText: 'Descrição da lesão'),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const ValueKey('horse-injury-prescription'),
            controller: _prescription,
            maxLength: 500,
            minLines: 2,
            maxLines: 2,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            scrollPhysics: const ClampingScrollPhysics(),
            decoration: const InputDecoration(
              labelText: 'Prescrição médica (opcional)',
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      OutlinedButton(onPressed: _save, child: const Text('Salvar')),
    ],
  );
}
