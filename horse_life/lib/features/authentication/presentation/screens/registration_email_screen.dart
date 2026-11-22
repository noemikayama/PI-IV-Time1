// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Usa dependências reais por padrão e conserva injeção para testes.
//
// Data: 16/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Substituição de ValueChanged<RegistrationDraft> pelo typedef
// RegistrationEmailCallback no callback de continuidade do cadastro.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Compartilhamento da etapa com o fluxo de treinador, com progresso
// e próxima etapa definidos pelo tipo concreto do cadastro, direcionamento para
// a seleção de modalidade e padronização da dependência profissional para sport.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da etapa de e-mail do cadastro de responsável.
// -----------------------------------------------------------------------------

import 'package:horse_life/features/authentication/data/repositories/firebase_training_sport_repository.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/app_text_form_field.dart';
import '../../application/controllers/registration_controller.dart';
import '../../application/states/registration_draft.dart';
import '../../data/repositories/training_sport_repository.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_next_button.dart';
import '../widgets/registration_progress_indicator.dart';
import 'registration_password_screen.dart';
import 'training_sport_screen.dart';

typedef RegistrationEmailCallback =
    void Function(RegistrationDraft registration);

// Segunda etapa compartilhada dos cadastros, dedicada ao meio de contato.
class RegistrationEmailScreen extends StatefulWidget {
  const RegistrationEmailScreen({
    required this.registration,
    this.sportRepository = const FirebaseTrainingSportRepository(),
    this.registrationController,
    this.onContinue,
    this.onBack,
    super.key,
  });

  // Dados recebidos da etapa anterior e dependências do fluxo.
  final RegistrationDraft registration;
  final TrainingSportRepository sportRepository;
  final RegistrationController? registrationController;
  final RegistrationEmailCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<RegistrationEmailScreen> createState() =>
      _RegistrationEmailScreenState();
}

class _RegistrationEmailScreenState extends State<RegistrationEmailScreen> {
  // Estado e controlador pertencentes exclusivamente ao formulário de e-mail.
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.registration.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Validação local executada antes de alterar o estado do cadastro.
  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail.';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  // Navegação de retorno injetável para manter a tela testável.
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  // Acrescenta o e-mail e abre a próxima etapa correspondente ao perfil.
  void _continue() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final updatedRegistration = widget.registration.copyWithContact(
      email: _emailController.text.trim(),
    );
    final onContinue = widget.onContinue;

    if (onContinue != null) {
      onContinue(updatedRegistration);
      return;
    }

    final nextScreen = switch (updatedRegistration) {
      GuardianRegistrationDraft guardian => RegistrationPasswordScreen(
        registration: guardian,
        registrationController: widget.registrationController,
      ),
      TrainerRegistrationDraft trainer => TrainingSportScreen(
        registration: trainer,
        sportRepository: widget.sportRepository,
        registrationController: widget.registrationController,
      ),
    };

    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => nextScreen),
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
                            // Segundo passo do fluxo de cadastro selecionado.
                            RegistrationProgressIndicator(
                              configuration: switch (widget.registration) {
                                GuardianRegistrationDraft() =>
                                  RegistrationProgressConfiguration.guardian,
                                TrainerRegistrationDraft() =>
                                  RegistrationProgressConfiguration.trainer,
                              },
                              currentStep: 2,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Qual o seu e-mail?',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Esse será nosso meio de contato\ncom você.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 58),
                            // Entrada sem acesso direto a backend ou Firebase.
                            Form(
                              key: _formKey,
                              child: AppTextFormField(
                                controller: _emailController,
                                hintText: 'E-mail',
                                autofillHints: const [AutofillHints.email],
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                validator: _validateEmail,
                                onFieldSubmitted: (_) => _continue(),
                              ),
                            ),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-registration-email',
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
