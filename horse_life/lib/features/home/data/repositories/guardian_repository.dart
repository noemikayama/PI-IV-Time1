// RESPONSÁVEL PELA DOCUMENTAÇÃO/INTEGRAÇÃO: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 25/10/2026
// Autor da documentação e integração: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização dos cabeçalhos e comentários explicativos das
// principais responsabilidades, regras e fluxos do módulo Guardian.
// -----------------------------------------------------------------------------
import 'package:cloud_functions/cloud_functions.dart';
import '../models/guardian_model.dart';

/// Contrato abstrato para desacoplar a UI da implementação de rede.
abstract class GuardianRepository {
  Future<GuardianHomeModel> getHome();
  Future<GuardianProfileModel> getProfile();
  Future<GuardianRegistrationResult> register(GuardianRegistrationInput input);
}

/// Implementação real usando callable Functions na região southamerica-east1.
class FirebaseGuardianRepository implements GuardianRepository {
  final FirebaseFunctions _functions;

  FirebaseGuardianRepository({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  // Encapsula a chamada e garante que o payload retornado seja um mapa.
  Future<Map<String, dynamic>> _call(
    String functionName, [
    Map<String, dynamic>? payload,
  ]) async {
    final response = await _functions
        .httpsCallable(functionName)
        .call<dynamic>(payload ?? <String, dynamic>{});
    if (response.data is! Map) {
      throw const FormatException('Resposta inválida da Cloud Function.');
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<GuardianHomeModel> getHome() async {
    // getHome exige usuário autenticado e seleciona a home pelo role.
    return GuardianHomeModel.fromJson(await _call('getHome'));
  }

  @override
  Future<GuardianProfileModel> getProfile() async {
    // getGuardianProfile exige role de responsável.
    return GuardianProfileModel.fromJson(await _call('getGuardianProfile'));
  }

  @override
  Future<GuardianRegistrationResult> register(
    GuardianRegistrationInput input,
  ) async {
    // Cadastro público; o backend é responsável por criar o Auth e gravar no MongoDB.
    return GuardianRegistrationResult.fromJson(
      await _call('registerGuardian', input.toJson()),
    );
  }
}
