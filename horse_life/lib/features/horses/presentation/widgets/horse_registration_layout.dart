// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Cabeçalho, progresso e botão de avanço separados das etapas.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import '../../application/states/horse_registration_step.dart';

/// O mesmo layout envolve todas as etapas, como no cadastro de usuário.
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
      backgroundColor: AppColors.whiteSmoke,
      appBar: AppBar(
        toolbarHeight: 78,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.seaGreen),
          tooltip: 'Voltar',
          onPressed: busy ? null : onBack,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Image.asset(
              'assets/Logo_somente_simbolo.png',
              width: 52,
              height: 52,
              errorBuilder: (_, _, _) => const Icon(
                Icons.pets,
                color: AppColors.seaGreen,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Row(
                  children: [
                    for (final item in HorseRegistrationStep.values)
                      Expanded(
                        child: Container(
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: item.index <= step.index
                                ? AppColors.seaGreen
                                : AppColors.alabasterGray,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 38, 28, 24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          step.title,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          step.subtitle,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyLarge?.copyWith(color: AppColors.text),
                        ),
                        const SizedBox(height: 36),
                        content,
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                  child: OutlinedButton(
                    onPressed: busy ? null : onNext,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      side: const BorderSide(color: AppColors.seaGreen, width: 2),
                      foregroundColor: AppColors.seaGreen,
                      shape: const StadiumBorder(),
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            step.isLast ? 'Cadastrar cavalo' : 'Seguinte →',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
