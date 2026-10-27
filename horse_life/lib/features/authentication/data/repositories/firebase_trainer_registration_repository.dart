// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração sequencial do cadastro profissional, autenticação
// temporária e envio dos PDFs por URLs assinadas do Storage.
// -----------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../application/states/registration_draft.dart';
import '../../application/states/trainer_document.dart';
import '../../application/states/trainer_service_area.dart';
import '../models/brazilian_country_region.dart';
import 'registration_repository.dart';

typedef TrainerRegistrationCall =
    Future<void> Function(Map<String, Object> data);
typedef TrainerAuthenticationCall =
    Future<void> Function(String email, String password);
typedef TrainerAttachmentUploadCall =
    Future<TrainerAttachmentUpload> Function(TrainerAttachmentType type);
typedef TrainerFileUploadCall =
    Future<void> Function(TrainerAttachmentUpload upload, Uint8List bytes);
typedef TrainerAttachmentConfirmationCall =
    Future<void> Function(TrainerAttachmentType type, String path);
typedef TrainerSignOutCall = Future<void> Function();

enum TrainerAttachmentType {
  experience('experiencias'),
  certification('certificacoes');

  const TrainerAttachmentType(this.value);

  final String value;
}

class TrainerAttachmentUpload {
  const TrainerAttachmentUpload({
    required this.path,
    required this.url,
    required this.headers,
  });

  final String path;
  final String url;
  final Map<String, String> headers;
}

// Cria primeiro a conta profissional e só então envia os anexos, pois os
// caminhos do Storage são derivados do UID autenticado.
final class FirebaseTrainerRegistrationRepository
    implements RegistrationRepository {
  const FirebaseTrainerRegistrationRepository({
    TrainerRegistrationCall? registerTrainer,
    TrainerAuthenticationCall? authenticate,
    TrainerAttachmentUploadCall? createAttachmentUpload,
    TrainerFileUploadCall? uploadFile,
    TrainerAttachmentConfirmationCall? confirmAttachment,
    TrainerSignOutCall? signOut,
  }) : _registerTrainer = registerTrainer,
       _authenticate = authenticate,
       _createAttachmentUpload = createAttachmentUpload,
       _uploadFile = uploadFile,
       _confirmAttachment = confirmAttachment,
       _signOut = signOut;

  static const _region = 'southamerica-east1';
  static const _registerFunctionName = 'registerTrainer';
  static const _loginFunctionName = 'login';
  static const _createUploadFunctionName = 'createTrainerAttachmentUpload';
  static const _confirmUploadFunctionName = 'confirmTrainerAttachment';
  static const _allCities = 'Todas as cidades';

  final TrainerRegistrationCall? _registerTrainer;
  final TrainerAuthenticationCall? _authenticate;
  final TrainerAttachmentUploadCall? _createAttachmentUpload;
  final TrainerFileUploadCall? _uploadFile;
  final TrainerAttachmentConfirmationCall? _confirmAttachment;
  final TrainerSignOutCall? _signOut;

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: _region);

  @override
  Future<void> createAccount({
    required RegistrationDraft registration,
    required String password,
  }) async {
    if (registration is! TrainerRegistrationDraft) {
      throw const RegistrationFailure(
        'Este repositório aceita apenas cadastros profissionais.',
      );
    }

    _validateDocuments(registration);
    final data = _buildRegistrationData(registration, password);

    try {
      await (_registerTrainer ?? _registerTrainerWithFirebase)(data);
    } on RegistrationFailure {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      throw _mapRegistrationFailure(error);
    } catch (_) {
      throw const RegistrationFailure.connection();
    }

    final documents = _documentsFrom(registration);
    if (documents.isEmpty) return;

    var isAuthenticated = false;
    try {
      await (_authenticate ?? _authenticateWithFirebase)(
        registration.email.trim(),
        password,
      );
      isAuthenticated = true;

      for (final document in documents) {
        await _sendDocument(document.$1, document.$2);
      }
    } on RegistrationFailure catch (error) {
      throw RegistrationFailure(
        'Sua conta foi criada, mas não foi possível enviar todos os '
        'documentos. ${error.message}',
        accountCreated: true,
      );
    } catch (_) {
      throw const RegistrationFailure(
        'Sua conta foi criada, mas não foi possível enviar todos os '
        'documentos. Tente adicioná-los novamente depois de entrar.',
        accountCreated: true,
      );
    } finally {
      if (isAuthenticated) {
        try {
          await (_signOut ?? _signOutFromFirebase)();
        } catch (_) {
          // A conta e os documentos já foram persistidos. Uma falha local ao
          // encerrar a sessão não deve transformar o cadastro em nova tentativa.
        }
      }
    }
  }

  Map<String, Object> _buildRegistrationData(
    TrainerRegistrationDraft registration,
    String password,
  ) {
    final sport = registration.sport?.trim();
    if (sport == null || sport.isEmpty) {
      throw const RegistrationFailure('Selecione uma modalidade.');
    }

    return {
      'nome':
          '${registration.firstName.trim()} '
          '${registration.lastName.trim()}',
      'email': registration.email.trim(),
      'senha': password,
      'modalidades': [sport],
      'regioesAtendimento': _serializeServiceAreas(registration.serviceAreas),
    };
  }

  List<Map<String, Object>> _serializeServiceAreas(
    List<TrainerServiceArea> areas,
  ) {
    final serialized = <String, Map<String, Object>>{};

    void addArea({
      required String state,
      required String city,
      String? complement,
    }) {
      serialized['$state|$city'] = {
        'estado': state,
        'cidade': city,
        'complemento': ?complement,
      };
    }

    for (final area in areas) {
      switch (area.type) {
        case TrainerServiceAreaType.countryRegion:
          final region = BrazilianCountryRegions.values.firstWhere(
            (region) => region.name == area.countryRegion,
            orElse: () => throw const RegistrationFailure(
              'Região de atendimento inválida.',
            ),
          );
          final stateCodes = region.stateCodes.toList()..sort();
          for (final stateCode in stateCodes) {
            addArea(
              state: stateCode,
              city: _allCities,
              complement: 'Região ${area.countryRegion}',
            );
          }
        case TrainerServiceAreaType.state:
          addArea(
            state: area.stateCode!,
            city: _allCities,
            complement: 'Estado inteiro',
          );
        case TrainerServiceAreaType.city:
          addArea(state: area.stateCode!, city: area.cityName!);
      }
    }

    if (serialized.length > 30) {
      throw const RegistrationFailure(
        'Selecione no máximo 30 regiões de atendimento.',
      );
    }
    return serialized.values.toList(growable: false);
  }

  void _validateDocuments(TrainerRegistrationDraft registration) {
    if (registration.trainerCertificationDocuments.length >
        TrainerDocumentLimits.maximumCertifications) {
      throw const RegistrationFailure('Adicione no máximo 10 certificações.');
    }

    final documents = [
      ?registration.trainerExperienceDocument,
      ...registration.trainerCertificationDocuments,
    ];
    for (final document in documents) {
      final isPdf = document.name.toLowerCase().endsWith('.pdf');
      if (!isPdf || !TrainerDocumentLimits.acceptsSize(document.sizeInBytes)) {
        throw const RegistrationFailure(
          'Cada documento deve ser um PDF de até 10 MB.',
        );
      }
    }
  }

  List<(TrainerAttachmentType, TrainerDocument)> _documentsFrom(
    TrainerRegistrationDraft registration,
  ) {
    return [
      if (registration.trainerExperienceDocument case final document?)
        (TrainerAttachmentType.experience, document),
      for (final document in registration.trainerCertificationDocuments)
        (TrainerAttachmentType.certification, document),
    ];
  }

  Future<void> _sendDocument(
    TrainerAttachmentType type,
    TrainerDocument document,
  ) async {
    final createUpload =
        _createAttachmentUpload ?? _createAttachmentUploadWithFirebase;
    final upload = await createUpload(type);
    final bytes = await document.loadBytes();
    await (_uploadFile ?? _uploadFileToStorage)(upload, bytes);
    await (_confirmAttachment ?? _confirmAttachmentWithFirebase)(
      type,
      upload.path,
    );
  }

  Future<void> _registerTrainerWithFirebase(Map<String, Object> data) async {
    await _functions.httpsCallable(_registerFunctionName).call<void>(data);
  }

  Future<void> _authenticateWithFirebase(String email, String password) async {
    final result = await _functions.httpsCallable(_loginFunctionName).call({
      'email': email,
      'senha': password,
    });
    final data = _asMap(result.data);
    final customToken = data['customToken'];
    if (customToken is! String || customToken.isEmpty) {
      throw const RegistrationFailure('Não foi possível autenticar a conta.');
    }
    await FirebaseAuth.instance.signInWithCustomToken(customToken);
  }

  Future<TrainerAttachmentUpload> _createAttachmentUploadWithFirebase(
    TrainerAttachmentType type,
  ) async {
    final result = await _functions
        .httpsCallable(_createUploadFunctionName)
        .call({'tipo': type.value});
    final data = _asMap(result.data);
    final path = data['caminho'];
    final url = data['uploadUrl'];
    final rawHeaders = data['headers'];
    if (path is! String || url is! String || rawHeaders is! Map) {
      throw const RegistrationFailure(
        'O servidor não preparou o envio do documento.',
      );
    }

    return TrainerAttachmentUpload(
      path: path,
      url: url,
      headers: rawHeaders.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
  }

  Future<void> _uploadFileToStorage(
    TrainerAttachmentUpload upload,
    Uint8List bytes,
  ) async {
    final response = await http.put(
      Uri.parse(upload.url),
      headers: upload.headers,
      body: bytes,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const RegistrationFailure(
        'O Storage recusou o envio de um documento.',
      );
    }
  }

  Future<void> _confirmAttachmentWithFirebase(
    TrainerAttachmentType type,
    String path,
  ) async {
    await _functions.httpsCallable(_confirmUploadFunctionName).call<void>({
      'tipo': type.value,
      'caminho': path,
    });
  }

  Future<void> _signOutFromFirebase() {
    return FirebaseAuth.instance.signOut();
  }

  Map<Object?, Object?> _asMap(Object? value) {
    if (value is Map<Object?, Object?>) return value;
    throw const RegistrationFailure('Resposta inválida do servidor.');
  }

  RegistrationFailure _mapRegistrationFailure(
    FirebaseFunctionsException error,
  ) {
    return switch (error.code) {
      'already-exists' => const RegistrationFailure('E-mail já cadastrado.'),
      'invalid-argument' => RegistrationFailure(
        error.message ?? 'Dados de cadastro inválidos.',
      ),
      _ => const RegistrationFailure.connection(),
    };
  }
}
