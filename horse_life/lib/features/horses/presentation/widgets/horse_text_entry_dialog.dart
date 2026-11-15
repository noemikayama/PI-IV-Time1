// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de entrada, validação e devolução de
// valores textuais usados no perfil do cavalo.
//
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Adequação visual ao protótipo e reutilização da estrutura comum
// dos modais de inclusão do perfil do cavalo.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Diálogo de texto reutilizável com controlador próprio.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import 'horse_profile_entry_dialog.dart';

Future<String?> showHorseTextEntryDialog(
  BuildContext context, {
  required String title,
}) => showDialog<String>(
  context: context,
  builder: (_) => HorseTextEntryDialog(title: title),
);

class HorseTextEntryDialog extends StatefulWidget {
  const HorseTextEntryDialog({required this.title, super.key});

  final String title;

  @override
  State<HorseTextEntryDialog> createState() => _HorseTextEntryDialogState();
}

class _HorseTextEntryDialogState extends State<HorseTextEntryDialog> {
  final _controller = TextEditingController();
  bool _canSave = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HorseProfileEntryDialog(
    key: const Key('horse-text-entry-dialog'),
    title: widget.title,
    saveEnabled: _canSave,
    onSave: () => Navigator.pop(context, _controller.text.trim()),
    content: SizedBox(
      height: 132,
      child: TextField(
        key: const Key('horse-text-entry-field'),
        controller: _controller,
        autofocus: true,
        minLines: null,
        maxLines: null,
        expands: true,
        maxLength: 500,
        textAlignVertical: TextAlignVertical.top,
        onChanged: (value) =>
            setState(() => _canSave = value.trim().isNotEmpty),
        decoration: horseEntryInputDecoration(hintText: 'Descreva aqui'),
      ),
    ),
  );
}
