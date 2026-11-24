// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão dos contratos do treino do dia, período do plano ativo e
// permissão efetiva para iniciar ou apenas consultar a execução.
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos segmentos de identidade, vínculos, histórico,
// alterações parciais e serialização do perfil completo do cavalo.
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos modelos imutáveis do perfil completo do cavalo.
// -----------------------------------------------------------------------------

// --- Valores resumidos retornados junto ao perfil ---------------------------
// Estes modelos representam referências e informações calculadas que não
// possuem comportamento próprio na camada de apresentação.

/// Idade calculada pelo backend no instante da consulta.
class HorseProfileAge {
  const HorseProfileAge({required this.years, required this.months});

  final int years;
  final int months;
}

/// Imagem persistida no Storage e exposta por URL assinada temporária.
class HorseProfileImage {
  const HorseProfileImage({required this.path, required this.url});

  final String path;
  final String url;
}

/// Referência resumida de uma pessoa vinculada ao animal.
class HorseProfilePerson {
  const HorseProfilePerson({required this.id, required this.name});

  final String id;
  final String name;
}

/// Modalidade esportiva atualmente associada ao cavalo.
class HorseProfileModality {
  const HorseProfileModality({required this.id, required this.name});

  final String id;
  final String name;
}

/// Ação autorizada no treino diário exibido pelo perfil do cavalo.
enum HorseProfileTrainingAction { start, view, none }

/// Treino de hoje já contextualizado pelo backend para quem consulta o perfil.
class HorseProfileDayTraining {
  const HorseProfileDayTraining({
    required this.recordId,
    required this.name,
    required this.planName,
    required this.durationMinutes,
    required this.personRole,
    required this.personName,
    required this.status,
  });

  /// Identidade do registro e nomes usados na navegação da execução.
  final String recordId;
  final String name;
  final String planName;

  /// Duração planejada apresentada antes do carregamento dos detalhes.
  final int durationMinutes;

  /// Pessoa responsável exibida no card do treino diário.
  final String personRole;
  final String personName;

  /// Situação persistida do registro no formato retornado pelo backend.
  final String status;

  /// Indica registros totais ou parciais que não podem ser iniciados novamente.
  bool get isFinished => status == 'REALIZADO' || status == 'PARCIAL';
}

/// Plano ativo retornado pela consulta do cavalo.
class HorseProfilePlan {
  const HorseProfilePlan({
    required this.id,
    required this.title,
    this.startDate,
    this.endDate,
    this.todayTraining,
  });

  final String id;
  final String title;

  /// Período do plano, opcional para manter compatibilidade com dados antigos.
  final DateTime? startDate;
  final DateTime? endDate;

  /// Treino agendado para a data corrente, quando houver.
  final HorseProfileDayTraining? todayTraining;
}

/// Avaliação registrada por um treinador.
class HorseProfileEvaluation {
  const HorseProfileEvaluation({
    required this.id,
    required this.date,
    required this.trainer,
  });

  final String id;
  final DateTime date;
  final HorseProfilePerson trainer;
}

/// Registro de lesão usado na leitura e na atualização do histórico.
class HorseInjuryRecord {
  const HorseInjuryRecord({
    required this.date,
    required this.description,
    this.prescription,
  });

  final DateTime date;
  final String description;
  final String? prescription;

  Map<String, String> toJson() => {
    'data': _ymd(date),
    'descricao': description.trim(),
    if (prescription != null && prescription!.trim().isNotEmpty)
      'prescricao': prescription!.trim(),
  };

  @override
  bool operator ==(Object other) =>
      other is HorseInjuryRecord &&
      date == other.date &&
      description.trim() == other.description.trim() &&
      (prescription?.trim() ?? '') == (other.prescription?.trim() ?? '');

  @override
  int get hashCode =>
      Object.hash(date, description.trim(), prescription?.trim() ?? '');
}

// --- Agregado principal do cavalo -------------------------------------------
// Reúne identidade, histórico, vínculos e permissões devolvidos pela consulta.

/// Retrato completo devolvido por `getHorseProfile`.
class HorseProfileData {
  const HorseProfileData({
    required this.id,
    required this.microchip,
    required this.name,
    required this.birthDate,
    required this.age,
    required this.breed,
    required this.coat,
    required this.sex,
    required this.images,
    required this.modality,
    required this.physicalLimitations,
    required this.healthNotes,
    required this.injuries,
    required this.owner,
    required this.athlete,
    required this.trainers,
    required this.currentPlan,
    required this.evaluations,
    required this.responsibilities,
    this.trainingAction = HorseProfileTrainingAction.none,
  });

  final String id;
  final String microchip;
  final String name;
  final DateTime birthDate;
  final HorseProfileAge age;
  final String breed;
  final String coat;
  final String sex;
  final List<HorseProfileImage> images;
  final HorseProfileModality? modality;
  final List<String> physicalLimitations;
  final List<String> healthNotes;
  final List<HorseInjuryRecord> injuries;
  final HorseProfilePerson owner;
  final HorseProfilePerson? athlete;
  final List<HorseProfilePerson> trainers;
  final HorseProfilePlan? currentPlan;
  final List<HorseProfileEvaluation> evaluations;
  final List<String> responsibilities;

  /// Ação calculada pelo backend para o usuário que consultou o perfil.
  final HorseProfileTrainingAction trainingAction;

  /// Prioriza o vínculo de atleta quando a permissão remota estiver ausente ou
  /// desatualizada. O backend continua sendo a autoridade final no envio.
  HorseProfileTrainingAction get effectiveTrainingAction =>
      responsibilities.contains('ATLETA')
      ? HorseProfileTrainingAction.start
      : trainingAction;

  /// Somente o proprietário pode chamar `updateHorse` no contrato atual.
  bool get canEdit => responsibilities.contains('PROPRIETARIO');
}

// --- Alterações parciais enviadas ao backend --------------------------------
// Compara a versão carregada com a editada e serializa somente diferenças,
// preservando campos que não foram tocados pela pessoa usuária.

/// Inclusões e remoções de uma lista aceitas por `updateHorse`.
class HorseProfileListChanges<T> {
  const HorseProfileListChanges({
    this.added = const [],
    this.removed = const [],
  });

  final List<T> added;
  final List<T> removed;

  bool get isEmpty => added.isEmpty && removed.isEmpty;
}

HorseProfileListChanges<T>? horseProfileListChanges<T>(
  List<T> previous,
  List<T> current,
) {
  final changes = HorseProfileListChanges<T>(
    added: current.where((item) => !previous.contains(item)).toList(),
    removed: previous.where((item) => !current.contains(item)).toList(),
  );
  return changes.isEmpty ? null : changes;
}

/// Diferenças editáveis aceitas por `updateHorse`.
class HorseProfileUpdate {
  const HorseProfileUpdate({
    this.name,
    this.birthDate,
    this.breed,
    this.coat,
    this.sex,
    this.modalityId,
    this.shouldUpdateModality = false,
    this.physicalLimitations,
    this.healthNotes,
    this.injuries,
  });

  final String? name;
  final DateTime? birthDate;
  final String? breed;
  final String? coat;
  final String? sex;
  final String? modalityId;
  final bool shouldUpdateModality;
  final HorseProfileListChanges<String>? physicalLimitations;
  final HorseProfileListChanges<String>? healthNotes;
  final HorseProfileListChanges<HorseInjuryRecord>? injuries;

  bool get isEmpty =>
      name == null &&
      birthDate == null &&
      breed == null &&
      coat == null &&
      sex == null &&
      !shouldUpdateModality &&
      (physicalLimitations == null || physicalLimitations!.isEmpty) &&
      (healthNotes == null || healthNotes!.isEmpty) &&
      (injuries == null || injuries!.isEmpty);

  Map<String, Object?> toJson(String id) {
    final json = <String, Object?>{'id': id};
    if (name != null) json['nome'] = name!.trim();
    if (birthDate != null) json['dataNascimento'] = _ymd(birthDate!);
    if (breed != null) json['raca'] = breed!.trim();
    if (coat != null) json['pelagem'] = coat!.trim();
    if (sex != null) json['sexo'] = sex;
    if (shouldUpdateModality) json['modalidadeId'] = modalityId;
    if (physicalLimitations != null) {
      json['limitacoesFisicas'] = _listChangesJson(
        physicalLimitations!,
        (item) => item.trim(),
      );
    }
    if (healthNotes != null) {
      json['observacoesSaude'] = _listChangesJson(
        healthNotes!,
        (item) => item.trim(),
      );
    }
    if (injuries != null) {
      json['historicoLesoes'] = _listChangesJson(
        injuries!,
        (item) => item.toJson(),
      );
    }
    return json;
  }
}

// --- Serialização compartilhada pelo contrato remoto ------------------------

Map<String, Object?> _listChangesJson<T>(
  HorseProfileListChanges<T> changes,
  Object Function(T item) serialize,
) => {
  'adicionar': changes.added.map(serialize).toList(growable: false),
  'remover': changes.removed.map(serialize).toList(growable: false),
};

String _ymd(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')}';
