// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do estado específico do perfil selecionado e encadeamento
// do primeiro passo do treinador à etapa de e-mail, preservando a configuração
// de oito passos.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da primeira etapa de identificação do cadastro.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_text_form_field.dart';
import '../../application/controllers/registration_controller.dart';
import '../../application/states/registration_draft.dart';
import '../../data/models/user_type.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_next_button.dart';
import '../widgets/registration_progress_indicator.dart';
import 'registration_email_screen.dart';

typedef RegistrationNameCallback =
    void Function(String firstName, String lastName);

// Primeira etapa compartilhável dos cadastros, parametrizada pelo fluxo ativo.
class RegistrationNameScreen extends StatefulWidget {
  const RegistrationNameScreen.guardian({
    this.onContinue,
    this.onBack,
    this.registrationController,
    super.key,
  }) : userType = UserType.guardian,
       progressConfiguration = RegistrationProgressConfiguration.guardian;

  const RegistrationNameScreen.trainer({
    this.onContinue,
    this.onBack,
    this.registrationController,
    super.key,
  }) : userType = UserType.trainer,
       progressConfiguration = RegistrationProgressConfiguration.trainer;

  // Tipo, progresso e dependências definidos pelo coordenador do fluxo.
  final UserType userType;
  final RegistrationProgressConfiguration progressConfiguration;
  final RegistrationController? registrationController;
  final RegistrationNameCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<RegistrationNameScreen> createState() => _RegistrationNameScreenState();
}

class _RegistrationNameScreenState extends State<RegistrationNameScreen> {
  // Estado e controladores dos dois campos da primeira etapa.
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  // Impede o avanço com nomes vazios ou compostos apenas por espaços.
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Preencha este campo.';
    }
    return null;
  }

  // Retorno injetável com fallback para o Navigator.
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  // Normaliza os nomes e cria o draft inicial do fluxo selecionado.
  void _continue() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final onContinue = widget.onContinue;

    if (onContinue != null) {
      onContinue(firstName, lastName);
      return;
    }

    final registration = switch (widget.userType) {
      UserType.guardian => GuardianRegistrationDraft(
        firstName: firstName,
        lastName: lastName,
      ),
      UserType.trainer => TrainerRegistrationDraft(
        firstName: firstName,
        lastName: lastName,
      ),
    };

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => RegistrationEmailScreen(
          registration: registration,
          registrationController: widget.registrationController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

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
                            // Indicador parametrizado para o primeiro passo.
                            RegistrationProgressIndicator(
                              configuration: widget.progressConfiguration,
                              currentStep: 1,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Como você se chama?',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Informe como quer ser\nchamado(a).',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 43),
                            // Coleta dos nomes com autofill e validação local.
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  AppTextFormField(
                                    controller: _firstNameController,
                                    hintText: 'Primeiro nome',
                                    autofillHints: const [
                                      AutofillHints.givenName,
                                    ],
                                    keyboardType: TextInputType.name,
                                    textInputAction: TextInputAction.next,
                                    validator: _validateName,
                                  ),
                                  const SizedBox(height: 28),
                                  AppTextFormField(
                                    controller: _lastNameController,
                                    hintText: 'Sobrenome',
                                    autofillHints: const [
                                      AutofillHints.familyName,
                                    ],
                                    keyboardType: TextInputType.name,
                                    textInputAction: TextInputAction.done,
                                    validator: _validateName,
                                    onFieldSubmitted: (_) => _continue(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-registration-name',
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
