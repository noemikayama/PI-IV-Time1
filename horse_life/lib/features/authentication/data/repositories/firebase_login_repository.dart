// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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

class AuthenticatedIdentity {
  const AuthenticatedIdentity({required this.uid, required this.roleClaim});

  final String uid;
  final Object? roleClaim;
}

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

  @override
  Future<LoginSession> authenticate({
    required String email,
    required String password,
  }) async {
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
    final result = await FirebaseFunctions.instanceFor(
      region: _region,
    ).httpsCallable(_functionName).call<Object?>(credentials);
    return result.data;
  }

  Future<AuthenticatedIdentity> _authenticateFirebase(
    String customToken,
  ) async {
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
    try {
      await (_signOut ?? FirebaseAuth.instance.signOut)();
    } catch (_) {
      // Uma falha de limpeza não substitui o erro original do login.
    }
  }

  Map<Object?, Object?> _asMap(Object? value) {
    if (value is Map<Object?, Object?>) return value;
    throw const LoginFailure('Resposta de login inválida.');
  }

  LoginFailure _mapFunctionFailure(FirebaseFunctionsException error) {
    return switch (error.code) {
      'unauthenticated' => const LoginFailure.invalidCredentials(),
      'invalid-argument' || 'not-found' || 'permission-denied' => LoginFailure(
        error.message ?? 'Não foi possível autenticar esta conta.',
      ),
      _ => const LoginFailure.connection(),
    };
  }
}
