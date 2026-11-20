// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Extração da navegação, valores e regras do formulário de feedback
// para um controlador independente da composição visual das etapas.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/features/feedback/data/models/training_execution_record.dart';

/// Conteúdo fixo das etapas: evita títulos e instruções duplicados nas telas.
class FeedbackFormStepDefinition {
  const FeedbackFormStepDefinition({
    required this.title,
    required this.description,
    required this.hint,
    this.isRequired = false,
  });

  final String title;
  final String description;
  final String hint;
  final bool isRequired;
}

/// Controla uma única execução do formulário e libera seus recursos ao fechar.
/// Não conhece a tela, o Navigator ou o repositório de persistência.
class FeedbackRegistrationController extends ChangeNotifier {
  static const definitions = <FeedbackFormStepDefinition>[
    FeedbackFormStepDefinition(
      title: 'Comentários sobre a\nexecução',
      description: 'Escreva uma avaliação geral do desempenho observado '
          'na execução dos exercícios.',
      hint: 'Comentários',
      isRequired: true,
    ),
    FeedbackFormStepDefinition(
      title: 'Dificuldades\nidentificadas',
      description: 'Descreva as dificuldades/pontos fracos percebidos '
          'nos relatos da execução.',
      hint: 'Dificuldades',
    ),
    FeedbackFormStepDefinition(
      title: 'Correções e\norientações',
      description: 'Sugira correções e ajustes para que os próximos treinos '
          'tenham um resultado melhor.',
      hint: 'Correções',
    ),
  ];

  final List<TextEditingController> textControllers = List.generate(
    definitions.length,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(
    definitions.length,
    (_) => FocusNode(),
  );

  int _step = 0;
  bool _isSaving = false;

  int get step => _step;
  int get totalSteps => definitions.length + 1;
  bool get isReview => _step == definitions.length;
  bool get isSaving => _isSaving;
  FeedbackFormStepDefinition get currentDefinition => definitions[_step];

  /// Volta uma etapa. Retorna false quando a tela deve ser fechada.
  bool previous() {
    if (_step == 0) return false;
    _step--;
    notifyListeners();
    return true;
  }

  void next() {
    if (isReview) return;
    _step++;
    notifyListeners();
  }

  /// A revisão permite editar qualquer etapa anterior sem perder os textos.
  void edit(int index) {
    if (index < 0 || index >= definitions.length) {
      throw RangeError.index(index, definitions);
    }
    _step = index;
    notifyListeners();
  }

  /// Uma regra única é aplicada tanto no campo quanto na revisão final.
  String? validate(int index, String? value) {
    final text = value?.trim() ?? '';
    if (definitions[index].isRequired && text.isEmpty) {
      return 'Escreva um comentário sobre a execução.';
    }
    if (text.length > 1000) return 'Use no máximo 1000 caracteres.';
    return null;
  }

  String? validateAll() {
    for (var index = 0; index < definitions.length; index++) {
      final error = validate(index, textControllers[index].text);
      if (error != null) return error;
    }
    return null;
  }

  void setSaving(bool value) {
    if (_isSaving == value) return;
    _isSaving = value;
    notifyListeners();
  }

  TrainingExecutionFeedback buildFeedback({DateTime? createdAt}) =>
      TrainingExecutionFeedback(
        createdAt: createdAt ?? DateTime.now(),
        comment: textControllers[0].text.trim(),
        difficulties: _paragraphs(textControllers[1].text),
        guidelines: _paragraphs(textControllers[2].text),
      );

  static List<String> _paragraphs(String text) => text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  @override
  void dispose() {
    for (final controller in textControllers) {
      controller.dispose();
    }
    for (final focus in focusNodes) {
      focus.dispose();
    }
    super.dispose();
  }
}
