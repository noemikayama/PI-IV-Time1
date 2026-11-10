// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Modelo do cadastro de cavalos alinhado ao contrato registerHorse.
// -----------------------------------------------------------------------------

import 'package:file_selector/file_selector.dart';

enum HorseRelationship {
  owner('Proprietário', ['PROPRIETARIO']),
  athlete('Atleta', ['ATLETA']),
  ownerAndAthlete('Proprietário e atleta', ['PROPRIETARIO', 'ATLETA']);

  const HorseRelationship(this.label, this.apiValues);
  final String label;
  final List<String> apiValues;
  bool get mayRegister => apiValues.contains('PROPRIETARIO');
}

enum HorseSex {
  female('Feminino', 'FEMEA'),
  male('Masculino', 'MACHO');

  const HorseSex(this.label, this.apiValue);
  final String label;
  final String apiValue;
}

class HorseModality {
  const HorseModality({required this.id, required this.name});
  final String id;
  final String name;
}

class HorseInjury {
  const HorseInjury({
    required this.date,
    required this.description,
    this.prescription,
  });
  final DateTime date;
  final String description;
  final String? prescription;

  Map<String, Object> toJson() => <String, Object>{
    'data': horseIsoDate(date),
    'descricao': description.trim(),
    if (prescription != null && prescription!.trim().isNotEmpty)
      'prescricao': prescription!.trim(),
  };
}

String horseIsoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// Draft mantido durante as etapas; só vira payload na fronteira do repositório.
class HorseRegistrationDraft {
  HorseRelationship relationship = HorseRelationship.owner;
  String name = '';
  String microchip = '';
  DateTime? birthDate;
  String breed = '';
  String coat = '';
  HorseSex sex = HorseSex.female;
  HorseModality? modality;
  final List<XFile> images = [];
  final List<String> physicalLimitations = [];
  final List<String> healthNotes = [];
  final List<HorseInjury> injuries = [];

  Map<String, Object?> toApiPayload() => <String, Object?>{
    'responsabilidades': relationship.apiValues,
    'nome': name.trim(),
    'codigo': microchip.trim(),
    'dataNascimento': birthDate == null ? null : horseIsoDate(birthDate!),
    'raca': breed.trim(),
    'pelagem': coat.trim(),
    'sexo': sex.apiValue,
    'modalidadeId': modality?.id,
    'limitacoesFisicas': physicalLimitations.map((e) => e.trim()).toList(),
    'observacoesSaude': healthNotes.map((e) => e.trim()).toList(),
    'historicoLesoes': injuries.map((e) => e.toJson()).toList(),
  };
}
