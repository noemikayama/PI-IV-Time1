// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 01/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do getDashboard com contrato real e modo mock.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários pontuais sobre a responsabilidade do arquivo.
//
// -----------------------------------------------------------------------------

/// Representa a resposta da Cloud Function e oferece acesso seguro às seções recebidas.
class DashboardResponse {
  DashboardResponse(this.json);
  final Map<String, dynamic> json;
  String get role => json['tipoConta'] as String? ?? '';
  bool get professional => json['painelProfissional'] == true;
  bool get hasData => json['possuiDados'] == true;
  List<Map<String, dynamic>> get horses => _maps(json['cavalos']);
  List<Map<String, dynamic>> get trainings => _maps(json['ultimosTreinos']);
  List<Map<String, dynamic>> get feedbacks => _maps(json['ultimosFeedbacks']);
  Map<String, dynamic> section(String name) => _map(json[name]);
  int number(String name) => (json[name] as num?)?.toInt() ?? 0;
  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? value.map((k, v) => MapEntry(k.toString(), v)) : {};
  static List<Map<String, dynamic>> _maps(Object? value) =>
      value is List ? value.map(_map).toList() : [];
  static Map<String, dynamic> normalize(Object? value) => _map(value);
  static num numeric(Map<String, dynamic> values, String key) =>
      (values[key] as num?) ?? 0;
}
