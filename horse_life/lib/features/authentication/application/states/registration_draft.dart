// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do estado imutável de cadastro, com uma base para os dados
// compartilhados e estados específicos de responsável e treinador. O estado do
// treinador reúne a modalidade, os documentos de experiência e certificação em
// um único modelo e as regiões de atendimento, com operações imutáveis para
// atualizar, substituir ou remover esses dados.
// -----------------------------------------------------------------------------

import 'trainer_document.dart';
import 'trainer_service_area.dart';

// Estado-base dos dados compartilhados pelos dois fluxos de cadastro.
sealed class RegistrationDraft {
  const RegistrationDraft({
    required this.firstName,
    required this.lastName,
    this.email = '',
  });

  // Dados comuns e não sensíveis. A senha nunca pertence aos drafts.
  final String firstName;
  final String lastName;
  final String email;

  RegistrationDraft copyWithContact({
    String? firstName,
    String? lastName,
    String? email,
  });
}

// Estado exclusivo do responsável, sem campos do domínio profissional.
final class GuardianRegistrationDraft extends RegistrationDraft {
  const GuardianRegistrationDraft({
    required super.firstName,
    required super.lastName,
    super.email,
  });

  @override
  // Atualiza somente os dados compartilhados e preserva o tipo responsável.
  GuardianRegistrationDraft copyWithContact({
    String? firstName,
    String? lastName,
    String? email,
  }) {
    return GuardianRegistrationDraft(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
    );
  }
}

// Estado exclusivo do treinador; dados profissionais surgem apenas quando
// suas respectivas etapas forem concluídas.
final class TrainerRegistrationDraft extends RegistrationDraft {
  const TrainerRegistrationDraft({
    required super.firstName,
    required super.lastName,
    super.email,
    this.sport,
    this.trainerExperienceDocument,
    this.trainerCertificationDocuments = const [],
    this.serviceAreas = const [],
  });

  final String? sport;
  final TrainerDocument? trainerExperienceDocument;
  final List<TrainerDocument> trainerCertificationDocuments;
  final List<TrainerServiceArea> serviceAreas;

  @override
  // Atualiza o contato sem descartar as informações profissionais já coletadas.
  TrainerRegistrationDraft copyWithContact({
    String? firstName,
    String? lastName,
    String? email,
  }) {
    return TrainerRegistrationDraft(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      sport: sport,
      trainerExperienceDocument: trainerExperienceDocument,
      trainerCertificationDocuments: trainerCertificationDocuments,
      serviceAreas: serviceAreas,
    );
  }

  // Acrescenta a modalidade escolhida na terceira etapa do fluxo.
  TrainerRegistrationDraft withSport(String sport) {
    return TrainerRegistrationDraft(
      firstName: firstName,
      lastName: lastName,
      email: email,
      sport: sport,
      trainerExperienceDocument: trainerExperienceDocument,
      trainerCertificationDocuments: trainerCertificationDocuments,
      serviceAreas: serviceAreas,
    );
  }

  // Substitui ou remove o comprovante opcional de experiência.
  TrainerRegistrationDraft withTrainerExperienceDocument(
    TrainerDocument? document,
  ) {
    return TrainerRegistrationDraft(
      firstName: firstName,
      lastName: lastName,
      email: email,
      sport: sport,
      trainerExperienceDocument: document,
      trainerCertificationDocuments: trainerCertificationDocuments,
      serviceAreas: serviceAreas,
    );
  }

  // Cria uma cópia defensiva da coleção mutável mantida pela tela.
  TrainerRegistrationDraft withTrainerCertificationDocuments(
    List<TrainerDocument> documents,
  ) {
    return TrainerRegistrationDraft(
      firstName: firstName,
      lastName: lastName,
      email: email,
      sport: sport,
      trainerExperienceDocument: trainerExperienceDocument,
      trainerCertificationDocuments: List.unmodifiable(documents),
      serviceAreas: serviceAreas,
    );
  }

  // Consolida as áreas escolhidas em uma lista imutável antes de avançar.
  TrainerRegistrationDraft withServiceAreas(List<TrainerServiceArea> areas) {
    return TrainerRegistrationDraft(
      firstName: firstName,
      lastName: lastName,
      email: email,
      sport: sport,
      trainerExperienceDocument: trainerExperienceDocument,
      trainerCertificationDocuments: trainerCertificationDocuments,
      serviceAreas: List.unmodifiable(areas),
    );
  }
}
