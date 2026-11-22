// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura dos estados específicos de responsável e treinador e da
// navegação correspondente para senha ou seleção de modalidade, com
// padronização do nome da etapa profissional para sport.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes da etapa de e-mail do responsável.
// -----------------------------------------------------------------------------

import '../../../support/features/authentication/data/repositories/local_training_sport_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/authentication/application/states/registration_draft.dart';
import 'package:horse_life/features/authentication/presentation/screens/registration_email_screen.dart';
import 'package:horse_life/features/authentication/presentation/screens/registration_password_screen.dart';
import 'package:horse_life/features/authentication/presentation/screens/training_sport_screen.dart';

void main() {
  // Dados recebidos da etapa de nome e reutilizados pelos cenários.
  const initialRegistration = GuardianRegistrationDraft(
    firstName: 'Ana',
    lastName: 'Silva',
  );
  const trainerRegistration = TrainerRegistrationDraft(
    firstName: 'Ana',
    lastName: 'Silva',
  );

  // Montagem isolada com a configuração visual real.
  Widget buildApp(Widget home) {
    return MaterialApp(theme: AppTheme.light, home: home);
  }

  // Conteúdo visual e destaque exclusivo do segundo segmento.
  testWidgets('shows the guardian email step with the second segment active', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const RegistrationEmailScreen(sportRepository: const LocalTrainingSportRepository(), registration: initialRegistration),
      ),
    );

    expect(find.text('Qual o seu e-mail?'), findsOneWidget);
    expect(find.textContaining('Esse será nosso meio'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 2 de 4'), findsOneWidget);

    for (var step = 1; step <= 4; step++) {
      final segment = tester.widget<Container>(
        find.byKey(Key('registration-progress-segment-$step')),
      );
      final decoration = segment.decoration! as BoxDecoration;
      expect(
        decoration.color,
        step == 2 ? AppColors.seaGreen : AppColors.alabasterGray,
      );
    }
  });

  // Regras de e-mail e atualização imutável do draft.
  testWidgets('validates and appends the normalized email to the draft', (
    tester,
  ) async {
    RegistrationDraft? receivedRegistration;

    await tester.pumpWidget(
      buildApp(
        RegistrationEmailScreen(sportRepository: const LocalTrainingSportRepository(),
          registration: initialRegistration,
          onContinue: (registration) {
            receivedRegistration = registration;
          },
        ),
      ),
    );

    final continueButton = find.byKey(const Key('continue-registration-email'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(receivedRegistration, isNull);

    await tester.enterText(find.byType(TextFormField), 'email-invalido');
    await tester.tap(continueButton);
    await tester.pump();

    expect(find.text('Informe um e-mail válido.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '  ana@email.com  ');
    await tester.tap(continueButton);

    expect(receivedRegistration?.firstName, 'Ana');
    expect(receivedRegistration?.lastName, 'Silva');
    expect(receivedRegistration?.email, 'ana@email.com');
  });

  // Encadeamento do draft completo até a etapa sensível.
  testWidgets('opens the password step and preserves the registration data', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const RegistrationEmailScreen(sportRepository: const LocalTrainingSportRepository(), registration: initialRegistration),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'ana@email.com');
    final continueButton = find.byKey(const Key('continue-registration-email'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationPasswordScreen), findsOneWidget);
    expect(find.text('Crie uma senha'), findsOneWidget);

    final passwordScreen = tester.widget<RegistrationPasswordScreen>(
      find.byType(RegistrationPasswordScreen),
    );
    expect(passwordScreen.registration.firstName, 'Ana');
    expect(passwordScreen.registration.lastName, 'Silva');
    expect(passwordScreen.registration.email, 'ana@email.com');
  });

  // O treinador segue para a modalidade, enquanto o responsável mantém senha.
  testWidgets('opens the sport step for a trainer registration', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        const RegistrationEmailScreen(sportRepository: const LocalTrainingSportRepository(), registration: trainerRegistration),
      ),
    );

    await tester.enterText(find.byType(TextFormField), 'ana@email.com');
    final continueButton = find.byKey(const Key('continue-registration-email'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(TrainingSportScreen), findsOneWidget);
    expect(find.text('Modalidade de treinos'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 3 de 8'), findsOneWidget);

    final sportScreen = tester.widget<TrainingSportScreen>(
      find.byType(TrainingSportScreen),
    );
    expect(sportScreen.registration.email, 'ana@email.com');
  });
}
