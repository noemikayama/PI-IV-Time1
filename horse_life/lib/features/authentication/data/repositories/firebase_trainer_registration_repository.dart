// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos e segmentos do código de autenticação,
// detalhando responsabilidades, fluxo de dados e integração entre camadas.
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

// Categorias aceitas pelas callables de preparação e confirmação de anexos.
enum TrainerAttachmentType {
  experience('experiencias'),
  certification('certificacoes');

  const TrainerAttachmentType(this.value);

  final String value;
}

// Credenciais temporárias de upload devolvidas pelo backend. A URL assinada
// permite enviar o PDF ao Storage sem expor permissões permanentes no cliente.
class TrainerAttachmentUpload {
  const TrainerAttachmentUpload({
    required this.path,
    required this.url,
    required this.headers,
  });

  // Caminho definitivo, endpoint temporário e cabeçalhos exigidos pelo Storage.
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

  // O cadastro possui duas fases independentes:
  // 1. criação da conta e dos dados profissionais pela callable;
  // 2. autenticação temporária e upload de cada documento selecionado.
  // Falhas da segunda fase informam que a conta já existe para impedir uma
  // nova tentativa de cadastro com o mesmo e-mail.
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

    // Valida tudo localmente antes de criar uma conta que não possa ser enviada.
    _validateDocuments(registration);
    final data = _buildRegistrationData(registration, password);

    // Primeira fase: persiste a conta e os campos profissionais estruturados.
    try {
      await (_registerTrainer ?? _registerTrainerWithFirebase)(data);
    } on RegistrationFailure {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      throw _mapRegistrationFailure(error);
    } catch (_) {
      throw const RegistrationFailure.connection();
    }

    // Sem anexos, a conta já está completa e nenhuma sessão temporária é aberta.
    final documents = _documentsFrom(registration);
    if (documents.isEmpty) return;

    // Segunda fase: o UID autenticado define os caminhos seguros do Storage.
    var isAuthenticated = false;
    try {
      await (_authenticate ?? _authenticateWithFirebase)(
        registration.email.trim(),
        password,
      );
      isAuthenticated = true;

      // O envio sequencial facilita identificar e compensar uma falha parcial.
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
      // A sessão serve apenas ao upload; o cadastro termina desautenticado e a
      // pessoa usuária segue para o login explícito.
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
    // Modalidade é obrigatória para o perfil treinador e já deve ter sido
    // coletada na terceira etapa do fluxo.
    final sport = registration.sport?.trim();
    if (sport == null || sport.isEmpty) {
      throw const RegistrationFailure('Selecione uma modalidade.');
    }

    // A senha nunca é armazenada no draft: entra no payload apenas neste ponto.
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
    // O mapa usa estado+cidade como chave para remover sobreposições produzidas
    // pela expansão de regiões e estados inteiros.
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

    // O backend recebe somente estado/cidade. Abrangências maiores são
    // expandidas para todas as UFs correspondentes usando "Todas as cidades".
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

    // O limite é aplicado depois da expansão, que representa o payload real.
    if (serialized.length > 30) {
      throw const RegistrationFailure(
        'Selecione no máximo 30 regiões de atendimento.',
      );
    }
    return serialized.values.toList(growable: false);
  }

  void _validateDocuments(TrainerRegistrationDraft registration) {
    // Revalida quantidade, extensão e tamanho na boundary remota, mesmo que as
    // telas já tenham bloqueado seleções inválidas.
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
    // Associa cada arquivo ao diretório reconhecido pelas callables de anexo.
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
    // Protocolo de três passos: obter URL assinada, transferir bytes e confirmar
    // o caminho para que o backend associe o anexo ao treinador.
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
    // A callable cria Authentication e dados de domínio de forma coordenada.
    await _functions.httpsCallable(_registerFunctionName).call<void>(data);
  }

  Future<void> _authenticateWithFirebase(String email, String password) async {
    // Reutiliza o login do projeto para obter uma sessão curta de upload.
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
    // O backend escolhe o caminho e assina a URL; o cliente não monta chaves.
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
    // A transferência ocorre diretamente para a URL assinada recebida.
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
    // Somente após o PUT bem-sucedido o caminho é persistido no cadastro.
    await _functions.httpsCallable(_confirmUploadFunctionName).call<void>({
      'tipo': type.value,
      'caminho': path,
    });
  }

  Future<void> _signOutFromFirebase() {
    // Encerra a autenticação temporária criada exclusivamente para anexos.
    return FirebaseAuth.instance.signOut();
  }

  Map<Object?, Object?> _asMap(Object? value) {
    // Evita acessar campos de respostas que não atendem ao contrato remoto.
    if (value is Map<Object?, Object?>) return value;
    throw const RegistrationFailure('Resposta inválida do servidor.');
  }

  RegistrationFailure _mapRegistrationFailure(
    FirebaseFunctionsException error,
  ) {
    // Apenas conflitos e argumentos inválidos têm mensagens acionáveis; os
    // demais códigos são tratados como indisponibilidade.
    return switch (error.code) {
      'already-exists' => const RegistrationFailure('E-mail já cadastrado.'),
      'invalid-argument' => RegistrationFailure(
        error.message ?? 'Dados de cadastro inválidos.',
      ),
      _ => const RegistrationFailure.connection(),
    };
  }
}
