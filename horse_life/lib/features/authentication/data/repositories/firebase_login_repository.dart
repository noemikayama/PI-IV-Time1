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
// Alteração: Integração da callable de login com normalização das credenciais,
// Firebase Authentication e validação do papel presente no ID token.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../application/states/login_session.dart';
import 'login_repository.dart';

typedef LoginFunctionCall =
    Future<Object?> Function(Map<String, String> credentials);
typedef CustomTokenSignIn =
    Future<AuthenticatedIdentity> Function(String customToken);
typedef AuthenticationSignOut = Future<void> Function();

// Resultado mínimo da autenticação Firebase necessário para validar a sessão.
class AuthenticatedIdentity {
  const AuthenticatedIdentity({required this.uid, required this.roleClaim});

  final String uid;
  final Object? roleClaim;
}

// Executa o protocolo em duas fases: solicita um custom token à callable e
// autentica esse token no FirebaseAuth antes de liberar a sessão ao aplicativo.
final class FirebaseLoginRepository implements LoginRepository {
  const FirebaseLoginRepository({
    LoginFunctionCall? callLogin,
    CustomTokenSignIn? signInWithCustomToken,
    AuthenticationSignOut? signOut,
  }) : _callLogin = callLogin,
       _signInWithCustomToken = signInWithCustomToken,
       _signOut = signOut;

  static const _region = 'southamerica-east1';
  static const _functionName = 'login';

  final LoginFunctionCall? _callLogin;
  final CustomTokenSignIn? _signInWithCustomToken;
  final AuthenticationSignOut? _signOut;

  // A resposta da callable e o claim do ID token precisam concordar sobre o
  // papel. Qualquer divergência encerra a sessão recém-criada.
  @override
  Future<LoginSession> authenticate({
    required String email,
    required String password,
  }) async {
    // A normalização ocorre antes de enviar as credenciais para o backend.
    final response = await _requestLogin(email.trim().toLowerCase(), password);
    final data = _asMap(response);
    final customToken = data['customToken'];
    final name = data['nome'];
    final responseRole = AuthenticationRole.fromValue(data['role']);

    if (customToken is! String ||
        customToken.isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        responseRole == null) {
      throw const LoginFailure('Resposta de login inválida.');
    }

    // Controla se existe uma sessão parcial que precisa ser limpa em falhas.
    var didAuthenticate = false;
    try {
      final identity = await (_signInWithCustomToken ?? _authenticateFirebase)(
        customToken,
      );
      didAuthenticate = true;
      final tokenRole = AuthenticationRole.fromValue(identity.roleClaim);
      if (identity.uid.isEmpty ||
          tokenRole == null ||
          tokenRole != responseRole) {
        throw const LoginFailure(
          'Não foi possível validar as permissões da conta.',
        );
      }

      return LoginSession(
        uid: identity.uid,
        name: name.trim(),
        role: tokenRole,
      );
    } on LoginFailure {
      if (didAuthenticate) await _safeSignOut();
      rethrow;
    } on FirebaseAuthException {
      if (didAuthenticate) await _safeSignOut();
      throw const LoginFailure.connection();
    } catch (_) {
      if (didAuthenticate) await _safeSignOut();
      throw const LoginFailure.connection();
    }
  }

  Future<Object?> _requestLogin(String email, String password) async {
    // Isola falhas da callable das falhas posteriores do FirebaseAuth.
    try {
      return await (_callLogin ?? _callFirebaseFunction)({
        'email': email,
        'senha': password,
      });
    } on LoginFailure {
      rethrow;
    } on FirebaseFunctionsException catch (error) {
      throw _mapFunctionFailure(error);
    } catch (_) {
      throw const LoginFailure.connection();
    }
  }

  Future<Object?> _callFirebaseFunction(Map<String, String> credentials) async {
    // A callable centraliza a validação de credenciais e emite o custom token.
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_functionName).call<Object?>(credentials);
    return result.data;
  }

  Future<AuthenticatedIdentity> _authenticateFirebase(
    String customToken,
  ) async {
    // Força a leitura atualizada do token para não reutilizar claims antigos.
    final credential = await FirebaseAuth.instance.signInWithCustomToken(
      customToken,
    );
    final user = credential.user;
    if (user == null) {
      await _safeSignOut();
      throw const LoginFailure('Resposta de autenticação inválida.');
    }
    try {
      final token = await user.getIdTokenResult(true);
      return AuthenticatedIdentity(
        uid: user.uid,
        roleClaim: token.claims?['role'],
      );
    } catch (_) {
      await _safeSignOut();
      rethrow;
    }
  }

  Future<void> _safeSignOut() async {
    // Limpeza compensatória: nunca mascara a falha original do login.
    try {
      await (_signOut ?? FirebaseAuth.instance.signOut)();
    } catch (_) {
      // Uma falha de limpeza não substitui o erro original do login.
    }
  }

  Map<Object?, Object?> _asMap(Object? value) {
    // Rejeita respostas que não atendem ao contrato antes de acessar campos.
    if (value is Map<Object?, Object?>) return value;
    throw const LoginFailure('Resposta de login inválida.');
  }

  LoginFailure _mapFunctionFailure(FirebaseFunctionsException error) {
    // Traduz apenas códigos esperados; indisponibilidades usam erro genérico.
    return switch (error.code) {
      'unauthenticated' => const LoginFailure.invalidCredentials(),
      'invalid-argument' || 'not-found' || 'permission-denied' => LoginFailure(
        error.message ?? 'Não foi possível autenticar esta conta.',
      ),
      _ => const LoginFailure.connection(),
    };
  }
}
