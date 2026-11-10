// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de estado, validação, mensagens, operações
// assíncronas e composição do formulário.
//
// Data: 04/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da tela de edição do perfil do responsável, com alteração
// de nome, e-mail somente leitura e solicitação de redefinição de senha.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/app_text_form_field.dart';
import 'package:horse_life/features/authentication/data/repositories/password_reset_repository.dart';
import 'package:horse_life/features/authentication/presentation/widgets/auth_header.dart';
import 'package:horse_life/features/profile/application/controllers/guardian_profile_controller.dart';
import 'package:horse_life/features/profile/data/models/guardian_profile_data.dart';

/// Formulário de edição dos dados que o backend permite alterar.
class GuardianProfileEditScreen extends StatefulWidget {
  const GuardianProfileEditScreen({
    required this.profile,
    required this.controller,
    super.key,
  });

  final GuardianProfileData profile;
  final GuardianProfileController controller;

  @override
  State<GuardianProfileEditScreen> createState() =>
      _GuardianProfileEditScreenState();
}

class _GuardianProfileEditScreenState extends State<GuardianProfileEditScreen> {
  // --- Estado do formulário --------------------------------------------------
  // Limita operações remotas para que a interface não permaneça bloqueada.
  static const _requestTimeout = Duration(seconds: 10);

  // Chave, focos e controladores pertencem ao ciclo de vida desta tela.
  final _formKey = GlobalKey<FormState>();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  bool _isSaving = false;
  bool _isRequestingPasswordReset = false;

  // --- Inicialização e descarte ---------------------------------------------
  @override
  void initState() {
    super.initState();
    final nameParts = _splitName(widget.profile.name);
    _firstNameController = TextEditingController(text: nameParts.$1);
    _lastNameController = TextEditingController(text: nameParts.$2);
    _emailController = TextEditingController(text: widget.profile.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    super.dispose();
  }

  // --- Normalização e validação ---------------------------------------------
  // Separa somente o primeiro termo; o restante permanece como sobrenome.
  (String, String) _splitName(String fullName) {
    final normalized = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
    final separator = normalized.indexOf(' ');
    if (separator < 0) return (normalized, '');
    return (
      normalized.substring(0, separator),
      normalized.substring(separator + 1),
    );
  }

  /// Impede o envio de partes vazias do nome.
  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Preencha este campo.';
    return null;
  }

  // --- Mensagens ao usuário -------------------------------------------------
  // Traduz falhas conhecidas e usa uma mensagem segura para erros inesperados.
  void _showError(Object error) {
    var message = 'Não foi possível concluir a operação. Tente novamente.';
    if (error is PasswordResetFailure) {
      message = error.message;
    } else if (error is FirebaseFunctionsException &&
        error.message?.trim().isNotEmpty == true) {
      message = error.message!.trim();
    }
    AppSnackBar.show(
      context,
      backgroundColor: Theme.of(context).colorScheme.error,
      icon: Icons.error_outline_rounded,
      message: message,
    );
  }

  // Explica por que o e-mail aparece bloqueado no formulário.
  Future<void> _showEmailInformation() {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
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
                  'Só é possível aterar o e-mail falando diretamente com o '
                  'Suporte.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(height: 1.25),
                ),
                const SizedBox(height: 28),
                OutlinedButton(
                  key: const Key('guardian-email-information-ok'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.seaGreen,
                    side: const BorderSide(color: AppColors.seaGreen, width: 2),
                    minimumSize: const Size.fromHeight(54),
                    textStyle: theme.textTheme.labelLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Ok'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Operações assíncronas ------------------------------------------------
  // Valida o formulário, bloqueia envios repetidos e retorna `true` para que a
  // tela anterior saiba que deve recarregar o perfil.
  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await widget.controller
          .updateName(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
          )
          .timeout(_requestTimeout);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on TimeoutException catch (error) {
      if (mounted) _showError(error);
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Usa sempre o e-mail original do perfil, que não é editável nesta tela.
  Future<void> _requestPasswordReset() async {
    if (_isRequestingPasswordReset) return;
    setState(() => _isRequestingPasswordReset = true);
    try {
      final message = await widget.controller
          .requestPasswordReset(widget.profile.email)
          .timeout(_requestTimeout);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.success,
        icon: Icons.mark_email_read_outlined,
        message: message,
      );
    } catch (error) {
      if (mounted) _showError(error);
    } finally {
      if (mounted) setState(() => _isRequestingPasswordReset = false);
    }
  }

  // --- Composição visual -----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 18, 32, 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 50,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthHeader(onBack: () => Navigator.maybePop(context)),
                      const SizedBox(height: 56),
                      Text(
                        'Editar perfil',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayMedium,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Corrija suas informações como preferir.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 46),
                      // Bloco de dados pessoais editáveis e informativos.
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            AppTextFormField(
                              key: const Key('guardian-edit-first-name'),
                              controller: _firstNameController,
                              focusNode: _firstNameFocus,
                              hintText: 'Primeiro nome',
                              autofillHints: const [AutofillHints.givenName],
                              textInputAction: TextInputAction.next,
                              validator: _validateName,
                              suffixIcon: IconButton(
                                tooltip: 'Editar primeiro nome',
                                onPressed: _firstNameFocus.requestFocus,
                                icon: const Icon(Icons.edit_rounded),
                              ),
                            ),
                            const SizedBox(height: 30),
                            AppTextFormField(
                              key: const Key('guardian-edit-last-name'),
                              controller: _lastNameController,
                              focusNode: _lastNameFocus,
                              hintText: 'Sobrenome',
                              autofillHints: const [AutofillHints.familyName],
                              textInputAction: TextInputAction.done,
                              validator: _validateName,
                              onFieldSubmitted: (_) => _save(),
                              suffixIcon: IconButton(
                                tooltip: 'Editar sobrenome',
                                onPressed: _lastNameFocus.requestFocus,
                                icon: const Icon(Icons.edit_rounded),
                              ),
                            ),
                            const SizedBox(height: 30),
                            AppTextFormField(
                              key: const Key('guardian-edit-email'),
                              controller: _emailController,
                              hintText: 'E-mail',
                              readOnly: true,
                              keyboardType: TextInputType.emailAddress,
                              suffixIcon: IconButton(
                                key: const Key('guardian-email-information'),
                                tooltip: 'Informações sobre o e-mail',
                                onPressed: _showEmailInformation,
                                icon: const Icon(Icons.info_outline_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 34),
                      // A redefinição de senha é uma operação independente do
                      // salvamento do nome.
                      OutlinedButton.icon(
                        key: const Key('guardian-change-password'),
                        onPressed: _isRequestingPasswordReset
                            ? null
                            : _requestPasswordReset,
                        icon: _isRequestingPasswordReset
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.key_rounded),
                        label: Text(
                          _isRequestingPasswordReset
                              ? 'Enviando...'
                              : 'Alterar senha',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.seaGreen,
                          side: const BorderSide(
                            color: AppColors.seaGreen,
                            width: 2,
                          ),
                          minimumSize: const Size.fromHeight(54),
                          textStyle: theme.textTheme.labelLarge,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      // Ação principal do formulário.
                      OutlinedButton(
                        key: const Key('guardian-save-profile'),
                        onPressed: _isSaving ? null : _save,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.seaGreen,
                          side: const BorderSide(
                            color: AppColors.seaGreen,
                            width: 2,
                          ),
                          minimumSize: const Size.fromHeight(64),
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontSize: 22,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        child: _isSaving
                            ? const SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Salvar alterações'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
