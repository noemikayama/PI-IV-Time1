// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Campo de microchip isolado, preservando teste com letras.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

class HorseMicrochipStep extends StatelessWidget {
  const HorseMicrochipStep({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    key: const ValueKey('horse-microchip'),
    maxLength: 15,
    keyboardType: TextInputType.number,
    decoration: const InputDecoration(
      labelText: 'Código',
      helperText: '15 dígitos numéricos, sem letras ou espaços.',
    ),
    // Não bloqueia letras: o usuário consegue testar a mensagem de erro.
    onChanged: onChanged,
    validator: (value) => !RegExp(r'^\d{15}$').hasMatch(value ?? '')
        ? 'O microchip deve conter exatamente 15 números.'
        : null,
  );
}
