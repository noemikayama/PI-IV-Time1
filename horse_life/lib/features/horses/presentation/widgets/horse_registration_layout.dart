// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adaptação estética do layout para reutilizar AuthHeader,
// FormProgressIndicator e AuthNextButton de core/widgets, alinhando a estrutura
// visual aos fluxos de autenticação e cadastro de exercícios.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Cabeçalho, progresso e botão de avanço separados das etapas.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';

import '../../application/states/horse_registration_step.dart';

/// O mesmo layout envolve todas as etapas, alinhado aos fluxos de autenticação
/// e exercícios.
class HorseRegistrationLayout extends StatelessWidget {
  const HorseRegistrationLayout({
    required this.step,
    required this.formKey,
    required this.content,
    required this.onBack,
    required this.onNext,
    required this.busy,
    super.key,
  });

  final HorseRegistrationStep step;
  final GlobalKey<FormState> formKey;
  final Widget content;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool busy;

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
                    AuthHeader(onBack: busy ? () {} : onBack),
                    SizedBox(height: step.showsProgress ? 44 : 64),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (step.showsProgress) ...[
                                FormProgressIndicator(
                                  configuration:
                                      FormProgressConfiguration.horseRegistration,
                                  currentStep: step.progressStep,
                                ),
                                const SizedBox(height: 52),
                              ],
                              Text(
                                step.title,
                                textAlign: TextAlign.center,
                                style: textTheme.displaySmall?.copyWith(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                step.subtitle,
                                textAlign: TextAlign.center,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontSize: 20,
                                  height: 1.18,
                                ),
                              ),
                              SizedBox(height: step.showsProgress ? 58 : 40),
                              content,
                              SizedBox(height: step.showsProgress ? 50 : 64),
                              AuthNextButton(
                                buttonKey: const Key(
                                  'continue-horse-registration',
                                ),
                                isLoading: busy,
                                label: step.isLast
                                    ? 'Cadastrar cavalo'
                                    : 'Seguinte',
                                showArrow: !step.isLast,
                                onPressed: onNext,
                              ),
                            ],
                          ),
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
