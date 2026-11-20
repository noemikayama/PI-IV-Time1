// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Separação da composição das etapas de digitação e revisão,
// reutilizando campos compartilhados e permitindo edição sem perder os dados.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_multiline_text_form_field.dart';
import 'package:horse_life/core/widgets/editable_review_field.dart';
import 'package:horse_life/features/feedback/application/controllers/feedback_registration_controller.dart';

/// Etapa de preenchimento. O Form fica na tela para validar só o campo atual.
class FeedbackInputSection extends StatelessWidget {
  const FeedbackInputSection({
    required this.formKey,
    required this.controller,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final FeedbackRegistrationController controller;

  @override
  Widget build(BuildContext context) {
    final definition = controller.currentDefinition;
    final step = controller.step;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          definition.title,
          textAlign: TextAlign.center,
          style: textTheme.displayMedium?.copyWith(fontSize: 36, height: 1.07),
        ),
        const SizedBox(height: 24),
        Text(
          definition.description,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(fontSize: 22, height: 1.18),
        ),
        const SizedBox(height: 38),
        Form(
          key: formKey,
          child: AppMultilineTextFormField(
            fieldKey: Key('feedback-input-${step + 1}'),
            controller: controller.textControllers[step],
            focusNode: controller.focusNodes[step],
            hintText: definition.hint,
            minLines: 6,
            maxLines: 8,
            validator: (value) => controller.validate(step, value),
          ),
        ),
      ],
    );
  }
}

/// Resumo de todas as respostas, com edição direcionada à respectiva etapa.
class FeedbackReviewSection extends StatelessWidget {
  const FeedbackReviewSection({
    required this.controller,
    required this.onEdit,
    super.key,
  });

  final FeedbackRegistrationController controller;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Revise os dados',
          textAlign: TextAlign.center,
          style: textTheme.displayMedium?.copyWith(fontSize: 36),
        ),
        const SizedBox(height: 28),
        Text(
          'Confira se todas as informações estão corretas antes de continuar.',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(fontSize: 22, height: 1.2),
        ),
        const SizedBox(height: 34),
        for (var index = 0; index < FeedbackRegistrationController.definitions.length; index++) ...[
          EditableReviewField(
            fieldKey: Key('feedback-review-${index + 1}'),
            label: FeedbackRegistrationController.definitions[index].title
                .replaceAll('\n', ' '),
            controller: controller.textControllers[index],
            focusNode: controller.focusNodes[index],
            isEditing: false,
            externalEdit: true,
            onToggleEditing: () => onEdit(index),
            validator: (_) => null,
            minLines: 2,
            maxLines: null,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}
