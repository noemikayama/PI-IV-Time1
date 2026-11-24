// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Validação do limite de até 500 caracteres por orientação.
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adoção do componente compartilhado AppMultilineTextFormField
// proveniente de core/widgets.
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do modal para adição de uma orientação de execução do
// exercício, reutilizando AppModalFrame e AppModalSaveButton de core/widgets.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_multiline_text_form_field.dart';
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
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Preencha este campo.';
    }
    if (trimmed.length > 500) {
      return 'A orientação deve ter no máximo 500 caracteres.';
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
    // final theme = Theme.of(context);

    return AppModalFrame(
      title: 'Adicionar\norientação',
      onClose: () => Navigator.of(context).pop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppMultilineTextFormField(
              fieldKey: const Key('exercise-guideline-input'),
              controller: _guidelineController,
              hintText: 'Orientação',
              autofocus: true,
              minLines: 4,
              maxLines: 6,
              validator: _validateGuideline,
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
