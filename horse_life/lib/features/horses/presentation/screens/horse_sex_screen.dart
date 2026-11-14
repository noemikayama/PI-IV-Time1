// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela autônoma de seleção do sexo do cavalo (etapa 6 de 12),
// integrando FormProgressIndicator, AuthHeader, AppDropdownField arredondado
// com opções Macho e Fêmea e botão Seguinte.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_dropdown_field.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../application/controllers/horse_registration_controller.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../data/repositories/horse_registration_repository.dart';
import '../services/horse_image_selection_service.dart';
import 'horse_images_screen.dart';

typedef HorseSexCallback = void Function(HorseRegistrationDraft draft);

/// Etapa 6 de 12: Seleção do sexo do cavalo (Macho ou Fêmea).
class HorseSexScreen extends StatefulWidget {
  const HorseSexScreen({
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
  final HorseSexCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<HorseSexScreen> createState() => _HorseSexScreenState();
}

class _HorseSexScreenState extends State<HorseSexScreen> {
  late HorseSex _selectedSex;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedSex = widget.draft.sex;
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
    widget.draft.sex = _selectedSex;

    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(widget.draft);
      return;
    }

    final result = await Navigator.push<HorseRegistrationResult>(
      context,
      MaterialPageRoute<HorseRegistrationResult>(
        builder: (context) => HorseImagesScreen(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const FormProgressIndicator(
                              configuration:
                                  FormProgressConfiguration.horseRegistration,
                              currentStep: 6,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Sexo',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Selecione se o animal é do sexo\n'
                              'masculino ou feminino.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            AppDropdownField<HorseSex>(
                              style: AppDropdownStyle.rounded,
                              label: 'Selecionar sexo',
                              dropdownKey: const ValueKey('horse-select-Sexo'),
                              value: _selectedSex,
                              options: HorseSex.values,
                              labelFor: (item) => item.label,
                              isOpen: _isMenuOpen,
                              onTap: () => setState(() => _isMenuOpen = true),
                              onChanged: (value) => setState(() {
                                _selectedSex = value;
                                _isMenuOpen = false;
                                widget.draft.sex = value;
                              }),
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
