// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Delegação da validação assíncrona do microchip ao HorseRegistrationController,
// desacoplando a infraestrutura do repositório da tela e repassando o estado.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela autônoma de validação e coleta do microchip do cavalo
// (etapa 2 de 12), integrando FormProgressIndicator, AuthHeader e botão Seguinte
// com prevenção de travamento em loading na exibição do modal de aviso.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horse_life/core/widgets/app_text_form_field.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../application/controllers/horse_registration_controller.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../data/repositories/horse_registration_repository.dart';
import '../../horse_registration_composition.dart';
import '../services/horse_image_selection_service.dart';
import '../widgets/horse_registration_alert.dart';
import 'horse_birth_date_screen.dart';

typedef HorseMicrochipCallback = void Function(HorseRegistrationDraft draft);

/// Etapa 2 de 12: Coleta e validação do microchip de 15 dígitos do animal.
class HorseMicrochipScreen extends StatefulWidget {
  const HorseMicrochipScreen({
    required this.draft,
    this.controller,
    this.repository,
    this.microchipValidator,
    this.imageSelection = const HorseImageSelectionService(),
    this.onContinue,
    this.onBack,
    super.key,
  });

  final HorseRegistrationDraft draft;
  final HorseRegistrationController? controller;
  final HorseRegistrationRepository? repository;
  final HorseMicrochipValidator? microchipValidator;
  final HorseImageSelectionService imageSelection;
  final HorseMicrochipCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<HorseMicrochipScreen> createState() => _HorseMicrochipScreenState();
}

class _HorseMicrochipScreenState extends State<HorseMicrochipScreen> {
  late final TextEditingController _chipController;
  late final HorseRegistrationController _controller;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _chipController = TextEditingController(text: widget.draft.microchip);
    _controller =
        widget.controller ??
        HorseRegistrationComposition.productionController(
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          initialDraft: widget.draft,
        );
  }

  @override
  void dispose() {
    _chipController.dispose();
    super.dispose();
  }

  void _goBack() {
    if (_isValidating) return;
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  Future<void> _continue() async {
    if (_isValidating) return;
    FocusScope.of(context).unfocus();

    final chip = _chipController.text.trim();
    if (!RegExp(r'^\d{15}$').hasMatch(chip)) {
      await showHorseRegistrationNotice(
        context,
        title: 'Código inválido',
        message:
            'O número do microchip informado é inválido. Verifique se houve um '
            'erro de digitação e tente novamente.',
      );
      return;
    }

    setState(() => _isValidating = true);
    try {
      await _controller.validateMicrochip(chip);
    } on HorseMicrochipValidationFailure catch (error) {
      if (!mounted) return;
      setState(() => _isValidating = false);
      await showHorseRegistrationNotice(
        context,
        title: 'Código inválido',
        message: error.message,
      );
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _isValidating = false);
      await showHorseRegistrationNotice(
        context,
        title: 'Erro na validação',
        message: 'Não foi possível validar o microchip. Tente novamente.',
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isValidating = false);

    widget.draft.microchip = chip;

    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(widget.draft);
      return;
    }

    final result = await Navigator.push<HorseRegistrationResult>(
      context,
      MaterialPageRoute<HorseRegistrationResult>(
        builder: (context) => HorseBirthDateScreen(
          draft: widget.draft,
          controller: _controller,
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          imageSelection: widget.imageSelection,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 18, 32, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(onBack: _isValidating ? () {} : _goBack),
                    const SizedBox(height: 44),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const FormProgressIndicator(
                              configuration:
                                  FormProgressConfiguration.horseRegistration,
                              currentStep: 2,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Microchip do cavalo',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Informe os 15 números gravados no\n'
                              'microchip do animal.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            AppTextFormField(
                              key: const ValueKey('horse-microchip'),
                              controller: _chipController,
                              hintText: 'Código',
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(15),
                              ],
                              onChanged: (value) => widget.draft.microchip = value,
                              onFieldSubmitted: (_) => _continue(),
                            ),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-horse-registration',
                              ),
                              isLoading: _isValidating,
                              onPressed: _isValidating ? null : _continue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
