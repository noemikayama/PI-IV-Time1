// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de estado, seleção da data, validação e
// retorno dos dados do formulário de lesão.
//
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Adequação do formulário de lesão ao modal compartilhado do
// perfil, com campos e calendário conforme o protótipo.
//
// Data: 09/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Ícone do calendário substituído pelo Material Symbols event.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Formulário de lesões isolado para evitar que campos grandes
// aumentem o diálogo ou saiam da tela em dispositivos pequenos.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/models/horse_registration_draft.dart';
import 'horse_profile_entry_dialog.dart';
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

  bool get _canSave =>
      _injuryDate != null && _description.text.trim().isNotEmpty;

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
  Widget build(BuildContext context) => HorseProfileEntryDialog(
    key: const Key('horse-injury-entry-dialog'),
    title: 'Adicionar lesão',
    saveEnabled: _canSave,
    onSave: _save,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel('Data da lesão'),
        InkWell(
          key: const Key('horse-injury-date-field'),
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: horseEntryInputDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _injuryDate == null
                        ? 'DD/MM/AAAA'
                        : _formatDate(_injuryDate!),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Icon(Symbols.event, size: 32),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Detalhes da lesão'),
        SizedBox(
          height: 124,
          child: TextField(
            key: const Key('horse-injury-description'),
            controller: _description,
            maxLength: 500,
            minLines: null,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            onChanged: (_) => setState(() {}),
            decoration: horseEntryInputDecoration(hintText: 'Descreva a lesão'),
          ),
        ),
        const SizedBox(height: 18),
        const _FieldLabel('Prescrição veterinária'),
        SizedBox(
          height: 124,
          child: TextField(
            key: const Key('horse-injury-prescription'),
            controller: _prescription,
            maxLength: 500,
            minLines: null,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            decoration: horseEntryInputDecoration(
              hintText: 'Descreva a prescrição',
            ),
          ),
        ),
      ],
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}
