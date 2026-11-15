// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de conteúdo, validação e ações da base
// visual compartilhada pelos formulários do perfil.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da estrutura compartilhada dos modais de inclusão de
// informações do perfil do cavalo, conforme o protótipo.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Estrutura visual compartilhada pelos formulários de inclusão do perfil.
///
/// O conteúdo e sua validação permanecem com cada formulário, enquanto este
/// widget concentra dimensões, fechamento e ação de salvar.
class HorseProfileEntryDialog extends StatelessWidget {
  const HorseProfileEntryDialog({
    required this.title,
    required this.content,
    required this.onSave,
    this.saveEnabled = true,
    super.key,
  });

  final String title;
  final Widget content;
  final VoidCallback onSave;
  final bool saveEnabled;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: media.size.height - media.viewInsets.bottom - 40,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 30, 40, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 42),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.08,
                            fontSize: 24,
                          ),
                    ),
                  ),
                  Positioned(
                    right: -12,
                    top: -12,
                    child: IconButton(
                      key: const Key('horse-entry-dialog-close-button'),
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 38),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              content,
              const SizedBox(height: 34),
              OutlinedButton(
                key: const Key('horse-entry-dialog-save-button'),
                onPressed: saveEnabled ? onSave : null,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  foregroundColor: AppColors.seaGreen,
                  disabledForegroundColor: AppColors.grey,
                  side: BorderSide(
                    color: saveEnabled
                        ? AppColors.seaGreen
                        : AppColors.alabasterGray,
                    width: 2,
                  ),
                  shape: const StadiumBorder(),
                  textStyle: Theme.of(context).textTheme.titleLarge,
                ),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Decoração uniforme dos campos grandes exibidos dentro dos modais.
InputDecoration horseEntryInputDecoration({String? hintText}) =>
    InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: AppColors.alabasterGray,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.seaGreen, width: 2),
      ),
      contentPadding: const EdgeInsets.all(20),
    );
