// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do modal para adição de uma orientação de execução do
// exercício, reutilizando AppModalFrame e AppModalSaveButton de core/widgets.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/service_area_dialogs.dart';

// Abre o diálogo de inserção de orientação e devolve o texto normalizado.
Future<String?> showAddExerciseGuidelineDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AddExerciseGuidelineDialog(),
  );
}

// Modal reutilizável que coleta uma orientação textual para execução do
// exercício antes de adicioná-la à lista da etapa.
class AddExerciseGuidelineDialog extends StatefulWidget {
  const AddExerciseGuidelineDialog({super.key});

  @override
  State<AddExerciseGuidelineDialog> createState() =>
      _AddExerciseGuidelineDialogState();
}

class _AddExerciseGuidelineDialogState
    extends State<AddExerciseGuidelineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _guidelineController = TextEditingController();

  @override
  void dispose() {
    _guidelineController.dispose();
    super.dispose();
  }

  String? _validateGuideline(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Preencha este campo.';
    }
    return null;
  }

  void _save() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_guidelineController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppModalFrame(
      title: 'Adicionar\norientação',
      onClose: () => Navigator.of(context).pop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('exercise-guideline-input'),
              controller: _guidelineController,
              autofocus: true,
              minLines: 4,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              validator: _validateGuideline,
              cursorColor: theme.colorScheme.primary,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 20,
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: 'Orientação',
                hintStyle: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.grey,
                  fontSize: 20,
                ),
                filled: true,
                fillColor: AppColors.alabasterGray,
                contentPadding: const EdgeInsets.all(20),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  borderSide: BorderSide.none,
                ),
                errorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  borderSide: BorderSide(color: AppColors.error, width: 1.5),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  borderSide: BorderSide(color: AppColors.error, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 36),
            AppModalSaveButton(
              buttonKey: const Key('save-exercise-guideline'),
              label: 'Salvar',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
