// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Verificação da criação dos estados específicos após o nome e da
// transição para o e-mail no fluxo de treinador com oito passos.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes da primeira etapa do cadastro.
// -----------------------------------------------------------------------------

import '../../../support/features/authentication/data/repositories/local_training_sport_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/authentication/application/states/registration_draft.dart';
import 'package:horse_life/features/authentication/presentation/screens/registration_email_screen.dart';
import 'package:horse_life/features/authentication/presentation/screens/registration_name_screen.dart';

void main() {
  // Montagem compartilhada das variações da etapa de nome.
  Widget buildApp(Widget home) {
    return MaterialApp(theme: AppTheme.light, home: home);
  }

  // Conteúdo e progresso do responsável.
  testWidgets('shows the guardian name step with four progress segments', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const RegistrationNameScreen.guardian()));

    expect(find.text('Como você se chama?'), findsOneWidget);
    expect(find.textContaining('Informe como quer'), findsOneWidget);
    expect(find.text('Primeiro nome'), findsOneWidget);
    expect(find.text('Sobrenome'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 1 de 4'), findsOneWidget);

    for (var step = 1; step <= 4; step++) {
      final segment = tester.widget<Container>(
        find.byKey(Key('registration-progress-segment-$step')),
      );
      final decoration = segment.decoration! as BoxDecoration;
      expect(
        decoration.color,
        step == 1 ? AppColors.seaGreen : AppColors.alabasterGray,
      );
    }
  });

  // Configuração fixa do fluxo profissional.
  testWidgets('shows the trainer progress with eight steps', (tester) async {
    await tester.pumpWidget(buildApp(const RegistrationNameScreen.trainer(sportRepository: const LocalTrainingSportRepository())));

    expect(find.bySemanticsLabel('Etapa 1 de 8'), findsOneWidget);
    expect(
      find.byKey(const Key('registration-progress-segment-8')),
      findsOneWidget,
    );
  });

  // Validação, trim e contrato de saída dos nomes.
  testWidgets('validates and passes normalized names to the next step', (
    tester,
  ) async {
    String? firstName;
    String? lastName;

    await tester.pumpWidget(
      buildApp(
        RegistrationNameScreen.guardian(
          onContinue: (first, last) {
            firstName = first;
            lastName = last;
          },
        ),
      ),
    );

    final continueButton = find.byKey(const Key('continue-registration-name'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(find.text('Preencha este campo.'), findsNWidgets(2));
    expect(firstName, isNull);

    await tester.enterText(find.byType(TextFormField).first, '  Ana  ');
    await tester.enterText(find.byType(TextFormField).last, '  Silva  ');
    await tester.tap(continueButton);

    expect(firstName, 'Ana');
    expect(lastName, 'Silva');
  });

  // Navegação e preservação do draft entre as duas primeiras etapas.
  testWidgets('opens the guardian email step and preserves the names', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const RegistrationNameScreen.guardian()));

    await tester.enterText(find.byType(TextFormField).first, 'Ana');
    await tester.enterText(find.byType(TextFormField).last, 'Silva');

    final continueButton = find.byKey(const Key('continue-registration-name'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationEmailScreen), findsOneWidget);
    expect(find.text('Qual o seu e-mail?'), findsOneWidget);

    final emailScreen = tester.widget<RegistrationEmailScreen>(
      find.byType(RegistrationEmailScreen),
    );
    expect(emailScreen.registration.firstName, 'Ana');
    expect(emailScreen.registration.lastName, 'Silva');
    expect(emailScreen.registration, isA<GuardianRegistrationDraft>());
  });

  // Transição do treinador para o segundo passo, mantendo a trilha profissional.
  testWidgets('opens the trainer email step with eight progress steps', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(const RegistrationNameScreen.trainer(sportRepository: const LocalTrainingSportRepository())));

    await tester.enterText(find.byType(TextFormField).first, 'Ana');
    await tester.enterText(find.byType(TextFormField).last, 'Silva');

    final continueButton = find.byKey(const Key('continue-registration-name'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationEmailScreen), findsOneWidget);
    expect(find.text('Qual o seu e-mail?'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 2 de 8'), findsOneWidget);
    expect(
      find.byKey(const Key('registration-progress-segment-8')),
      findsOneWidget,
    );
    final emailScreen = tester.widget<RegistrationEmailScreen>(
      find.byType(RegistrationEmailScreen),
    );
    expect(emailScreen.registration, isA<TrainerRegistrationDraft>());
  });
}
