// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de estado, seleção da data, validação e
// retorno dos dados do formulário de lesão.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adequação estética do diálogo de lesão à prototipação: card branco
// arredondado, botão de fechar em cruz, seletor de data arredondado integrado
// ao showAppDatePicker localizado, caixas de texto cinzas e botão Salvar em cápsula.
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
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';
import 'package:material_symbols_icons/symbols.dart';
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

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = widget.birthDate ?? DateTime(now.year - 50);
    final picked = await showAppDatePicker(
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 32),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Adicionar lesão',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('close-horse-injury-dialog'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 28,
                      color: AppColors.text,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Data da lesão',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                key: const Key('horse-injury-date-picker-button'),
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9E9E9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _injuryDate == null
                              ? 'DD/MM/AAAA'
                              : formatAppDate(_injuryDate),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 18,
                            color: _injuryDate == null
                                ? AppColors.grey
                                : AppColors.text,
                          ),
                        ),
                      ),
                      const Icon(
                        Symbols.event,
                        color: AppColors.text,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Detalhes da lesão',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E9E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  key: const Key('horse-injury-description'),
                  controller: _description,
                  minLines: 3,
                  maxLines: 4,
                  maxLength: 500,
                  cursorColor: AppColors.seaGreen,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 18,
                    color: AppColors.text,
                    height: 1.25,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Prescrição veterinária',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E9E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: TextField(
                  key: const Key('horse-injury-prescription'),
                  controller: _prescription,
                  minLines: 3,
                  maxLines: 4,
                  maxLength: 500,
                  cursorColor: AppColors.seaGreen,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 18,
                    color: AppColors.text,
                    height: 1.25,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              OutlinedButton(
                key: const Key('save-horse-injury'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: AppColors.seaGreen, width: 2),
                  shape: const StadiumBorder(),
                ),
                onPressed: _save,
                child: Text(
                  'Salvar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.seaGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
