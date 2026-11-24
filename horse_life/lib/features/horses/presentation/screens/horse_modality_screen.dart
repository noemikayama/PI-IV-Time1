// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Delegação da consulta de modalidades ao HorseRegistrationController,
// desacoplando o repositório da tela e repassando o estado via navegação.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela autônoma de seleção da modalidade de treinos do cavalo
// (etapa 8 de 12), integrando FormProgressIndicator, AuthHeader, AppDropdownField
// arredondado assíncrono e botão Seguinte.
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
import '../../horse_registration_composition.dart';
import '../services/horse_image_selection_service.dart';
import 'horse_limitations_screen.dart';

typedef HorseModalityCallback = void Function(HorseRegistrationDraft draft);

/// Etapa 8 de 12: Seleção assíncrona da modalidade esportiva do cavalo.
class HorseModalityScreen extends StatefulWidget {
  const HorseModalityScreen({
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
  final HorseModalityCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<HorseModalityScreen> createState() => _HorseModalityScreenState();
}

class _HorseModalityScreenState extends State<HorseModalityScreen> {
  late final HorseRegistrationController _controller;
  late Future<List<HorseModality>> _modalitiesFuture;
  HorseModality? _selectedModality;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        HorseRegistrationComposition.productionController(
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          initialDraft: widget.draft,
        );
    _selectedModality = widget.draft.modality;
    _modalitiesFuture = _controller.fetchModalities();
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
    widget.draft.modality = _selectedModality;

    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(widget.draft);
      return;
    }

    final result = await Navigator.push<HorseRegistrationResult>(
      context,
      MaterialPageRoute<HorseRegistrationResult>(
        builder: (context) => HorseLimitationsScreen(
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
                              currentStep: 8,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Modalidade de treinos',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Selecione qual modalidade de\n'
                              'esporte seu cavalo pratica.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            FutureBuilder<List<HorseModality>>(
                              future: _modalitiesFuture,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData && !snapshot.hasError) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return Column(
                                    children: [
                                      const Text(
                                        'Não foi possível carregar as modalidades.',
                                      ),
                                      TextButton(
                                        onPressed: () => setState(() {
                                          _modalitiesFuture =
                                              _controller.fetchModalities();
                                        }),
                                        child: const Text('Tentar novamente'),
                                      ),
                                    ],
                                  );
                                }

                                final options =
                                    snapshot.data ?? <HorseModality>[];
                                final current =
                                    _selectedModality ??
                                    (options.isNotEmpty ? options.first : null);

                                if (_selectedModality == null &&
                                    current != null) {
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted && _selectedModality == null) {
                                      setState(() {
                                        _selectedModality = current;
                                        widget.draft.modality = current;
                                      });
                                    }
                                  });
                                }

                                return AppDropdownField<HorseModality>(
                                  style: AppDropdownStyle.rounded,
                                  label: 'Selecionar Modalidade',
                                  dropdownKey: const ValueKey(
                                    'horse-select-Modalidade',
                                  ),
                                  value: current,
                                  options: options,
                                  labelFor: (item) => item.name,
                                  isOpen: _isMenuOpen,
                                  onTap: () =>
                                      setState(() => _isMenuOpen = true),
                                  onChanged: (item) => setState(() {
                                    _selectedModality = item;
                                    _isMenuOpen = false;
                                    widget.draft.modality = item;
                                  }),
                                );
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
