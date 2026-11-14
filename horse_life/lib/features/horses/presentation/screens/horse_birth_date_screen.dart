// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela autônoma de data de nascimento do cavalo (etapa 3 de 12),
// integrando FormProgressIndicator, AuthHeader, AppDatePickerField em português
// e botão Seguinte.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../application/controllers/horse_registration_controller.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../data/repositories/horse_registration_repository.dart';
import '../services/horse_image_selection_service.dart';
import '../widgets/horse_registration_calendar.dart';
import 'horse_breed_screen.dart';

typedef HorseBirthDateCallback = void Function(HorseRegistrationDraft draft);

/// Etapa 3 de 12: Seleção da data de nascimento do animal com date picker localizado.
class HorseBirthDateScreen extends StatefulWidget {
  const HorseBirthDateScreen({
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
  final HorseBirthDateCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<HorseBirthDateScreen> createState() => _HorseBirthDateScreenState();
}

class _HorseBirthDateScreenState extends State<HorseBirthDateScreen> {
  DateTime? _birthDate;

  @override
  void initState() {
    super.initState();
    _birthDate = widget.draft.birthDate;
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final min = DateTime(now.year - 50, now.month, now.day);
    final date = await showHorseRegistrationCalendar(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: min,
      lastDate: now,
      title: 'Data de nascimento',
    );
    if (!mounted || date == null) return;
    setState(() {
      _birthDate = date;
      widget.draft.birthDate = date;
      widget.draft.injuries.removeWhere((injury) => injury.date.isBefore(date));
    });
  }

  Future<void> _continue() async {
    widget.draft.birthDate = _birthDate;
    if (_birthDate != null) {
      widget.draft.injuries.removeWhere(
        (injury) => injury.date.isBefore(_birthDate!),
      );
    }

    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(widget.draft);
      return;
    }

    final result = await Navigator.push<HorseRegistrationResult>(
      context,
      MaterialPageRoute<HorseRegistrationResult>(
        builder: (context) => HorseBreedScreen(
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
                              currentStep: 3,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Data de nascimento',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Selecione qual é a data de\n'
                              'nascimento do seu animal.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 20,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            AppDatePickerField(
                              key: const ValueKey('horse-birth-date'),
                              value: _birthDate,
                              hintText: 'DD/MM/AAAA',
                              onTap: _pickBirthDate,
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
