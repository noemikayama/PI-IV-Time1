// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão de chaves explícitas na liberação da validação assíncrona
// do microchip, preservando a verificação de montagem da tela.
//
// Data: 18/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Restauração da injeção opcional do seletor de imagens para
// compatibilidade com os testes, mantendo o serviço real como padrão.
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Revisão da documentação dos blocos de estado, navegação entre
// etapas, seleção de imagens e submissão do cadastro.
//
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Transição do fluxo de cadastro de cavalos para telas modulares
// autônomas, reexportando HorseRelationshipScreen como ponto de entrada do fluxo
// com compatibilidade retroativa para todos os testes e rotas existentes.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../application/controllers/horse_registration_controller.dart';
import '../../application/controllers/horse_registration_step_validator.dart';
import '../../application/states/horse_registration_step.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../data/repositories/horse_registration_repository.dart';
import '../../horse_registration_composition.dart';
import '../services/horse_image_selection_service.dart';
import '../steps/horse_birth_date_step.dart';
import '../steps/horse_catalog_step.dart';
import '../steps/horse_images_step.dart';
import '../steps/horse_injuries_step.dart';
import '../steps/horse_microchip_step.dart';
import '../steps/horse_modality_step.dart';
import '../steps/horse_name_step.dart';
import '../steps/horse_notes_step.dart';
import '../steps/horse_relationship_step.dart';
import '../steps/horse_review_step.dart';
import '../steps/horse_sex_step.dart';
import '../widgets/horse_injury_dialog.dart';
import '../widgets/horse_registration_alert.dart';
import '../widgets/horse_registration_calendar.dart';
import '../widgets/horse_registration_layout.dart';
import '../widgets/horse_text_entry_dialog.dart';

/// Mantém as informações entre etapas. A Home recebe o resultado por Navigator.
class HorseRegistrationScreen extends StatefulWidget {
  const HorseRegistrationScreen({
    this.repository,
    this.microchipValidator,
    this.imageSelection = const HorseImageSelectionService(),
    super.key,
  });

  final HorseRegistrationRepository? repository;

  /// Somente o microchip poderá consultar a API Java no futuro.
  final HorseMicrochipValidator? microchipValidator;

  /// Permite isolar a seleção de fotografias nos testes sem alterar a produção.
  final HorseImageSelectionService imageSelection;

  @override
  State<HorseRegistrationScreen> createState() =>
      _HorseRegistrationScreenState();
}

class _HorseRegistrationScreenState extends State<HorseRegistrationScreen> {
  final _draft = HorseRegistrationDraft();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _chipController = TextEditingController();

  HorseRegistrationStep _step = HorseRegistrationStep.relationship;
  bool _saving = false;
  bool _validatingMicrochip = false;
  bool _advancing = false;
  bool _completed = false;
  late final HorseRegistrationRepository _repository;
  late final HorseRegistrationController _controller;
  late final HorseRegistrationStepValidator _stepValidator;
  Future<List<HorseModality>>? _modalitiesFuture;

  bool get _busy => _saving || _validatingMicrochip || _advancing;

  @override
  void initState() {
    super.initState();
    // Um único repositório e validador são usados durante todo o cadastro.
    _repository =
        widget.repository ??
        HorseRegistrationComposition.productionRepository();
    final validator =
        widget.microchipValidator ??
        HorseRegistrationComposition.productionMicrochipValidator();
    _controller = HorseRegistrationController(
      repository: _repository,
      microchipValidator: validator,
    );
    _stepValidator = HorseRegistrationStepValidator(validator);
    // Modalidades só são carregadas ao alcançar essa etapa.
  }

  @override
  void dispose() {
    _nameController.dispose();
    _chipController.dispose();
    super.dispose();
  }

  Future<void> _notice(String title, String message) async {
    if (!mounted) return;
    await showHorseRegistrationNotice(context, title: title, message: message);
  }

  Future<void> _back() async {
    if (_busy) return;
    if (_step != HorseRegistrationStep.relationship) {
      setState(() => _step = _step.previous);
    } else if (await confirmHorseRegistrationExit(context) && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _next() async {
    // Evita que dois toques rápidos pulem uma etapa antes da validação.
    if (_busy || _advancing) return;
    _advancing = true;
    try {
      if (_step.isLast) {
        await _submit();
        return;
      }
      if ((_step == HorseRegistrationStep.name ||
              _step == HorseRegistrationStep.microchip) &&
          !(_formKey.currentState?.validate() ?? false)) {
        if (_step == HorseRegistrationStep.microchip) {
          await _notice(
            'Código inválido',
            'O microchip deve conter exatamente 15 números, sem letras ou espaços.',
          );
        }
        return;
      }

      final checkingChip = _step == HorseRegistrationStep.microchip;
      if (checkingChip) setState(() => _validatingMicrochip = true);
      HorseStepWarning? warning;
      try {
        warning = await _stepValidator.validate(_step, _draft);
      } finally {
        if (mounted && checkingChip) {
          setState(() => _validatingMicrochip = false);
        }
      }
      if (!mounted) return;
      if (warning != null) {
        await _notice(warning.title, warning.message);
        return;
      }
      setState(() => _step = _step.next);
    } finally {
      _advancing = false;
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final result = await _controller.register(_draft);
      if (!mounted) return;
      // Libera o PopScope antes de voltar, inclusive no Android.
      setState(() => _completed = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.of(context).pop(result);
    } on HorseRegistrationFailure catch (error) {
      await _notice('Cadastro não realizado', error.message);
    } catch (_) {
      await _notice(
        'Falha no cadastro',
        'Não foi possível concluir o cadastro. Verifique sua conexão e tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final min = DateTime(now.year - 50, now.month, now.day);
    final date = await showHorseRegistrationCalendar(
      context: context,
      initialDate: _draft.birthDate ?? now,
      firstDate: min,
      lastDate: now,
      title: 'Data de nascimento',
    );
    if (!mounted || date == null) return;
    setState(() {
      _draft.birthDate = date;
      // Lesões não podem ser anteriores ao nascimento selecionado.
      _draft.injuries.removeWhere((injury) => injury.date.isBefore(date));
    });
  }

  Future<void> _selectImages() async {
    try {
      final selected = await widget.imageSelection.select(
        currentCount: _draft.images.length,
      );
      if (!mounted) return;
      if (selected.access != HorseImageLibraryAccess.granted) {
        await _notice(
          'Acesso à galeria necessário',
          selected.access == HorseImageLibraryAccess.permanentlyDenied
              ? 'Ative a permissão para fotos nas configurações do aparelho.'
              : 'Permita o acesso à galeria para adicionar imagens.',
        );
        return;
      }
      setState(() => _draft.images.addAll(selected.accepted));
      if (selected.rejected > 0) {
        await _notice(
          'Algumas imagens foram ignoradas',
          'São permitidas até 10 imagens JPG ou PNG, com no máximo 5 MB por arquivo.',
        );
      }
    } catch (_) {
      await _notice(
        'Não foi possível abrir os arquivos',
        'Tente novamente ou avance sem imagens.',
      );
    }
  }

  Future<void> _addTextItem(String title, List<String> list) async {
    final value = await showHorseTextEntryDialog(context, title: title);
    if (!mounted || value == null || value.isEmpty) return;
    if (list.length >= 30) {
      await _notice(
        'Limite atingido',
        'São permitidos até 30 registros nesta seção.',
      );
    } else {
      setState(() => list.add(value));
    }
  }

  Future<void> _addInjury() async {
    final injury = await showHorseInjuryDialog(
      context: context,
      birthDate: _draft.birthDate,
    );
    if (!mounted || injury == null) return;
    if (_draft.injuries.length >= 50) {
      await _notice('Limite atingido', 'São permitidas até 50 lesões.');
    } else {
      setState(() => _draft.injuries.add(injury));
    }
  }

  void _edit(HorseRegistrationStep step) => setState(() => _step = step);

  // Cada etapa tem seu próprio arquivo, semelhante ao cadastro de usuário.
  Widget _currentStep() => switch (_step) {
    HorseRegistrationStep.relationship => HorseRelationshipStep(
      value: _draft.relationship,
      onChanged: (value) => setState(() => _draft.relationship = value),
    ),
    HorseRegistrationStep.name => HorseNameStep(
      controller: _nameController,
      onChanged: (value) => _draft.name = value,
    ),
    HorseRegistrationStep.microchip => HorseMicrochipStep(
      controller: _chipController,
      onChanged: (value) => _draft.microchip = value,
    ),
    HorseRegistrationStep.birthDate => HorseBirthDateStep(
      value: _draft.birthDate,
      onSelect: _pickBirthDate,
    ),
    HorseRegistrationStep.breed => HorseCatalogStep(
      kind: HorseCatalogKind.breed,
      value: _draft.breed,
      onSelected: (value) => setState(() => _draft.breed = value),
    ),
    HorseRegistrationStep.coat => HorseCatalogStep(
      kind: HorseCatalogKind.coat,
      value: _draft.coat,
      onSelected: (value) => setState(() => _draft.coat = value),
    ),
    HorseRegistrationStep.sex => HorseSexStep(
      value: _draft.sex,
      onChanged: (value) => setState(() => _draft.sex = value),
    ),
    HorseRegistrationStep.images => HorseImagesStep(
      images: _draft.images,
      onAdd: _selectImages,
      onRemove: (file) => setState(() => _draft.images.remove(file)),
    ),
    HorseRegistrationStep.modality => HorseModalityStep(
      modalities: _modalitiesFuture ??= _repository.getModalities(),
      value: _draft.modality,
      onChanged: (value) => setState(() => _draft.modality = value),
      onRetry: () =>
          setState(() => _modalitiesFuture = _repository.getModalities()),
    ),
    HorseRegistrationStep.limitations => HorseNotesStep(
      type: HorseNotesType.limitations,
      items: _draft.physicalLimitations,
      onAdd: () =>
          _addTextItem('Adicionar limitação', _draft.physicalLimitations),
      onRemove: (item) =>
          setState(() => _draft.physicalLimitations.remove(item)),
    ),
    HorseRegistrationStep.health => HorseNotesStep(
      type: HorseNotesType.health,
      items: _draft.healthNotes,
      onAdd: () => _addTextItem('Adicionar observação', _draft.healthNotes),
      onRemove: (item) => setState(() => _draft.healthNotes.remove(item)),
    ),
    HorseRegistrationStep.injuries => HorseInjuriesStep(
      injuries: _draft.injuries,
      onAdd: _addInjury,
      onRemove: (item) => setState(() => _draft.injuries.remove(item)),
    ),
    HorseRegistrationStep.review => HorseReviewStep(
      draft: _draft,
      onEdit: _edit,
      onRemoveImage: (file) => setState(() => _draft.images.remove(file)),
      onRemoveLimitation: (item) =>
          setState(() => _draft.physicalLimitations.remove(item)),
      onRemoveHealth: (item) => setState(() => _draft.healthNotes.remove(item)),
      onRemoveInjury: (item) => setState(() => _draft.injuries.remove(item)),
    ),
  };

  @override
  Widget build(BuildContext context) => PopScope(
    canPop:
        _completed || (_step == HorseRegistrationStep.relationship && !_busy),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && !_completed) _back();
    },
    child: HorseRegistrationLayout(
      step: _step,
      formKey: _formKey,
      content: _currentStep(),
      onBack: _back,
      onNext: _next,
      busy: _busy,
    ),
  );
}
