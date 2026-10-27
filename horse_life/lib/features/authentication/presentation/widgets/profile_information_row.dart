// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Extração do bloco informativo da seleção de perfil.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

// Apresenta uma orientação textual acompanhada pelo ícone informativo da marca.
class InformationRow extends StatelessWidget {
  const InformationRow({required this.text, super.key});

  // Conteúdo fornecido pela tela de seleção de perfil.
  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Ícone e texto permanecem alinhados pelo topo em conteúdos multilinha.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.info_outline_rounded,
            color: AppColors.seaGreen,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodySmall?.copyWith(fontSize: 16, height: 1.13),
          ),
        ),
      ],
    );
  }
}
