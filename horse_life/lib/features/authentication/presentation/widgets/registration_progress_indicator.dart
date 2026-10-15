// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do indicador configurável dos fluxos de cadastro.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/user_type.dart';

// Configura separadamente a quantidade de etapas de cada tipo de usuário.
class RegistrationProgressConfiguration {
  const RegistrationProgressConfiguration._({
    required this.userType,
    required this.totalSteps,
  });

  // Identidade do fluxo e número total de etapas exibidas.
  final UserType userType;
  final int totalSteps;

  // Fluxo de responsável definido pelos quatro passos atuais.
  static const guardian = RegistrationProgressConfiguration._(
    userType: UserType.guardian,
    totalSteps: 4,
  );

  // O total profissional será informado quando suas etapas forem definidas.
  const RegistrationProgressConfiguration.professional({
    required int totalSteps,
  }) : this._(userType: UserType.professional, totalSteps: totalSteps);
}

// Exibe o progresso segmentado correspondente ao fluxo selecionado.
class RegistrationProgressIndicator extends StatelessWidget {
  const RegistrationProgressIndicator({
    required this.configuration,
    required this.currentStep,
    super.key,
  });

  // Configuração do fluxo e etapa ativa, usando índice iniciado em um.
  final RegistrationProgressConfiguration configuration;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    // Restringe valores externos aos limites disponíveis no indicador.
    final activeSteps = currentStep.clamp(0, configuration.totalSteps);

    return Semantics(
      label: 'Etapa $activeSteps de ${configuration.totalSteps}',
      // Cada segmento ocupa a mesma largura e somente o atual recebe destaque.
      child: Row(
        children: [
          for (var index = 0; index < configuration.totalSteps; index++) ...[
            Expanded(
              child: Container(
                key: Key('registration-progress-segment-${index + 1}'),
                height: 8,
                decoration: BoxDecoration(
                  color: index == activeSteps - 1
                      ? AppColors.seaGreen
                      : AppColors.alabasterGray,
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                ),
              ),
            ),
            if (index < configuration.totalSteps - 1) const SizedBox(width: 26),
          ],
        ],
      ),
    );
  }
}
