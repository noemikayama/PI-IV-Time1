// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Validação de limites (descrição até 100 caracteres e quantidade
// entre 1 e 999) conforme contrato do backend.
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação do modal de adição de material necessário para o
// exercício, com campo de nome e controle numérico de quantidade (+ / -),
// reutilizando AppModalFrame e AppModalSaveButton de core/widgets.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/service_area_dialogs.dart';
import '../../application/states/exercise_material.dart';

// Abre o diálogo de inserção de material e devolve o objeto validado.
Future<ExerciseMaterial?> showAddExerciseMaterialDialog(BuildContext context) {
  return showDialog<ExerciseMaterial>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AddExerciseMaterialDialog(),
  );
}

// Modal reutilizável que coleta nome e quantidade necessária de um material
// antes de adicioná-lo à lista da etapa do exercício.
class AddExerciseMaterialDialog extends StatefulWidget {
  const AddExerciseMaterialDialog({super.key});

  @override
  State<AddExerciseMaterialDialog> createState() =>
      _AddExerciseMaterialDialogState();
}

class _AddExerciseMaterialDialogState extends State<AddExerciseMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  int get _currentQuantity =>
      int.tryParse(_quantityController.text.trim()) ?? 1;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Preencha este campo.';
    }
    if (trimmed.length > 100) {
      return 'A descrição deve ter no máximo 100 caracteres.';
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Informe a quantidade.';
    }
    final quantity = int.tryParse(trimmed);
    if (quantity == null || quantity <= 0 || quantity > 999) {
      return 'Informe uma quantidade entre 1 e 999.';
    }
    return null;
  }

  void _decrementQuantity() {
    final nextQuantity = _currentQuantity > 1 ? _currentQuantity - 1 : 1;
    setState(() {
      _quantityController.text = nextQuantity.toString();
    });
  }

  void _incrementQuantity() {
    final nextQuantity = _currentQuantity < 999 ? _currentQuantity + 1 : 999;
    setState(() {
      _quantityController.text = nextQuantity.toString();
    });
  }

  void _save() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final material = ExerciseMaterial(
      name: _nameController.text.trim(),
      quantity: int.parse(_quantityController.text.trim()),
    );
    Navigator.of(context).pop(material);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppModalFrame(
      title: 'Adicionar\nmaterial',
      onClose: () => Navigator.of(context).pop(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nome do material',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('exercise-material-name-input'),
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: _validateName,
              cursorColor: theme.colorScheme.primary,
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20),
              decoration: InputDecoration(
                hintText: 'Nome do material',
                hintStyle: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.grey,
                  fontSize: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFE9E9E9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
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
            const SizedBox(height: 20),
            Text(
              'Quantidade necessária',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('exercise-material-quantity-input'),
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              validator: _validateQuantity,
              onFieldSubmitted: (_) => _save(),
              cursorColor: theme.colorScheme.primary,
              style: theme.textTheme.headlineSmall?.copyWith(fontSize: 20),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFE9E9E9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: const Key('decrement-exercise-material-quantity'),
                      onPressed: _decrementQuantity,
                      tooltip: 'Diminuir quantidade',
                      icon: const Icon(
                        Icons.remove_rounded,
                        color: AppColors.text,
                        size: 28,
                      ),
                    ),
                    IconButton(
                      key: const Key('increment-exercise-material-quantity'),
                      onPressed: _incrementQuantity,
                      tooltip: 'Aumentar quantidade',
                      icon: const Icon(
                        Icons.add_rounded,
                        color: AppColors.text,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
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
              buttonKey: const Key('save-exercise-material'),
              label: 'Salvar',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
