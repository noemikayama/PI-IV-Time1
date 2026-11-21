// RESPONSÁVEL PELA IMPLEMENTAÇÃO FLUTTER: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 21/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição do status canceled ('CANCELADO') a GuardianTrainingStatus.
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Modelos tipados para as callable Functions do responsável.
// Contrato baseado nos types TypeScript fornecidos pela equipe de backend.
// -----------------------------------------------------------------------------

/// Campos de resumo usados nas listas da home (RefResumo).
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Criação dos modelos tipados para getHome, getGuardianProfile e registerGuardian.
// -----------------------------------------------------------------------------
class GuardianReference {
  final String id;
  final String name;

  const GuardianReference({required this.id, required this.name});

  factory GuardianReference.fromJson(Map<String, dynamic> json) =>
      GuardianReference(id: _asId(json['id']), name: _asString(json['nome']));
}

class GuardianProgress {
  final int completed;
  final int total;

  const GuardianProgress({required this.completed, required this.total});

  factory GuardianProgress.fromJson(Map<String, dynamic> json) =>
      GuardianProgress(
        completed: _asInt(json['feitos']),
        total: _asInt(json['total']),
      );
}

enum GuardianTrainingStatus {
  planned('PLANEJADO'),
  completed('REALIZADO'),
  partial('PARCIAL'),
  notCompleted('NAO_REALIZADO'),
  canceled('CANCELADO');

  const GuardianTrainingStatus(this.apiValue);
  final String apiValue;

  static GuardianTrainingStatus fromApi(dynamic value) {
    return GuardianTrainingStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () =>
          throw FormatException('Status de treino desconhecido: $value'),
    );
  }
}

class GuardianTodayTraining {
  final String recordId;
  final String title;
  final String horseName;
  final String trainerName;
  final int durationMinutes;
  final String planName;
  final GuardianTrainingStatus status;

  const GuardianTodayTraining({
    required this.recordId,
    required this.title,
    required this.horseName,
    required this.trainerName,
    required this.durationMinutes,
    required this.planName,
    required this.status,
  });

  factory GuardianTodayTraining.fromJson(Map<String, dynamic> json) =>
      GuardianTodayTraining(
        recordId: _asId(json['registroId']),
        title: _asString(json['nomeTreino']),
        horseName: _asString(json['nomeCavalo']),
        trainerName: _asString(json['nomeTreinador']),
        durationMinutes: _asInt(json['duracaoMinutos']),
        planName: _asString(json['nomePlano']),
        status: GuardianTrainingStatus.fromApi(json['status']),
      );
}

/// Retorno exclusivo da home de responsável, dentro de getHome().
class GuardianHomeModel {
  final String name;
  final int totalHorses;
  final List<GuardianTodayTraining> todayTrainings;
  final GuardianProgress week;
  final GuardianProgress month;
  final int allTimeCompleted;
  final List<GuardianReference> horses;
  final List<GuardianReference> trainers;

  const GuardianHomeModel({
    required this.name,
    required this.totalHorses,
    required this.todayTrainings,
    required this.week,
    required this.month,
    required this.allTimeCompleted,
    required this.horses,
    required this.trainers,
  });

  factory GuardianHomeModel.fromJson(Map<String, dynamic> json) {
    if (json['tipoConta'] != 'RESPONSAVEL') {
      throw const FormatException(
        'getHome não retornou uma conta RESPONSAVEL.',
      );
    }
    return GuardianHomeModel(
      name: _asString(json['nome']),
      totalHorses: _asInt(json['totalCavalos']),
      todayTrainings: _asList(json['treinosDoDia'])
          .map((e) => GuardianTodayTraining.fromJson(_asMap(e)))
          .toList(growable: false),
      week: GuardianProgress.fromJson(_asMap(json['treinosSemana'])),
      month: GuardianProgress.fromJson(_asMap(json['treinosMes'])),
      allTimeCompleted: _asInt(json['treinosTotal']),
      horses: _asList(json['cavalos'])
          .map((e) => GuardianReference.fromJson(_asMap(e)))
          .toList(growable: false),
      trainers: _asList(json['treinadores'])
          .map((e) => GuardianReference.fromJson(_asMap(e)))
          .toList(growable: false),
    );
  }
}

class GuardianHorseProfile {
  final String id;
  final String code;
  final String name;
  final List<String> responsibilities;

  const GuardianHorseProfile({
    required this.id,
    required this.code,
    required this.name,
    required this.responsibilities,
  });

  factory GuardianHorseProfile.fromJson(Map<String, dynamic> json) =>
      GuardianHorseProfile(
        id: _asId(json['_id']),
        code: _asString(json['codigo']),
        name: _asString(json['nome']),
        responsibilities: _asList(
          json['responsabilidades'],
        ).map(_asString).toList(growable: false),
      );
}

class GuardianModality {
  final String id;
  final int code;
  final String name;

  const GuardianModality({
    required this.id,
    required this.code,
    required this.name,
  });

  factory GuardianModality.fromJson(Map<String, dynamic> json) =>
      GuardianModality(
        id: _asId(json['_id']),
        code: _asInt(json['codigo']),
        name: _asString(json['nome']),
      );
}

/// Retorno de getGuardianProfile: inclui dados que não pertencem à home.
class GuardianProfileModel {
  final String uid;
  final int code;
  final String name;
  final String email;
  final String registrationStatus;
  final List<GuardianHorseProfile> horses;
  final List<GuardianModality> modalities;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GuardianProfileModel({
    required this.uid,
    required this.code,
    required this.name,
    required this.email,
    required this.registrationStatus,
    required this.horses,
    required this.modalities,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GuardianProfileModel.fromJson(Map<String, dynamic> json) =>
      GuardianProfileModel(
        uid: _asId(json['_id']),
        code: _asInt(json['codigo']),
        name: _asString(json['nome']),
        email: _asString(json['email']),
        registrationStatus: _asString(json['situacaoCadastral']),
        horses: _asList(json['cavalos'])
            .map((e) => GuardianHorseProfile.fromJson(_asMap(e)))
            .toList(growable: false),
        modalities: _asList(json['modalidades'])
            .map((e) => GuardianModality.fromJson(_asMap(e)))
            .toList(growable: false),
        createdAt: DateTime.parse(_asString(json['criadoEm'])),
        updatedAt: DateTime.parse(_asString(json['atualizadoEm'])),
      );
}

class GuardianRegistrationInput {
  final String name;
  final String email;
  final String password;

  const GuardianRegistrationInput({
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'nome': name,
    'email': email,
    'senha': password,
  };
}

class GuardianRegistrationResult {
  final String id;
  final int code;
  final String email;

  const GuardianRegistrationResult({
    required this.id,
    required this.code,
    required this.email,
  });

  factory GuardianRegistrationResult.fromJson(Map<String, dynamic> json) =>
      GuardianRegistrationResult(
        id: _asId(json['id']),
        code: _asInt(json['codigo']),
        email: _asString(json['email']),
      );
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('Esperado objeto JSON, recebido: ${value.runtimeType}');
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  throw FormatException('Esperada lista JSON, recebido: ${value.runtimeType}');
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException('Esperado inteiro, recebido: $value');
}

String _asString(dynamic value) {
  if (value is String) return value;
  throw FormatException('Esperado texto, recebido: $value');
}

String _asId(dynamic value) {
  if (value is String) return value;
  // Caso algum ObjectId do MongoDB seja serializado como objeto estendido.
  if (value is Map && value[r'$oid'] is String) return value[r'$oid'] as String;
  throw FormatException('Identificador inesperado: $value');
}
