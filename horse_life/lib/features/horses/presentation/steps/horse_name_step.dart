// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Campo de nome e sua validação visual extraídos do fluxo.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class HorseNameStep extends StatelessWidget {
  const HorseNameStep({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    textCapitalization: TextCapitalization.words,
    maxLength: 80,
    decoration: const InputDecoration(labelText: 'Nome'),
    onChanged: onChanged,
    validator: (value) => (value?.trim().length ?? 0) < 2
        ? 'Informe ao menos 2 caracteres.'
        : null,
  );
}
