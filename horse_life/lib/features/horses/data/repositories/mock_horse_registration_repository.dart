// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Repositório de testes sem gravação real, que espelha as validações.
// -----------------------------------------------------------------------------

import '../mocks/mock_horse_catalog.dart';
import '../models/horse_registration_draft.dart';
import 'horse_registration_repository.dart';

class MockHorseRegistrationRepository implements HorseRegistrationRepository {
  const MockHorseRegistrationRepository();

  @override
  Future<List<HorseModality>> getModalities() async => [
    for (var i = 0; i < MockHorseCatalog.modalityNames.length; i++)
      HorseModality(id: 'mock-$i', name: MockHorseCatalog.modalityNames[i]),
  ];

  @override
  Future<HorseRegistrationResult> register(HorseRegistrationDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!draft.relationship.mayRegister) {
      throw const HorseRegistrationFailure(
        'Apenas proprietários podem cadastrar cavalos.',
      );
    }
    if (!RegExp(r'^\d{15}$').hasMatch(draft.microchip)) {
      throw const HorseRegistrationFailure(
        'O microchip deve ter exatamente 15 dígitos numéricos.',
      );
    }
    if (draft.name.trim().length < 2 ||
        draft.birthDate == null ||
        draft.breed.trim().isEmpty ||
        draft.coat.trim().isEmpty) {
      throw const HorseRegistrationFailure(
        'Preencha os campos obrigatórios do cavalo.',
      );
    }
    if (draft.birthDate!.isAfter(DateTime.now())) {
      throw const HorseRegistrationFailure(
        'A data de nascimento não pode estar no futuro.',
      );
    }
    return HorseRegistrationResult(
      id: 'mock-${DateTime.now().microsecondsSinceEpoch}',
      name: draft.name.trim(),
      isPersisted: false,
    );
  }
}
