// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes da tela de login para validar conteúdo,
// senha, formulário, submissão assíncrona, timeout, falhas de autenticação e
// conexão, além da configuração, estilo e fechamento da SnackBar genérica.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/app_text_form_field.dart';
import 'package:horse_life/features/authentication/presentation/screens/login_screen.dart';

void main() {
  testWidgets('shows the login content and toggles password visibility', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('Login'), findsOneWidget);
    expect(
      find.text('É muito bom te ter de volta!\nPronto para mais um?'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Símbolo HorseLife'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);

    AppTextFormField passwordField = tester
        .widgetList<AppTextFormField>(find.byType(AppTextFormField))
        .last;
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();

    passwordField = tester
        .widgetList<AppTextFormField>(find.byType(AppTextFormField))
        .last;
    expect(passwordField.obscureText, isFalse);
    expect(find.byTooltip('Ocultar senha'), findsOneWidget);
  });

  testWidgets('validates and submits normalized credentials', (tester) async {
    String? submittedEmail;
    String? submittedPassword;

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          login: (email, password) async {
            submittedEmail = email;
            submittedPassword = password;
            return true;
          },
        ),
      ),
    );

    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).first,
      '  user@test.com ',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(submittedEmail, 'user@test.com');
    expect(submittedPassword, 'secret');
  });

  testWidgets('shows an error SnackBar when credentials are incorrect', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(login: (email, password) async => false)),
    );

    await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
    await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('E-mail ou senha incorretos'), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final shape = snackBar.shape! as RoundedRectangleBorder;
    expect(snackBar.backgroundColor, const Color(0xFFAA0000));
    expect(shape.borderRadius, AppSnackBar.borderRadius);
    expect(snackBar.showCloseIcon, isTrue);
    expect(find.byIcon(Icons.error), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('E-mail ou senha incorretos'), findsNothing);
  });

  testWidgets('shows a connection error when the server does not respond', (
    tester,
  ) async {
    final serverResponse = Completer<bool>();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(login: (email, password) => serverResponse.future),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
    await tester.enterText(find.byType(TextFormField).last, 'secret');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 10));

    expect(find.text('Erro de conexão com o servidor'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('shows a connection error when the login request fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          login: (email, password) async => throw Exception('Network error'),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
    await tester.enterText(find.byType(TextFormField).last, 'secret');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Erro de conexão com o servidor'), findsOneWidget);
  });
}
