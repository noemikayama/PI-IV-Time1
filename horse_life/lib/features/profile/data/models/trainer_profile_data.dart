// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de cavalo, documentos, regiões e dados
// agregados do perfil profissional.
//
// Data: 10/11/2026 (perfil do cavalo)
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão do id no resumo de cavalo do treinador.
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Preservação dos caminhos dos anexos e dos dados estruturados das
// regiões para permitir edição e remoção pelo contrato updateTrainerProfile.
//
// Data: 09/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão da coleção de certificações para permitir a listagem e
// abertura individual dos documentos no perfil.
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos modelos imutáveis do perfil, documento de experiência,
// regiões de atendimento e cavalos vinculados ao treinador.
// -----------------------------------------------------------------------------

/// Resumo de um cavalo acompanhado pelo treinador.
class TrainerProfileHorse {
  const TrainerProfileHorse({this.id = '', required this.name, this.imageUrl});

  final String id;

  /// Nome exibido no card do vínculo.
  final String name;

  /// URL assinada da primeira imagem ou nulo para usar o fallback visual.
  final String? imageUrl;
}

/// PDF de experiência profissional retornado pelo backend.
class TrainerExperienceDocument {
  const TrainerExperienceDocument({
    required this.fileName,
    required this.url,
    this.path = '',
  });

  /// Nome derivado do último segmento do caminho persistido no backend.
  final String fileName;

  /// URL assinada temporária usada somente para leitura do documento.
  final String url;

  /// Caminho persistido usado pelo backend para identificar uma remoção.
  final String path;
}

/// Região no formato exato devolvido e aceito pelas Cloud Functions.
class TrainerProfileServiceRegion {
  const TrainerProfileServiceRegion({
    required this.state,
    required this.city,
    this.complement,
  });

  final String state;
  final String city;
  final String? complement;

  /// Identificador normalizado para detectar duplicidades antes do envio.
  String get identifier => [
    state,
    city,
    complement ?? '',
  ].map((value) => value.trim().toLowerCase()).join('|');

  /// Texto compacto apresentado nas listas do perfil e da edição.
  String get label {
    final location = state.isEmpty ? city : '$city - $state';
    final detail = complement?.trim() ?? '';
    return detail.isEmpty ? location : '$location ($detail)';
  }

  Map<String, String> toJson() => {
    'estado': state,
    'cidade': city,
    if (complement != null && complement!.trim().isNotEmpty)
      'complemento': complement!.trim(),
  };
}

/// Dados necessários para montar o perfil profissional do treinador.
class TrainerProfileData {
  const TrainerProfileData({
    required this.name,
    required this.email,
    required this.professionalStatus,
    required this.experience,
    required this.certificationCount,
    this.certifications = const [],
    required this.serviceRegions,
    this.serviceRegionEntries = const [],
    required this.horses,
  });

  /// Nome completo devolvido pelo perfil autenticado.
  final String name;

  /// E-mail somente para exibição; a edição do perfil não o altera.
  final String email;

  /// Texto já convertido do enum remoto para apresentação.
  final String professionalStatus;

  /// Documento único de experiência, quando confirmado no Storage.
  final TrainerExperienceDocument? experience;

  /// Indica se existe experiência sem expor a nulabilidade aos consumidores.
  bool get hasExperience => experience != null;

  /// Total retornado para resumos e validações da interface.
  final int certificationCount;

  /// Certificações com URL assinada disponíveis para leitura.
  final List<TrainerExperienceDocument> certifications;

  /// Regiões formatadas para apresentação no bottom sheet.
  final List<String> serviceRegions;

  /// Regiões sem formatação, necessárias para remoções aceitas pelo backend.
  final List<TrainerProfileServiceRegion> serviceRegionEntries;

  /// Cavalos enriquecidos por getHorse antes do mapeamento final.
  final List<TrainerProfileHorse> horses;
}
