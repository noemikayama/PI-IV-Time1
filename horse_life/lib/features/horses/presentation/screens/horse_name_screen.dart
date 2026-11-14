// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela autônoma de definição do nome do animal (etapa 1 de 12),
// integrando FormProgressIndicator, AuthHeader e botão Seguinte com validação de campo.
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
import '../services/horse_image_selection_service.dart';
import 'horse_microchip_screen.dart';

typedef HorseNameCallback = void Function(HorseRegistrationDraft draft);

/// Etapa 1 de 12: Coleta e validação do nome do cavalo.
class HorseNameScreen extends StatefulWidget {
  const HorseNameScreen({
    required this.draft,
    this.repository,
    this.microchipValidator,
    this.controller,
    this.imageSelection = const HorseImageSelectionService(),
    this.onContinue,
    this.onBack,
    super.key,
  });

  final HorseRegistrationDraft draft;
  final HorseRegistrationRepository? repository;
  final HorseMicrochipValidator? microchipValidator;
  final HorseRegistrationController? controller;
  final HorseImageSelectionService imageSelection;
  final HorseNameCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<HorseNameScreen> createState() => _HorseNameScreenState();
}

class _HorseNameScreenState extends State<HorseNameScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.draft.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.draft.name = _nameController.text.trim();

    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(widget.draft);
      return;
    }

    final result = await Navigator.push<HorseRegistrationResult>(
      context,
      MaterialPageRoute<HorseRegistrationResult>(
        builder: (context) => HorseMicrochipScreen(
          draft: widget.draft,
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          controller: widget.controller,
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
                    AuthHeader(onBack: _goBack),
                    const SizedBox(height: 44),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const FormProgressIndicator(
                                configuration:
                                    FormProgressConfiguration.horseRegistration,
                                currentStep: 1,
                              ),
                              const SizedBox(height: 52),
                              Text(
                                'Nome do animal',
                                textAlign: TextAlign.center,
                                style: textTheme.displaySmall?.copyWith(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Dê um nome coerente e de fácil\ncompreensão.',
                                textAlign: TextAlign.center,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontSize: 20,
                                  height: 1.18,
                                ),
                              ),
                              const SizedBox(height: 58),
                              AppTextFormField(
                                controller: _nameController,
                                hintText: 'Nome',
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(80),
                                ],
                                onChanged: (value) => widget.draft.name = value,
                                validator: (value) =>
                                    (value?.trim().length ?? 0) < 2
                                        ? 'Informe ao menos 2 caracteres.'
                                        : null,
                                onFieldSubmitted: (_) => _continue(),
                              ),
                              const SizedBox(height: 50),
                              AuthNextButton(
                                buttonKey: const Key(
                                  'continue-horse-registration',
                                ),
                                onPressed: _continue,
                              ),
                            ],
                          ),
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
