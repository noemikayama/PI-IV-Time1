// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Herança de FormProgressConfiguration em RegistrationProgressConfiguration
// para garantir compatibilidade de tipos nos construtores const e no indicador.
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Re-exportação e adaptação da barra de progresso unificada em
// core/widgets/form_progress_indicator.dart, mantendo retrocompatibilidade.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Definição da trilha profissional com oito passos fixos.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do indicador configurável dos fluxos de cadastro.
// -----------------------------------------------------------------------------

export '../../../../core/widgets/form_progress_indicator.dart';

import '../../../../core/widgets/form_progress_indicator.dart';
import '../../data/models/user_type.dart';

// Configura separadamente a quantidade de etapas de cada tipo de usuário.
class RegistrationProgressConfiguration extends FormProgressConfiguration {
  const RegistrationProgressConfiguration._({
    required this.userType,
    required super.totalSteps,
  }) : super(segmentKeyPrefix: 'registration-progress-segment');

  final UserType userType;

  static const guardian = RegistrationProgressConfiguration._(
    userType: UserType.guardian,
    totalSteps: 4,
  );
  static const trainer = RegistrationProgressConfiguration._(
    userType: UserType.trainer,
    totalSteps: 8,
  );
}

typedef RegistrationProgressIndicator = FormProgressIndicator;
