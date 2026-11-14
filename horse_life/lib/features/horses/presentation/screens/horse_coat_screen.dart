// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela autônoma de seleção da pelagem do cavalo (etapa 5 de 12),
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
import 'horse_sex_screen.dart';

typedef HorseCoatCallback = void Function(HorseRegistrationDraft draft);

/// Etapa 5 de 12: Seleção e busca da pelagem do cavalo.
class HorseCoatScreen extends StatefulWidget {
  const HorseCoatScreen({
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
  final HorseCoatCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<HorseCoatScreen> createState() => _HorseCoatScreenState();
}

class _HorseCoatScreenState extends State<HorseCoatScreen> {
  late String _coat;

  @override
  void initState() {
    super.initState();
    _coat = widget.draft.coat;
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
    widget.draft.coat = _coat;

    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(widget.draft);
      return;
    }

    final result = await Navigator.push<HorseRegistrationResult>(
      context,
      MaterialPageRoute<HorseRegistrationResult>(
        builder: (context) => HorseSexScreen(
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
                              currentStep: 5,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Pelagem',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Selecione qual é a coloração da\n'
                              'pelagem do seu cavalo.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            HorseSearchField(
                              key: const ValueKey('horse-coat-field'),
                              label: 'Pelagem',
                              options: MockHorseCatalog.coats,
                              value: _coat,
                              onSelected: (value) {
                                setState(() => _coat = value);
                                widget.draft.coat = value;
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
