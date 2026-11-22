// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Usa dependências reais por padrão e conserva injeção para testes.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Desacoplamento da persistência e consulta das telas, centralizando
// no controller o rascunho (HorseRegistrationDraft), a busca de modalidades,
// a validação assíncrona de microchip e a submissão final do cadastro.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Regras do cadastro fora da interface e validação independente.
// -----------------------------------------------------------------------------

import 'dart:async';

import '../../data/catalogs/horse_catalog.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../data/repositories/horse_registration_repository.dart';

/// Controlador central do fluxo de cadastro de cavalos.
///
/// Mantém o rascunho de dados e centraliza as operações com o repositório
/// e validadores, isolando completamente as telas de detalhes de infraestrutura.
class HorseRegistrationController {
  HorseRegistrationController({
    required this.repository,
    required this.microchipValidator,
    HorseRegistrationDraft? initialDraft,
  }) : draft = initialDraft ?? HorseRegistrationDraft();

  final HorseRegistrationRepository repository;
  final HorseMicrochipValidator microchipValidator;

  /// Rascunho das informações do cavalo mantido ao longo de todas as etapas.
  final HorseRegistrationDraft draft;

  /// Carrega as modalidades disponíveis para treinos do animal.
  Future<List<HorseModality>> fetchModalities() {
    return repository.getModalities();
  }

  /// Valida o microchip com timeout defensivo de 10 segundos.
  Future<void> validateMicrochip(String microchip) async {
    await microchipValidator
        .validate(microchip)
        .timeout(const Duration(seconds: 10));
  }

  /// Valida o rascunho e submete o cadastro do cavalo ao repositório.
  Future<HorseRegistrationResult> register([
    HorseRegistrationDraft? draftToRegister,
  ]) async {
    final targetDraft = draftToRegister ?? draft;
    validateFields(targetDraft);
    // Confirmação do microchip antes de enviar o payload.
    try {
      await validateMicrochip(targetDraft.microchip);
    } on HorseMicrochipValidationFailure catch (error) {
      throw HorseRegistrationFailure(error.message);
    }
    return repository.register(targetDraft);
  }

  /// Validação síncrona de integridade de todos os campos do cadastro.
  void validateFields(HorseRegistrationDraft draft) {
    if (!draft.relationship.mayRegister) {
      throw const HorseRegistrationFailure(
        'Apenas proprietários podem cadastrar cavalos.',
      );
    }
    if (draft.name.trim().length < 2 || draft.name.trim().length > 80) {
      throw const HorseRegistrationFailure(
        'O nome deve ter entre 2 e 80 caracteres.',
      );
    }
    if (!RegExp(r'^\d{15}$').hasMatch(draft.microchip)) {
      throw const HorseRegistrationFailure(
        'O microchip deve conter exatamente 15 números.',
      );
    }
    final now = DateTime.now();
    final oldest = DateTime(now.year - 50, now.month, now.day);
    if (draft.birthDate == null ||
        draft.birthDate!.isAfter(now) ||
        draft.birthDate!.isBefore(oldest)) {
      throw const HorseRegistrationFailure(
        'Selecione uma data de nascimento válida.',
      );
    }
    if (!HorseCatalog.breeds.contains(draft.breed) ||
        !HorseCatalog.coats.contains(draft.coat)) {
      throw const HorseRegistrationFailure(
        'Selecione uma raça e uma pelagem das sugestões.',
      );
    }
    if (draft.physicalLimitations.length > 30 ||
        draft.healthNotes.length > 30 ||
        draft.injuries.length > 50) {
      throw const HorseRegistrationFailure(
        'Quantidade de registros adicionais acima do limite.',
      );
    }
    if (draft.injuries.any(
      (item) => item.date.isBefore(draft.birthDate!) || item.date.isAfter(now),
    )) {
      throw const HorseRegistrationFailure(
        'Confira as datas do histórico de lesões.',
      );
    }
  }
}
