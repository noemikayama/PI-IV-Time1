// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Carregamento e escolha de modalidade separados do fluxo.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../data/models/horse_registration_draft.dart';
import '../widgets/horse_choice_field.dart';

class HorseModalityStep extends StatelessWidget {
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
  Widget build(BuildContext context) => FutureBuilder<List<HorseModality>>(
    future: modalities,
    builder: (context, snapshot) {
      if (!snapshot.hasData && !snapshot.hasError) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Column(
          children: [
            const Text('Não foi possível carregar as modalidades.'),
            TextButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        );
      }
      final options = snapshot.data ?? <HorseModality>[];
      return HorseChoiceField<String>(
        label: 'Modalidade',
        value: value?.id ?? '',
        options: ['', ...options.map((option) => option.id)],
        name: (id) => id.isEmpty
            ? 'Sem modalidade'
            : options.firstWhere((item) => item.id == id).name,
        onChanged: (id) => onChanged(
          id.isEmpty ? null : options.firstWhere((item) => item.id == id),
        ),
      );
    },
  );
}
