// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adaptação visual da seleção de modalidades para utilizar o
// componente reutilizável AppDropdownField com estilo arredondado
// (AppDropdownStyle.rounded) e rótulo flutuante "Selecionar Modalidade".
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Carregamento e escolha de modalidade separados do fluxo.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_dropdown_field.dart';

import '../../data/models/horse_registration_draft.dart';

class HorseModalityStep extends StatefulWidget {
  const HorseModalityStep({
    required this.modalities,
    required this.value,
    required this.onChanged,
    required this.onRetry,
    super.key,
  });

  final Future<List<HorseModality>> modalities;
  final HorseModality? value;
  final ValueChanged<HorseModality?> onChanged;
  final VoidCallback onRetry;

  @override
  State<HorseModalityStep> createState() => _HorseModalityStepState();
}

class _HorseModalityStepState extends State<HorseModalityStep> {
  bool _isMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HorseModality>>(
      future: widget.modalities,
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
              const Text('Não foi possível carregar as modalidades.'),
              TextButton(
                onPressed: widget.onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          );
        }
        final options = snapshot.data ?? <HorseModality>[];
        final selectedValue =
            widget.value ?? (options.isNotEmpty ? options.first : null);

        if (widget.value == null && selectedValue != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && widget.value == null) {
              widget.onChanged(selectedValue);
            }
          });
        }

        return AppDropdownField<HorseModality>(
          style: AppDropdownStyle.rounded,
          label: 'Selecionar Modalidade',
          dropdownKey: const ValueKey('horse-select-Modalidade'),
          value: selectedValue,
          options: options,
          labelFor: (item) => item.name,
          isOpen: _isMenuOpen,
          onTap: () => setState(() => _isMenuOpen = true),
          onChanged: (item) {
            setState(() => _isMenuOpen = false);
            widget.onChanged(item);
          },
        );
      },
    );
  }
}
