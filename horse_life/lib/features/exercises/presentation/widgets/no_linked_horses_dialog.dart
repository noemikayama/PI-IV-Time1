// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do modal de alerta exibido quando o treinador tenta criar
// um exercício específico sem possuir nenhum animal vinculado ao seu perfil.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../authentication/presentation/widgets/auth_next_button.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      key: const Key('no-linked-horses-dialog'),
      backgroundColor: AppColors.whiteSmoke,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nenhum animal\nvinculado',
                textAlign: TextAlign.center,
                style: textTheme.displaySmall?.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Para poder criar exercícios específicos para um animal, você '
                'precisa estar vinculado a ele. Contate o proprietário do '
                'cavalo para o qual você faria o treino e peça para que ele te '
                'vincule.',
                textAlign: TextAlign.left,
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: 20,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              AuthNextButton(
                buttonKey: const Key('confirm-no-linked-horses'),
                label: 'Ok',
                showArrow: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
