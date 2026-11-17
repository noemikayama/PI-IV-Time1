// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de entrada, validação e devolução de
// valores textuais usados no perfil do cavalo.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adaptação visual do diálogo à prototipação: card branco com cantos
// arredondados, botão de fechar em cruz no topo, caixa de texto cinza e botão
// de salvar em cápsula com contorno verde.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Adequação visual ao protótipo e reutilização da estrutura comum
// dos modais de inclusão do perfil do cavalo.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Diálogo de texto reutilizável com controlador próprio.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

import 'horse_profile_entry_dialog.dart';

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
  bool _canSave = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 32),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('close-horse-text-entry'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 28,
                      color: AppColors.text,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE9E9E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  key: const Key('horse-text-entry-input'),
                  controller: _controller,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 5,
                  maxLength: 500,
                  cursorColor: AppColors.seaGreen,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 18,
                    color: AppColors.text,
                    height: 1.25,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              OutlinedButton(
                key: const Key('save-horse-text-entry'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: AppColors.seaGreen, width: 2),
                  shape: const StadiumBorder(),
                ),
                onPressed: _submit,
                child: Text(
                  'Salvar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: AppColors.seaGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
