// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Substituição do campo local pelo componente padronizado
// AppTextFormField proveniente de core/widgets, alinhando ao protótipo.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Campo de microchip isolado, preservando teste com letras.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horse_life/core/widgets/app_text_form_field.dart';

class HorseMicrochipStep extends StatelessWidget {
  const HorseMicrochipStep({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => AppTextFormField(
    key: const ValueKey('horse-microchip'),
    controller: controller,
    hintText: 'Código',
    keyboardType: TextInputType.number,
    textInputAction: TextInputAction.done,
    inputFormatters: [LengthLimitingTextInputFormatter(15)],
    // Não bloqueia letras: o usuário consegue testar a mensagem de erro.
    onChanged: onChanged,
  );
}
