// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Reutilização do diálogo padronizado AppInfoDialog de core/widgets.
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do modal de alerta exibido quando o treinador tenta criar
// um exercício específico sem possuir nenhum animal vinculado ao seu perfil.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_info_dialog.dart';

// Exibe o modal impeditivo quando não há animais vinculados ao treinador.
Future<void> showNoLinkedHorsesDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const NoLinkedHorsesDialog(),
  );
}

// Modal de aviso que orienta o treinador a solicitar o vínculo ao proprietário
// do cavalo antes de prosseguir com a criação de um exercício específico.
class NoLinkedHorsesDialog extends StatelessWidget {
  const NoLinkedHorsesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppInfoDialog(
      dialogKey: Key('no-linked-horses-dialog'),
      confirmButtonKey: Key('confirm-no-linked-horses'),
      title: 'Nenhum animal\nvinculado',
      message:
          'Para poder criar exercícios específicos para um animal, você '
          'precisa estar vinculado a ele. Contate o proprietário do '
          'cavalo para o qual você faria o treino e peça para que ele te '
          'vincule.',
    );
  }
}
