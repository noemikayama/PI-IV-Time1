// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela autônoma de seleção da raça do cavalo (etapa 4 de 12),
// integrando FormProgressIndicator, AuthHeader, campo de busca com overlay
// flutuante e botão Seguinte.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../application/controllers/horse_registration_controller.dart';
import '../../data/mocks/mock_horse_catalog.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../data/repositories/horse_registration_repository.dart';
import '../services/horse_image_selection_service.dart';
import '../widgets/horse_search_field.dart';
import 'horse_coat_screen.dart';

typedef HorseBreedCallback = void Function(HorseRegistrationDraft draft);

/// Etapa 4 de 12: Seleção e busca da raça do cavalo.
class HorseBreedScreen extends StatefulWidget {
  const HorseBreedScreen({
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
  final HorseBreedCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<HorseBreedScreen> createState() => _HorseBreedScreenState();
}

class _HorseBreedScreenState extends State<HorseBreedScreen> {
  late String _breed;

  @override
  void initState() {
    super.initState();
    _breed = widget.draft.breed;
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
    widget.draft.breed = _breed;

    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(widget.draft);
      return;
    }

    final result = await Navigator.push<HorseRegistrationResult>(
      context,
      MaterialPageRoute<HorseRegistrationResult>(
        builder: (context) => HorseCoatScreen(
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
                              currentStep: 4,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Raça',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Selecione qual é a raça do seu\nanimal.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            HorseSearchField(
                              key: const ValueKey('horse-breed-field'),
                              label: 'Raça',
                              options: MockHorseCatalog.breeds,
                              value: _breed,
                              onSelected: (value) {
                                setState(() => _breed = value);
                                widget.draft.breed = value;
                              },
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
