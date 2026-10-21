// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração da submissão com uma sessão autenticada tipada,
// tratamento das falhas do repositório e fechamento da rota após o sucesso.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Ajuste do espaçamento entre o título e a mensagem de boas-vindas.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Substituição de cores, fontes e estilos locais pelos papéis
// semânticos de TextTheme, ColorScheme e pelos temas globais de componentes.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da tela de login responsiva com validação, controle de
// senha, submissão assíncrona, timeout, mensagens centralizadas e tratamento
// de credenciais incorretas ou falhas de conexão com a SnackBar genérica e
// reutilizável da aplicação.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_text_form_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../application/states/login_session.dart';
import '../../data/repositories/login_repository.dart';
import '../messages/authentication_error_messages.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_link.dart';

typedef LoginOperation =
    Future<LoginSession> Function(String email, String password);

// Tela responsável pela entrada das credenciais e pela apresentação dos
// estados locais do login, com aparência herdada do tema institucional.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    this.onBack,
    this.onForgotPassword,
    this.login,
    this.onSignUp,
    super.key,
  });

  // Ações externas e contratos injetáveis do fluxo de login.
  final VoidCallback? onBack;
  final VoidCallback? onForgotPassword;
  final LoginOperation? login;
  final VoidCallback? onSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Limite de espera da operação remota.
  static const _loginTimeout = Duration(seconds: 10);

  // Estado e controladores pertencentes ao formulário.
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Sinalizadores usados para alternar a senha e proteger contra envios
  // duplicados.
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;

  // Liberação dos recursos criados e mantidos pela tela.
  @override
  void dispose() {
    // Libera os recursos pertencentes ao estado da tela.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validação local das credenciais antes de qualquer tentativa de envio.
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

  // Apresentação padronizada dos erros específicos deste fluxo.
  void _showSnackBar(String message) {
    if (!mounted) return;

    AppSnackBar.show(
      context,
      backgroundColor: Theme.of(context).colorScheme.error,
      icon: Icons.error,
      message: message,
    );
  }

  // Submissão assíncrona e tradução dos possíveis resultados em feedback
  // visual para a pessoa usuária.
  Future<void> _submit() async {
    // Fecha o teclado e impede envio inválido ou duplicado.
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    // A ausência de uma operação configurada é tratada como indisponibilidade.
    final login = widget.login;
    if (login == null) {
      _showSnackBar(AuthenticationErrorMessages.serverConnection);
      return;
    }

    // Mantém o botão bloqueado até sucesso, falha ou expiração do timeout.
    setState(() => _isSubmitting = true);
    try {
      await login(
        _emailController.text.trim(),
        _passwordController.text,
      ).timeout(_loginTimeout);
      _passwordController.clear();
      TextInput.finishAutofillContext();
      if (!mounted) return;
      Navigator.maybePop(context);
    } on LoginFailure catch (error) {
      _showSnackBar(error.message);
    } on TimeoutException {
      _showSnackBar(AuthenticationErrorMessages.serverConnection);
    } catch (_) {
      _showSnackBar(AuthenticationErrorMessages.serverConnection);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Navegação de retorno injetável, com fallback para a pilha atual.
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  // Estrutura responsiva da tela.
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Permite rolagem com teclado aberto e preserva a composição em telas
    // maiores.
    return Scaffold(
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
                    // Cabeçalho e apresentação do fluxo.
                    AuthHeader(onBack: _goBack),
                    const SizedBox(height: 80),
                    Text('Login', style: textTheme.displaySmall),
                    const SizedBox(height: 24),
                    Text(
                      'É muito bom te ter de volta!\nPronto para mais um?',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 48),
                    // Formulário de credenciais e ações relacionadas.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Entrada e validação do e-mail.
                              AppTextFormField(
                                controller: _emailController,
                                hintText: 'E-mail',
                                autofillHints: const [AutofillHints.email],
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 10),
                              // Entrada da senha e controle de visibilidade.
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
                              // Ações secundárias do fluxo de autenticação.
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AuthLink(
                                  label: 'Esqueci minha senha',
                                  onPressed: widget.onForgotPassword ?? () {},
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Ação principal, refletindo o estado de envio.
                              GradientButton(
                                label: 'Entrar',
                                isLoading: _isSubmitting,
                                onPressed: _submit,
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'Ainda não possui uma conta?',
                                textAlign: TextAlign.center,
                                style: textTheme.labelMedium,
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
