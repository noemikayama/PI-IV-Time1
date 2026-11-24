// RESPONSÁVEL PELA IMPLEMENTAÇÃO FLUTTER: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Criação do contrato tipado provisório da Home do Profissional,
// seguindo a separação entre API e apresentação adotada no Guardian.
// -----------------------------------------------------------------------------

// Data: 27/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Alinhamento do modelo Professional ao tipo HomeTreinador de
// functions/src/features/authentication/trainer/types/trainer.ts.
// Campos ausentes da API não são transformados em contagens fictícias.
// -----------------------------------------------------------------------------

/// Contrato confirmado: getHome para a role trainer retorna HomeTreinador.
/// A API ainda não expõe especialidade ou quantidade de planos ativos.
class TrainerReference {
  final String id;
  final String name;

  const TrainerReference({required this.id, required this.name});

  factory TrainerReference.fromJson(Map<String, dynamic> json) =>
      TrainerReference(
        id: _asId(json['id']),
        name: _asString(json['nome']),
      );
}

class TrainerProgress {
  final int completed;
  final int total;

  const TrainerProgress({required this.completed, required this.total});

  factory TrainerProgress.fromJson(Map<String, dynamic> json) =>
      TrainerProgress(
        completed: _asInt(json['feitos']),
        total: _asInt(json['total']),
      );
}

class TrainerTodayTraining {
  final String recordId;
  final String title;
  final String horseName;
  final String planName;
  final String? status;

  const TrainerTodayTraining({
    required this.recordId,
    required this.title,
    required this.horseName,
    required this.planName,
    this.status,
  });

  factory TrainerTodayTraining.fromJson(Map<String, dynamic> json) =>
      TrainerTodayTraining(
        recordId: _asId(json['registroId']),
        title: _asString(json['nomeTreino']),
        horseName: _asString(json['nomeCavalo']),
        planName: _asString(json['nomePlano']),
        status: json['status'] == null ? null : _asString(json['status']),
      );
}

/// Resposta retornada pela callable getHome quando tipoConta é TREINADOR.
class TrainerHomeModel {
  final String name;
  final String? specialty;
  final int totalHorses;
  final List<TrainerTodayTraining> todayTrainings;
  final TrainerProgress feedbacksWeek;
  final int? activePlans;
  final TrainerProgress trainingsWeek;
  final int createdExercises;
  final List<TrainerReference> horses;
  final List<TrainerReference> clients;

  const TrainerHomeModel({
    required this.name,
    required this.specialty,
    required this.totalHorses,
    required this.todayTrainings,
    required this.feedbacksWeek,
    required this.activePlans,
    required this.trainingsWeek,
    required this.createdExercises,
    required this.horses,
    required this.clients,
  });

  factory TrainerHomeModel.fromJson(Map<String, dynamic> json) {
    final role = json['tipoConta'];
    if (role != 'TREINADOR') {
      throw FormatException(
        'getHome não retornou uma conta TREINADOR. tipoConta: $role',
      );
    }

    return TrainerHomeModel(
      name: _asString(json['nome']),
      specialty: _optionalString(json['modalidade']), // Não enviado atualmente.
      totalHorses: _asInt(json['totalCavalos']),
      todayTrainings: _asList(json['treinosDoDia'])
          .map((item) => TrainerTodayTraining.fromJson(_asMap(item)))
          .toList(growable: false),
      feedbacksWeek: TrainerProgress.fromJson(
        _asMap(json['feedbacksSemana']),
      ),
      activePlans: _optionalInt(json['planosAtivos']), // Não enviado atualmente.
      trainingsWeek: TrainerProgress.fromJson(
        _asMap(json['treinosSemana']),
      ),
      createdExercises: _asInt(json['totalExercicios']),
      horses: _asList(json['cavalos'])
          .map((item) => TrainerReference.fromJson(_asMap(item)))
          .toList(growable: false),
      clients: _asList(json['clientes'])
          .map((item) => TrainerReference.fromJson(_asMap(item)))
          .toList(growable: false),
    );
  }
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

String? _optionalString(dynamic value) => value == null ? null : _asString(value);

int? _optionalInt(dynamic value) => value == null ? null : _asInt(value);

String _asId(dynamic value) {
  if (value is String) return value;
  if (value is Map && value[r'$oid'] is String) return value[r'$oid'] as String;
  throw FormatException('Identificador inesperado: $value');
}
