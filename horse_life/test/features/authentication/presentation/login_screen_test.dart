// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Adaptação dos cenários ao contrato de sessão tipada, às falhas
// do repositório e à limpeza da senha após autenticação.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Aplicação do AppTheme.light no ambiente de teste para reproduzir
// a configuração visual usada pela aplicação.
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
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/app_text_form_field.dart';
import 'package:horse_life/features/authentication/application/states/login_session.dart';
import 'package:horse_life/features/authentication/data/repositories/login_repository.dart';
import 'package:horse_life/features/authentication/presentation/screens/login_screen.dart';

void main() {
  const session = LoginSession(
    uid: 'guardian-uid',
    name: 'Ana Silva',
    role: AuthenticationRole.guardian,
  );

  Widget buildApp(Widget home) {
    return MaterialApp(theme: AppTheme.light, home: home);
  }

  // Cenário 1: conteúdo inicial e alternância da visibilidade da senha.
  testWidgets('shows the login content and toggles password visibility', (
    tester,
  ) async {
    // Preparação da tela sem integração remota.
    await tester.pumpWidget(buildApp(const LoginScreen()));

    // Verificação dos elementos essenciais da interface.
    expect(find.text('Login'), findsOneWidget);
    expect(
      find.text('É muito bom te ter de volta!\nPronto para mais um?'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Símbolo HorseLife'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);

    // Leitura do estado inicial do campo de senha.
    AppTextFormField passwordField = tester
        .widgetList<AppTextFormField>(find.byType(AppTextFormField))
        .last;
    expect(passwordField.obscureText, isTrue);

    // Ação de revelar a senha e verificação do novo estado.
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();

    passwordField = tester
        .widgetList<AppTextFormField>(find.byType(AppTextFormField))
        .last;
    expect(passwordField.obscureText, isFalse);
    expect(find.byTooltip('Ocultar senha'), findsOneWidget);
  });

  // Cenário 2: validação local e encaminhamento normalizado das credenciais.
  testWidgets('validates and submits normalized credentials', (tester) async {
    String? submittedEmail;
    String? submittedPassword;

    // Preparação de um login controlado que captura os valores recebidos.
    await tester.pumpWidget(
      buildApp(
        LoginScreen(
          login: (email, password) async {
            submittedEmail = email;
            submittedPassword = password;
            return session;
          },
        ),
      ),
    );

    // Primeira ação sem dados para disparar as validações obrigatórias.
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Informe seu e-mail.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);

    // Segunda ação com credenciais válidas e espaços extras no e-mail.
    await tester.enterText(
      find.byType(TextFormField).first,
      '  user@test.com ',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    // Verificação do contrato enviado à futura integração.
    expect(submittedEmail, 'user@test.com');
    expect(submittedPassword, 'secret');
  });

  // Cenário 3: recusa de credenciais e apresentação do erro configurado.
  testWidgets('shows an error SnackBar when credentials are incorrect', (
    tester,
  ) async {
    // Preparação de uma resposta negativa do serviço de login.
    await tester.pumpWidget(
      buildApp(
        LoginScreen(
          login: (email, password) async =>
              throw const LoginFailure.invalidCredentials(),
        ),
      ),
    );

    // Submissão de credenciais preenchidas.
    await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
    await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Verificação do conteúdo e da identidade visual da mensagem.
    expect(find.text('E-mail ou senha incorretos'), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    final shape = snackBar.shape! as RoundedRectangleBorder;
    expect(snackBar.backgroundColor, const Color(0xFFAA0000));
    expect(shape.borderRadius, AppSnackBar.borderRadius);
    expect(snackBar.showCloseIcon, isTrue);
    expect(find.byIcon(Icons.error), findsOneWidget);

    // Fechamento manual e confirmação da remoção da SnackBar.
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('E-mail ou senha incorretos'), findsNothing);
  });

  // Cenário 4: expiração do tempo de espera por ausência de resposta.
  testWidgets('shows a connection error when the server does not respond', (
    tester,
  ) async {
    // Future propositalmente pendente para simular o servidor sem resposta.
    final serverResponse = Completer<LoginSession>();

    await tester.pumpWidget(
      buildApp(LoginScreen(login: (email, password) => serverResponse.future)),
    );

    // Submissão e verificação do estado de processamento.
    await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
    await tester.enterText(find.byType(TextFormField).last, 'secret');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Avanço do relógio até o timeout e verificação da recuperação da tela.
    await tester.pump(const Duration(seconds: 10));

    expect(find.text('Erro de conexão com o servidor'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  // Cenário 5: exceção durante a comunicação com o serviço.
  testWidgets('shows a connection error when the login request fails', (
    tester,
  ) async {
    // Preparação de uma função que falha ao processar as credenciais.
    await tester.pumpWidget(
      buildApp(
        LoginScreen(
          login: (email, password) async => throw Exception('Network error'),
        ),
      ),
    );

    // Submissão e verificação da tradução da exceção em feedback seguro.
    await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
    await tester.enterText(find.byType(TextFormField).last, 'secret');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    expect(find.text('Erro de conexão com o servidor'), findsOneWidget);
  });

  testWidgets('clears the password after a successful login', (tester) async {
    await tester.pumpWidget(
      buildApp(LoginScreen(login: (email, password) async => session)),
    );

    await tester.enterText(find.byType(TextFormField).first, 'user@test.com');
    await tester.enterText(find.byType(TextFormField).last, 'secret');
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();

    final passwordField = tester.widget<TextFormField>(
      find.byType(TextFormField).last,
    );
    expect(passwordField.controller?.text, isEmpty);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
