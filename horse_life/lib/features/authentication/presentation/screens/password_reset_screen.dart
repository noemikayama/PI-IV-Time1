// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da tela responsiva de recuperação de senha, com validação
// de e-mail, submissão assíncrona, timeout, erros e confirmação em modal.
// Retorno automático ao login após a confirmação do e-mail enviado.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/app_text_form_field.dart';
import '../../application/controllers/password_reset_controller.dart';
import '../../data/repositories/password_reset_repository.dart';
import '../messages/authentication_error_messages.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_next_button.dart';

// Coleta o e-mail e apresenta os estados visuais do pedido de recuperação.
class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({required this.controller, super.key});

  final PasswordResetController controller;

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  // Evita manter a interface bloqueada indefinidamente em falhas de rede.
  static const _requestTimeout = Duration(seconds: 10);

  // Estado e recursos pertencentes ao formulário.
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Replica localmente as restrições básicas aceitas pelo backend.
  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (email.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  void _goBack() {
    Navigator.maybePop(context);
  }

  // Apresenta falhas remotas no componente padronizado da aplicação.
  void _showError(String message) {
    if (!mounted) return;
    AppSnackBar.show(
      context,
      backgroundColor: Theme.of(context).colorScheme.error,
      icon: Icons.error,
      message: message,
    );
  }

  // Valida, bloqueia envios duplicados e coordena os estados da operação.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.controller
          .requestPasswordReset(_emailController.text.trim())
          .timeout(_requestTimeout);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showEmailSentDialog();
      if (mounted) _goBack();
    } on PasswordResetFailure catch (error) {
      _showError(error.message);
    } on TimeoutException {
      _showError(AuthenticationErrorMessages.serverConnection);
    } catch (_) {
      _showError(AuthenticationErrorMessages.serverConnection);
    } finally {
      if (mounted && _isSubmitting) setState(() => _isSubmitting = false);
    }
  }

  // Confirma o envio sem revelar se existe uma conta para o e-mail informado.
  Future<void> _showEmailSentDialog() {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'E-mail enviado',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: 28),
                Text(
                  'Verifique sua caixa de entrada para redefinir sua senha '
                  '(não se esqueça de verificar o Spam).',
                  style: theme.textTheme.headlineSmall?.copyWith(height: 1.25),
                ),
                const SizedBox(height: 28),
                AuthNextButton(
                  buttonKey: const Key('confirm-password-reset'),
                  label: 'Ok',
                  showArrow: false,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Estrutura rolável para preservar o conteúdo com teclado ou telas menores.
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 18, 32, 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 50,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(onBack: _goBack),
                  const SizedBox(height: 80),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Recuperação de senha',
                            textAlign: TextAlign.center,
                            style: textTheme.displaySmall,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Insira o e-mail utilizado em seu cadastro para '
                            'enviarmos um link de recuperação de senha.',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Form(
                            key: _formKey,
                            child: AppTextFormField(
                              controller: _emailController,
                              hintText: 'E-mail',
                              autofillHints: const [AutofillHints.email],
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.done,
                              validator: _validateEmail,
                              onFieldSubmitted: (_) => _submit(),
                            ),
                          ),
                          const SizedBox(height: 50),
                          AuthNextButton(
                            buttonKey: const Key('request-password-reset'),
                            isLoading: _isSubmitting,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
