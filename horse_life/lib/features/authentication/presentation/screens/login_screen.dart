// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da tela de login responsiva com validação, controle de
// senha, submissão assíncrona, timeout, mensagens centralizadas e tratamento
// de credenciais incorretas ou falhas de conexão com a SnackBar genérica e
// reutilizável da aplicação.
// Futuramente, haverá no backend uma callable chamada `login`; como ela ainda
// não existe, este código deverá ser reajustado quando a Function for criada.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_text_form_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../messages/authentication_error_messages.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_link.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.onBack,
    this.onForgotPassword,
    this.login,
    this.onSignUp,
    super.key,
  });

  final VoidCallback? onBack;
  final VoidCallback? onForgotPassword;
  final Future<bool> Function(String email, String password)? login;
  final VoidCallback? onSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _backgroundColor = Color(0xFFFAFAFA);
  static const _errorSnackBarColor = Color(0xFFAA0000);
  static const _loginTimeout = Duration(seconds: 10);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    // Libera os recursos pertencentes ao estado da tela.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Informe sua senha.';
    return null;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    AppSnackBar.show(
      context,
      backgroundColor: _errorSnackBarColor,
      icon: Icons.error,
      message: message,
    );
  }

  Future<void> _submit() async {
    // Fecha o teclado e impede envio inválido ou duplicado.
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final login = widget.login;
    if (login == null) {
      _showSnackBar(AuthenticationErrorMessages.serverConnection);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final isAuthenticated = await login(
        _emailController.text.trim(),
        _passwordController.text,
      ).timeout(_loginTimeout);

      if (!isAuthenticated) {
        _showSnackBar(AuthenticationErrorMessages.invalidCredentials);
      }
    } on TimeoutException {
      _showSnackBar(AuthenticationErrorMessages.serverConnection);
    } catch (_) {
      _showSnackBar(AuthenticationErrorMessages.serverConnection);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Permite rolagem com teclado aberto e preserva a composição em telas
    // maiores.
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(32, 18, 32, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 50,
                ),
                child: Column(
                  children: [
                    AuthHeader(onBack: _goBack),
                    const SizedBox(height: 80),
                    const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Leage Spartan',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'É muito bom te ter de volta!\nPronto para mais um?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        height: 1.25,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'Urbanist',
                      ),
                    ),
                    const SizedBox(height: 48),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppTextFormField(
                                controller: _emailController,
                                hintText: 'E-mail',
                                autofillHints: const [AutofillHints.email],
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 10),
                              AppTextFormField(
                                controller: _passwordController,
                                hintText: 'Senha',
                                autofillHints: const [AutofillHints.password],
                                obscureText: !_isPasswordVisible,
                                textInputAction: TextInputAction.done,
                                validator: _validatePassword,
                                onFieldSubmitted: (_) => _submit(),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _isPasswordVisible =
                                        !_isPasswordVisible,
                                  ),
                                  tooltip: _isPasswordVisible
                                      ? 'Ocultar senha'
                                      : 'Mostrar senha',
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AuthLink(
                                  label: 'Esqueci minha senha',
                                  onPressed: widget.onForgotPassword ?? () {},
                                ),
                              ),
                              const SizedBox(height: 20),
                              GradientButton(
                                label: 'Entrar',
                                isLoading: _isSubmitting,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 22),
                              const Text(
                                'Ainda não possui uma conta?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Urbanist',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Align(
                                child: AuthLink(
                                  label: 'Cadastre-se',
                                  onPressed: widget.onSignUp ?? () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
