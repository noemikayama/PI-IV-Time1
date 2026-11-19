// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do modal reutilizável para inclusão de orientações do
// treinamento, reutilizando AppModalFrame, AppMultilineTextFormField e
// AppModalSaveButton.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_multiline_text_form_field.dart';
import 'package:horse_life/core/widgets/service_area_dialogs.dart';

/// Abre o modal de inclusão de orientação e retorna o texto informado.
Future<String?> showAddTrainingGuidelineDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AddTrainingGuidelineDialog(),
  );
}

/// Modal que coleta uma orientação textual para a sessão de treinamento.
class AddTrainingGuidelineDialog extends StatefulWidget {
  const AddTrainingGuidelineDialog({super.key});

  @override
  State<AddTrainingGuidelineDialog> createState() =>
      _AddTrainingGuidelineDialogState();
}

class _AddTrainingGuidelineDialogState
    extends State<AddTrainingGuidelineDialog> {
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
    return AppModalFrame(
      title: 'Adicionar\norientação',
      onClose: () => Navigator.of(context).pop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppMultilineTextFormField(
              fieldKey: const Key('training-guideline-input'),
              controller: _guidelineController,
              hintText: 'Orientação',
              autofocus: true,
              minLines: 4,
              maxLines: 6,
              validator: _validateGuideline,
            ),
            const SizedBox(height: 36),
            AppModalSaveButton(
              buttonKey: const Key('save-training-guideline'),
              label: 'Salvar',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
