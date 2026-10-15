// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da etapa de senha do cadastro.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_text_form_field.dart';
import '../../application/controllers/registration_controller.dart';
import '../../application/states/registration_draft.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_next_button.dart';
import '../widgets/registration_progress_indicator.dart';
import 'guardian_confirmation_screen.dart';

typedef RegistrationPasswordCallback =
    void Function(RegistrationDraft registration, String password);

// Terceira etapa do cadastro de responsável, com validação reativa da senha.
class RegistrationPasswordScreen extends StatefulWidget {
  const RegistrationPasswordScreen({
    required this.registration,
    this.registrationController,
    this.onContinue,
    this.onBack,
    super.key,
  });

  // Dados não sensíveis, dependência de submissão e callbacks do fluxo.
  final RegistrationDraft registration;
  final RegistrationController? registrationController;
  final RegistrationPasswordCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<RegistrationPasswordScreen> createState() =>
      _RegistrationPasswordScreenState();
}

class _RegistrationPasswordScreenState
    extends State<RegistrationPasswordScreen> {
  // Formulário e controladores que mantêm a senha somente durante esta rota.
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();

  // Estados visuais e draft não sensível recebido das etapas anteriores.
  bool _isPasswordVisible = false;
  bool _isConfirmationVisible = false;
  late final RegistrationDraft _registration = widget.registration;

  // Critérios reativos recalculados a cada alteração do campo principal.
  String get _password => _passwordController.text;

  bool get _hasValidLength => _password.length >= 8 && _password.length <= 30;
  bool get _hasLowercase => RegExp(r'[a-z]').hasMatch(_password);
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(_password);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_password);
  bool get _hasSpecialCharacter =>
      RegExp(r'[^A-Za-z0-9\s]').hasMatch(_password);

  bool get _meetsAllRequirements =>
      _hasValidLength &&
      _hasLowercase &&
      _hasUppercase &&
      _hasNumber &&
      _hasSpecialCharacter;

  @override
  void dispose() {
    // Libera os controladores e suas referências transitórias à senha.
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  // Valida os requisitos e a igualdade exata da confirmação.
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Informe uma senha.';
    if (!_meetsAllRequirements) {
      return 'Atenda a todos os requisitos da senha.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) return 'Confirme sua senha.';
    if (value != _password) return 'As senhas não coincidem.';
    return null;
  }

  // Retorno da etapa com suporte a callback em testes.
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  // Envia a senha separada do draft e substitui esta rota pela confirmação.
  // A confirmação fornece um caminho explícito de volta para esta etapa.
  void _continue() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final password = _password;
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(_registration, password);
      return;
    }

    Navigator.pushReplacement<void, void>(
      context,
      MaterialPageRoute<void>(
        builder: (confirmationContext) => GuardianConfirmationScreen(
          registration: _registration,
          password: password,
          registrationController: widget.registrationController,
          onEditPassword: (updatedRegistration) {
            Navigator.pushReplacement<void, void>(
              confirmationContext,
              MaterialPageRoute<void>(
                builder: (context) => RegistrationPasswordScreen(
                  registration: updatedRegistration,
                  registrationController: widget.registrationController,
                ),
              ),
            );
          },
        ),
      ),
    );

    _passwordController.clear();
    _confirmationController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(onBack: _goBack),
                    const SizedBox(height: 44),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Terceiro passo do cadastro de responsável.
                            const RegistrationProgressIndicator(
                              configuration:
                                  RegistrationProgressConfiguration.guardian,
                              currentStep: 3,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Crie uma senha',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Quase lá, mas antes precisamos de\nproteção.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 43),
                            // Campos sensíveis, requisitos reativos e controle
                            // independente de visibilidade.
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AppTextFormField(
                                    controller: _passwordController,
                                    hintText: 'Senha',
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    obscureText: !_isPasswordVisible,
                                    textInputAction: TextInputAction.next,
                                    validator: _validatePassword,
                                    onChanged: (_) => setState(() {}),
                                    suffixIcon: _VisibilityButton(
                                      isVisible: _isPasswordVisible,
                                      onPressed: () => setState(
                                        () => _isPasswordVisible =
                                            !_isPasswordVisible,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Ela deve conter:',
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _PasswordRequirement(
                                    label: 'de 8 a 30 caracteres',
                                    isMet: _hasValidLength,
                                  ),
                                  _PasswordRequirement(
                                    label: '1 caractere minúsculo',
                                    isMet: _hasLowercase,
                                  ),
                                  _PasswordRequirement(
                                    label: '1 caractere maiúsculo',
                                    isMet: _hasUppercase,
                                  ),
                                  _PasswordRequirement(
                                    label: '1 número',
                                    isMet: _hasNumber,
                                  ),
                                  _PasswordRequirement(
                                    label: '1 caractere especial',
                                    isMet: _hasSpecialCharacter,
                                  ),
                                  const SizedBox(height: 38),
                                  AppTextFormField(
                                    controller: _confirmationController,
                                    hintText: 'Confirmação da senha',
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    obscureText: !_isConfirmationVisible,
                                    textInputAction: TextInputAction.done,
                                    validator: _validateConfirmation,
                                    onFieldSubmitted: (_) => _continue(),
                                    suffixIcon: _VisibilityButton(
                                      isVisible: _isConfirmationVisible,
                                      onPressed: () => setState(
                                        () => _isConfirmationVisible =
                                            !_isConfirmationVisible,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-registration-password',
                              ),
                              onPressed: _continue,
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _PasswordRequirement extends StatelessWidget {
  const _PasswordRequirement({required this.label, required this.isMet});

  final String label;
  final bool isMet;

  @override
  Widget build(BuildContext context) {
    // Cor e ícone comunicam imediatamente se o critério foi atendido.
    final color = isMet ? AppColors.seaGreen : AppColors.error;

    return Row(
      children: [
        Icon(
          isMet ? Icons.check_rounded : Icons.close_rounded,
          key: Key('password-requirement-${isMet ? 'met' : 'unmet'}-$label'),
          color: color,
          size: 22,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontSize: 18,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _VisibilityButton extends StatelessWidget {
  const _VisibilityButton({required this.isVisible, required this.onPressed});

  final bool isVisible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // Alterna somente a representação visual; o valor não é persistido.
    return IconButton(
      onPressed: onPressed,
      tooltip: isVisible ? 'Ocultar senha' : 'Mostrar senha',
      icon: Icon(
        isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
      ),
    );
  }
}
