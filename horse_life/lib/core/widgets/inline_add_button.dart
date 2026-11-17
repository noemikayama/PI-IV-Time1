// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do contrato e do objetivo visual da ação textual
// reutilizável de inclusão.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Extração da ação textual de adicionar para reutilização nos
// perfis e formulários da aplicação.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Ação compacta usada dentro de seções para iniciar a inclusão de um item sem
/// competir visualmente com o botão principal da tela.
class InlineAddButton extends StatelessWidget {
  const InlineAddButton({
    required this.onPressed,
    this.label = '+ Adicionar',
    super.key,
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: AppColors.seaGreen,
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      alignment: Alignment.centerLeft,
    ),
    child: Text(
      label,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w300),
    ),
  );
}
