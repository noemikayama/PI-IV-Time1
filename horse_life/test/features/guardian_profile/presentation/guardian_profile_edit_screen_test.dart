// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação da preparação, dos cenários e das dependências falsas
// usadas nos testes da edição do perfil.
//
// Data: 04/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes da edição do perfil, cobrindo dados exibidos,
// e-mail somente leitura, atualização do nome e redefinição de senha.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/authentication/data/repositories/password_reset_repository.dart';
import 'package:horse_life/features/profile/application/controllers/guardian_profile_controller.dart';
import 'package:horse_life/features/profile/data/models/guardian_profile_data.dart';
import 'package:horse_life/features/profile/data/repositories/guardian_profile_repository.dart';
import 'package:horse_life/features/profile/presentation/screens/guardian_profile_edit_screen.dart';

void main() {
  // --- Dependências controladas ---------------------------------------------
  late _ProfileRepository profileRepository;
  late _PasswordRepository passwordRepository;

  // Monta o formulário sempre com o mesmo perfil e repositórios observáveis.
  Widget buildApp() {
    return MaterialApp(
      theme: AppTheme.light,
      home: GuardianProfileEditScreen(
        profile: const GuardianProfileData(
          name: 'Ana Maria Silva',
          email: 'ana@email.com',
          horses: [],
        ),
        controller: GuardianProfileController(
          profileRepository: profileRepository,
          passwordResetRepository: passwordRepository,
        ),
      ),
    );
  }

  setUp(() {
    profileRepository = _ProfileRepository();
    passwordRepository = _PasswordRepository();
  });

  // --- Exibição e bloqueio de campos ----------------------------------------
  testWidgets('shows profile data and keeps email read-only', (tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.text('Editar perfil'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Maria Silva'), findsOneWidget);
    final emailField = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('guardian-edit-email')),
        matching: find.byType(EditableText),
      ),
    );
    expect(emailField.readOnly, isTrue);
  });

  // --- Orientação sobre alteração de e-mail ---------------------------------
  testWidgets('explains how to change the email from the information icon', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    await tester.tap(find.byKey(const Key('guardian-email-information')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Só é possível aterar o e-mail falando diretamente com o Suporte.',
      ),
      findsOneWidget,
    );
    expect(find.byType(Dialog), findsOneWidget);
    expect(
      tester.widget(find.byKey(const Key('guardian-email-information-ok'))),
      isA<OutlinedButton>(),
    );

    await tester.tap(find.byKey(const Key('guardian-email-information-ok')));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
  });

  // --- Persistência do nome --------------------------------------------------
  testWidgets('updates name through the controller', (tester) async {
    await tester.pumpWidget(buildApp());

    await tester.enterText(
      find.byKey(const Key('guardian-edit-first-name')),
      'Beatriz',
    );
    await tester.enterText(
      find.byKey(const Key('guardian-edit-last-name')),
      'Souza',
    );
    await tester.ensureVisible(find.byKey(const Key('guardian-save-profile')));
    await tester.tap(find.byKey(const Key('guardian-save-profile')));
    await tester.pumpAndSettle();

    expect(profileRepository.firstName, 'Beatriz');
    expect(profileRepository.lastName, 'Souza');
  });

  // --- Redefinição de senha --------------------------------------------------
  testWidgets('requests password reset for the registered email', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    final button = find.byKey(const Key('guardian-change-password'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(passwordRepository.email, 'ana@email.com');
    expect(find.text('Confira sua caixa de entrada.'), findsOneWidget);
  });
}

/// Repositório falso que captura os nomes enviados pelo controlador.
class _ProfileRepository implements GuardianProfileRepository {
  String? firstName;
  String? lastName;

  @override
  Future<GuardianProfileData> getGuardianProfile() async =>
      const GuardianProfileData(
        name: 'Ana',
        email: 'ana@email.com',
        horses: [],
      );

  @override
  Future<GuardianProfileUpdate> updateGuardianProfile({
    required String firstName,
    required String lastName,
  }) async {
    this.firstName = firstName;
    this.lastName = lastName;
    return GuardianProfileUpdate(
      name: '$firstName $lastName',
      updatedAt: DateTime(2026, 11, 4),
    );
  }
}

/// Repositório falso que captura o destinatário da redefinição de senha.
class _PasswordRepository implements PasswordResetRepository {
  String? email;

  @override
  Future<String> requestPasswordReset({required String email}) async {
    this.email = email;
    return 'Confira sua caixa de entrada.';
  }
}
