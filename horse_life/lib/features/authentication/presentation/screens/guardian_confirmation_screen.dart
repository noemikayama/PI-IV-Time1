// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 16/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Substituição de ValueChanged<GuardianRegistrationDraft> pelo
// typedef GuardianPasswordEditRequested na solicitação de edição da senha.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Restrição da confirmação ao estado de responsável.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da revisão editável, tratamento transitório da senha e
// contrato de submissão do cadastro. A integração com Firebase Functions ainda
// não foi implementada.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../application/controllers/registration_controller.dart';
import '../../application/states/registration_draft.dart';
import '../messages/authentication_error_messages.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_next_button.dart';
import '../widgets/editable_review_field.dart';
import '../widgets/registration_progress_indicator.dart';

typedef GuardianPasswordEditRequested =
    void Function(GuardianRegistrationDraft registration);

// Última etapa do cadastro. A senha é mantida somente durante esta rota e
// entregue diretamente ao controller no momento da submissão.
class GuardianConfirmationScreen extends StatefulWidget {
  const GuardianConfirmationScreen({
    required this.registration,
    required this.password,
    this.registrationController,
    this.onCreated,
    this.onBack,
    this.onEditPassword,
    super.key,
  });

  // Entrada do fluxo, dependências opcionais e efeitos externos da tela.
  final GuardianRegistrationDraft registration;
  final String password;
  final RegistrationController? registrationController;
  final VoidCallback? onCreated;
  final VoidCallback? onBack;
  final GuardianPasswordEditRequested? onEditPassword;

  @override
  State<GuardianConfirmationScreen> createState() =>
      _GuardianConfirmationScreenState();
}

class _GuardianConfirmationScreenState
    extends State<GuardianConfirmationScreen> {
  // Estado do formulário de revisão e cópias editáveis dos dados recebidos.
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  // Focos pertencentes à tela para ativar cada edição no próprio campo.
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final Set<_ReviewFieldId> _editingFields = {};

  // Estados exclusivamente visuais e de submissão.
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.registration.firstName,
    );
    _lastNameController = TextEditingController(
      text: widget.registration.lastName,
    );
    _emailController = TextEditingController(text: widget.registration.email);
    _passwordController = TextEditingController(text: widget.password);
  }

  @override
  void dispose() {
    // Remove primeiro a senha transitória e depois libera os recursos locais.
    _passwordController.clear();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  // Alterna a edição inline dos campos não sensíveis e transfere o foco.
  void _toggleEditing(_ReviewFieldId field) {
    if (_editingFields.contains(field)) {
      setState(() => _editingFields.remove(field));
      _focusFor(field).unfocus();
      return;
    }

    setState(() => _editingFields.add(field));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusFor(field).requestFocus();
    });
  }

  FocusNode _focusFor(_ReviewFieldId field) {
    return switch (field) {
      _ReviewFieldId.firstName => _firstNameFocus,
      _ReviewFieldId.lastName => _lastNameFocus,
      _ReviewFieldId.email => _emailFocus,
    };
  }

  // Validações reaplicadas depois de qualquer alteração feita na revisão.
  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) return 'Preencha este campo.';
    return null;
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
    final password = value ?? '';
    final isValid =
        password.length >= 8 &&
        password.length <= 30 &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[^A-Za-z0-9\s]').hasMatch(password);

    if (!isValid) return 'Informe uma senha que atenda aos requisitos.';
    return null;
  }

  // Devolve os dados revisados ao fluxo e abre novamente a etapa que contém
  // todos os requisitos e a confirmação da senha.
  void _editPassword() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final updatedRegistration = widget.registration.copyWithContact(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
    );

    final onEditPassword = widget.onEditPassword;
    if (onEditPassword != null) {
      onEditPassword(updatedRegistration);
      return;
    }
    Navigator.maybePop(context);
  }

  // Entrega dados e senha separadamente ao controller injetado. Na ausência de
  // implementação, informa indisponibilidade sem simular integração Firebase.
  Future<void> _createAccount() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final controller = widget.registrationController;
    if (controller == null) {
      _showConnectionError();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await controller.createAccount(
        registration: widget.registration.copyWithContact(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
        ),
        password: _passwordController.text,
      );
      _passwordController.clear();
      if (!mounted) return;
      widget.onCreated?.call();
    } catch (_) {
      if (mounted) _showConnectionError();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showConnectionError() {
    AppSnackBar.show(
      context,
      backgroundColor: Theme.of(context).colorScheme.error,
      icon: Icons.error,
      message: AuthenticationErrorMessages.serverConnection,
    );
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
                            const RegistrationProgressIndicator(
                              configuration:
                                  RegistrationProgressConfiguration.guardian,
                              currentStep: 4,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Revise seus dados',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Este é o último passo até o\nHorseLife.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 50),
                            // Campos de revisão: edição inline para dados
                            // comuns e edição externa para a senha.
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  EditableReviewField(
                                    fieldKey: const Key('review-first-name'),
                                    label: 'Primeiro nome',
                                    controller: _firstNameController,
                                    focusNode: _firstNameFocus,
                                    isEditing: _editingFields.contains(
                                      _ReviewFieldId.firstName,
                                    ),
                                    validator: _validateRequired,
                                    textInputAction: TextInputAction.next,
                                    onToggleEditing: () => _toggleEditing(
                                      _ReviewFieldId.firstName,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  EditableReviewField(
                                    fieldKey: const Key('review-last-name'),
                                    label: 'Sobrenome',
                                    controller: _lastNameController,
                                    focusNode: _lastNameFocus,
                                    isEditing: _editingFields.contains(
                                      _ReviewFieldId.lastName,
                                    ),
                                    validator: _validateRequired,
                                    textInputAction: TextInputAction.next,
                                    onToggleEditing: () =>
                                        _toggleEditing(_ReviewFieldId.lastName),
                                  ),
                                  const SizedBox(height: 24),
                                  EditableReviewField(
                                    fieldKey: const Key('review-email'),
                                    label: 'E-mail',
                                    controller: _emailController,
                                    focusNode: _emailFocus,
                                    isEditing: _editingFields.contains(
                                      _ReviewFieldId.email,
                                    ),
                                    validator: _validateEmail,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    onToggleEditing: () =>
                                        _toggleEditing(_ReviewFieldId.email),
                                  ),
                                  const SizedBox(height: 24),
                                  EditableReviewField(
                                    fieldKey: const Key('review-password'),
                                    label: 'Senha',
                                    controller: _passwordController,
                                    focusNode: _passwordFocus,
                                    isEditing: false,
                                    obscureText: !_isPasswordVisible,
                                    validator: _validatePassword,
                                    textInputAction: TextInputAction.done,
                                    onToggleEditing: _editPassword,
                                    externalEdit: true,
                                    leadingAction: IconButton(
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
                                        color: AppColors.seaGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 50),
                            // Submissão final com bloqueio durante o envio.
                            AuthNextButton(
                              buttonKey: const Key(
                                'create-registration-account',
                              ),
                              label: 'Criar conta',
                              showArrow: false,
                              isLoading: _isSubmitting,
                              onPressed: _createAccount,
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

// Identifica os campos que podem ser editados sem abandonar a revisão.
enum _ReviewFieldId { firstName, lastName, email }
