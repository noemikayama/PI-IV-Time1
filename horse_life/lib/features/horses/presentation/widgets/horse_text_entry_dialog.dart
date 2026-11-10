// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Diálogo de texto reutilizável com controlador próprio.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    constraints: const BoxConstraints(maxWidth: 440),
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      minLines: 2,
      maxLines: 3,
      maxLength: 500,
      decoration: const InputDecoration(hintText: 'Descreva aqui'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      OutlinedButton(
        onPressed: () => Navigator.pop(context, _controller.text.trim()),
        child: const Text('Salvar'),
      ),
    ],
  );
}
