// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Substituição do campo local pelo componente padronizado
// AppTextFormField proveniente de core/widgets.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Campo de nome e sua validação visual extraídos do fluxo.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horse_life/core/widgets/app_text_form_field.dart';

class HorseNameStep extends StatelessWidget {
  const HorseNameStep({
    required this.controller,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => AppTextFormField(
    controller: controller,
    hintText: 'Nome',
    textCapitalization: TextCapitalization.words,
    textInputAction: TextInputAction.done,
    inputFormatters: [LengthLimitingTextInputFormatter(80)],
    onChanged: onChanged,
    validator: (value) => (value?.trim().length ?? 0) < 2
        ? 'Informe ao menos 2 caracteres.'
        : null,
  );
}
