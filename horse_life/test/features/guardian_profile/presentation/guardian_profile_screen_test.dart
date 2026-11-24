// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da abertura da listagem de cavalos pelo botão
// "Mostrar tudo" do perfil do responsável.
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Revisão da documentação dos cenários de carregamento, edição,
// nova tentativa e navegação pelos cavalos do responsável.
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Regressão para garantir que a nova tentativa da Home não devolva
// uma Future pelo callback síncrono de setState.
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação da montagem e dos cenários de interface do perfil.
//
// Data: 04/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão do teste de nova tentativa de carregamento após erro, sem
// retorno assíncrono indevido no setState.
//
// Data: 30/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação da montagem e dos cenários cobertos pelos testes.
//
// Data: 28/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos testes da tela de perfil do responsável, abrangendo
// dados, estado vazio, logout e acesso pela navegação inferior.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/core/widgets/gradient_button.dart';
import 'package:horse_life/features/profile/presentation/widgets/profile_identity_header.dart';
import 'package:horse_life/features/profile/presentation/widgets/red_sign_out_button.dart';
import 'package:horse_life/features/profile/data/models/guardian_profile_data.dart';
import 'package:horse_life/features/profile/presentation/screens/guardian_profile_screen.dart';
import 'package:horse_life/features/home/application/controllers/home_loader.dart';
import 'package:horse_life/features/home/data/models/guardian_home_data.dart';
import 'package:horse_life/features/home/presentation/screens/guardian/guardian_home_screen.dart';

void main() {
  // --- Preparação compartilhada ---------------------------------------------
  // Monta a tela com dependências previsíveis para os testes de widget.
  Widget buildGuardianApp(
    GuardianProfileData guardianProfile, {
    Future<void> Function()? onLogout,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: GuardianProfileScreen(
          loadGuardianProfile: () async => guardianProfile,
          onLogout: onLogout ?? () async {},
        ),
      ),
    );
  }

  // --- Conteúdo carregado ----------------------------------------------------
  testWidgets('shows guardian backend data and horse asset cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildGuardianApp(
        const GuardianProfileData(
          name: 'Ana Silva',
          email: 'ana@email.com',
          horses: [
            GuardianProfileHorse(name: 'Apollo', relationship: 'Proprietário'),
            GuardianProfileHorse(name: 'Luna', relationship: 'Atleta'),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Meu perfil'), findsOneWidget);
    expect(find.text('Ana Silva'), findsOneWidget);
    expect(find.text('ana@email.com'), findsOneWidget);
    expect(find.byType(ProfileIdentityHeader), findsOneWidget);
    expect(find.byKey(const Key('profile-status-chip')), findsNothing);
    expect(find.text('Total: 2'), findsOneWidget);
    expect(find.text('Apollo'), findsOneWidget);
    expect(find.text('Luna'), findsOneWidget);
    expect(
      find.image(const AssetImage('assets/black-head-horse.png')),
      findsNWidgets(2),
    );
    expect(find.byType(RedSignOutButton), findsOneWidget);
  });

  // --- Estado sem cavalos ----------------------------------------------------
  testWidgets('uses GradientButton in the guardian empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildGuardianApp(
        const GuardianProfileData(
          name: 'Usuário HorseLife',
          email: 'usuario@email.com',
          horses: [],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Total: 0'), findsOneWidget);
    expect(find.text('Nenhum animal cadastrado'), findsOneWidget);
    expect(find.text('Cadastrar animal'), findsOneWidget);
    expect(find.byType(GradientButton), findsOneWidget);
    expect(find.byIcon(Icons.add_box_outlined), findsOneWidget);
  });

  // --- Proteção da ação de saída --------------------------------------------
  testWidgets('guardian sign-out button blocks duplicate requests', (
    tester,
  ) async {
    var calls = 0;
    final completion = Completer<void>();
    await tester.pumpWidget(
      buildGuardianApp(
        const GuardianProfileData(
          name: 'Ana',
          email: 'ana@email.com',
          horses: [],
        ),
        onLogout: () {
          calls++;
          return completion.future;
        },
      ),
    );
    await tester.pump();

    final signOutButton = find.byKey(const Key('red-sign-out-button'));
    await tester.ensureVisible(signOutButton);
    await tester.tap(signOutButton);
    await tester.pump();
    await tester.tap(signOutButton);

    expect(calls, 1);
    expect(find.text('Saindo...'), findsOneWidget);
    completion.complete();
    await tester.pump();
  });

  // --- Recuperação de falha --------------------------------------------------
  // A primeira chamada falha e a segunda comprova a troca segura da Future.
  testWidgets(
    'retries profile loading without returning a Future from setState',
    (tester) async {
      var calls = 0;
      Future<GuardianProfileData> loadProfile() {
        calls++;
        if (calls == 1) {
          return Future<GuardianProfileData>.error(Exception('offline'));
        }
        return Future<GuardianProfileData>.value(
          const GuardianProfileData(
            name: 'Ana Silva',
            email: 'ana@email.com',
            horses: [],
          ),
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: GuardianProfileScreen(
              loadGuardianProfile: loadProfile,
              onLogout: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível carregar o perfil.'), findsOneWidget);
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(calls, 2);
      expect(find.text('Ana Silva'), findsOneWidget);
    },
  );

  // --- Integração com a navegação da Home -----------------------------------
  testWidgets('opens guardian profile from the bottom navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: GuardianHomeScreen(
          loader: _GuardianHomeLoader(),
          guardianProfileLoader: () async => const GuardianProfileData(
            name: 'Ana Silva',
            email: 'ana@email.com',
            horses: [],
          ),
          onLogout: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meu perfil'), findsNothing);
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Meu perfil'), findsOneWidget);
    expect(find.text('Ana Silva'), findsOneWidget);
  });

  testWidgets('opens the horse list from the guardian profile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: GuardianHomeScreen(
          loader: _GuardianHomeLoader(),
          guardianProfileLoader: () async => const GuardianProfileData(
            name: 'Ana Silva',
            email: 'ana@email.com',
            horses: [],
          ),
          horseListBuilder: (_) =>
              const Scaffold(body: Text('Listagem completa de cavalos')),
          onLogout: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mostrar tudo'));
    await tester.pumpAndSettle();

    expect(find.text('Listagem completa de cavalos'), findsOneWidget);
  });

  testWidgets(
    'retries guardian Home without returning a Future from setState',
    (tester) async {
      final loader = _RetryGuardianHomeLoader();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: GuardianHomeScreen(loader: loader, onLogout: () async {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Não foi possível carregar os dados da Home.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(loader.calls, 2);
      expect(find.text('Olá Ana!'), findsOneWidget);
    },
  );
}

/// Carregador determinístico usado para isolar o teste de navegação.
class _GuardianHomeLoader implements HomeLoader<GuardianHomeData> {
  @override
  Future<GuardianHomeData> fetchHome() async => const GuardianHomeData(
    guardianName: 'Ana',
    todayTrainings: [],
    weeklyCompleted: 0,
    weeklyPlanned: 0,
    monthlyCompleted: 0,
    monthlyPlanned: 0,
    allTimeCompleted: 0,
    horses: [],
    trainers: [],
  );
}

class _RetryGuardianHomeLoader implements HomeLoader<GuardianHomeData> {
  var calls = 0;

  @override
  Future<GuardianHomeData> fetchHome() {
    calls++;
    if (calls == 1) return Future.error(Exception('offline'));
    return Future.value(
      const GuardianHomeData(
        guardianName: 'Ana',
        todayTrainings: [],
        weeklyCompleted: 0,
        weeklyPlanned: 0,
        monthlyCompleted: 0,
        monthlyPlanned: 0,
        allTimeCompleted: 0,
        horses: [],
        trainers: [],
      ),
    );
  }
}
