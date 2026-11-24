// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Cobertura da seleção de macrorregião, estado e cidade e da
// persistência das regiões de atendimento do treinador.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/authentication/application/states/registration_draft.dart';
import 'package:horse_life/features/authentication/application/states/trainer_service_area.dart';
import 'package:horse_life/features/authentication/data/repositories/brazilian_locations_repository.dart';
import 'package:horse_life/features/authentication/presentation/screens/registration_password_screen.dart';
import 'package:horse_life/features/authentication/presentation/screens/service_areas_screen.dart';

void main() {
  // Draft mínimo compartilhado por todos os cenários da sexta etapa.
  const registration = TrainerRegistrationDraft(
    firstName: 'Ana',
    lastName: 'Silva',
    email: 'ana@email.com',
    sport: 'Salto',
  );

  // Monta a tela com tema real e permite injetar dependências por cenário.
  Widget buildApp({
    ServiceAreasCallback? onContinue,
    BrazilianLocationsRepository? repository,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: ServiceAreasScreen(
        registration: registration,
        locationsRepository: repository ?? FakeBrazilianLocationsRepository(),
        onContinue: onContinue,
      ),
    );
  }

  // Abre o primeiro modal e aguarda o término de suas animações.
  Future<void> openTypeDialog(WidgetTester tester) async {
    final addButton = find.byKey(const Key('add-service-area'));
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();
  }

  // Seleciona a abrangência e avança para o modal de localidades.
  Future<void> chooseType(WidgetTester tester, Key typeKey) async {
    await tester.tap(find.byKey(typeKey));
    await tester.tap(find.byKey(const Key('continue-service-area-type')));
    await tester.pumpAndSettle();
  }

  // Estrutura, chamada principal e progresso do fluxo profissional.
  testWidgets('shows service areas as the sixth trainer step', (tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.text('Regiões de\natendimento'), findsOneWidget);
    expect(find.text('Adicionar região'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 6 de 8'), findsOneWidget);
  });

  // Integração da sexta etapa com a tela compartilhada de senha.
  testWidgets('opens the shared password screen as trainer step seven', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());

    final continueButton = find.byKey(const Key('continue-service-areas'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.byType(RegistrationPasswordScreen), findsOneWidget);
    expect(find.text('Crie uma senha'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 7 de 8'), findsOneWidget);

    final passwordScreen = tester.widget<RegistrationPasswordScreen>(
      find.byType(RegistrationPasswordScreen),
    );
    expect(passwordScreen.registration, isA<TrainerRegistrationDraft>());
  });

  // Opções disponíveis e seleção inicial do primeiro modal.
  testWidgets('opens a modal to choose the area type', (tester) async {
    await tester.pumpWidget(buildApp());
    await openTypeDialog(tester);

    expect(
      find.text('Selecione o tipo de região que\ndeseja adicionar:'),
      findsOneWidget,
    );
    expect(find.text('Região do país'), findsOneWidget);
    expect(find.text('Estado'), findsOneWidget);
    expect(find.text('Cidade'), findsOneWidget);
    expect(find.byType(Radio<TrainerServiceAreaType>), findsNWidgets(3));

    final radioGroup = tester.widget<RadioGroup<TrainerServiceAreaType>>(
      find.byType(RadioGroup<TrainerServiceAreaType>),
    );
    expect(radioGroup.groupValue, TrainerServiceAreaType.countryRegion);
  });

  // Cadastro de uma área ampla, sem exigir estado nem cidade.
  testWidgets('adds the selected Brazilian country region', (tester) async {
    await tester.pumpWidget(buildApp());
    await openTypeDialog(tester);
    await chooseType(tester, const Key('service-area-type-region'));

    expect(find.byKey(const Key('country-region-dropdown')), findsOneWidget);
    expect(find.byKey(const Key('service-area-state-dropdown')), findsNothing);

    await tester.tap(find.byKey(const Key('save-service-area')));
    await tester.pumpAndSettle();

    expect(find.text('Sudeste'), findsOneWidget);
    expect(find.text('Região do país'), findsOneWidget);
  });

  // Encadeamento entre macrorregião e respectivas UFs.
  testWidgets('filters states after selecting a country region', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await openTypeDialog(tester);
    await chooseType(tester, const Key('service-area-type-state'));

    await tester.tap(find.byKey(const Key('country-region-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sul').last);
    await tester.pumpAndSettle();

    final stateDropdown = tester.widget<DropdownButton<BrazilianStateOption>>(
      find.byKey(const Key('service-area-state-dropdown')),
    );
    expect(stateDropdown.items, hasLength(1));
    expect(stateDropdown.value?.code, 'PR');

    await tester.ensureVisible(find.byKey(const Key('save-service-area')));
    await tester.tap(find.byKey(const Key('save-service-area')));
    await tester.pumpAndSettle();

    expect(find.text('Paraná'), findsOneWidget);
    expect(find.text('Estado • Sul'), findsOneWidget);
  });

  // Carregamento das cidades da UF ativa e persistência da escolha.
  testWidgets('shows alphabetized cities for the selected state', (
    tester,
  ) async {
    final repository = FakeBrazilianLocationsRepository();
    await tester.pumpWidget(buildApp(repository: repository));
    await openTypeDialog(tester);
    await chooseType(tester, const Key('service-area-type-city'));

    expect(repository.requestedStateCodes, ['SP']);
    final cityDropdown = tester.widget<DropdownButton<String>>(
      find.byKey(const Key('service-area-city-dropdown')),
    );
    final cityLabels = cityDropdown.items!
        .map((item) => (item.child as Text).data)
        .toList();
    expect(cityLabels, ['Americana', 'Campinas', 'Santos']);

    await tester.tap(find.byKey(const Key('service-area-city-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Campinas').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('save-service-area')));
    await tester.tap(find.byKey(const Key('save-service-area')));
    await tester.pumpAndSettle();

    expect(find.text('Campinas'), findsOneWidget);
    expect(find.text('Cidade • SP'), findsOneWidget);
  });

  // Remoção local e entrega somente das áreas remanescentes ao callback.
  testWidgets('removes an area and continues with remaining selections', (
    tester,
  ) async {
    TrainerRegistrationDraft? receivedRegistration;
    await tester.pumpWidget(
      buildApp(
        onContinue: (updatedRegistration) {
          receivedRegistration = updatedRegistration;
        },
      ),
    );

    for (var index = 0; index < 2; index++) {
      await openTypeDialog(tester);
      await chooseType(tester, const Key('service-area-type-region'));
      if (index == 1) {
        await tester.tap(find.byKey(const Key('country-region-dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sul').last);
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(find.byKey(const Key('save-service-area')));
      await tester.tap(find.byKey(const Key('save-service-area')));
      await tester.pumpAndSettle();
    }

    await tester.tap(
      find.byKey(const ValueKey('remove-service-area-countryregion|sudeste')),
    );
    await tester.pumpAndSettle();

    final continueButton = find.byKey(const Key('continue-service-areas'));
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);

    final areas = receivedRegistration?.serviceAreas ?? [];
    expect(areas, hasLength(1));
    expect(areas.single.type, TrainerServiceAreaType.countryRegion);
    expect(areas.single.countryRegion, 'Sul');
  });
}

// Fonte determinística que também registra as UFs consultadas pela tela.
class FakeBrazilianLocationsRepository implements BrazilianLocationsRepository {
  final List<String> requestedStateCodes = [];

  @override
  Future<List<String>> fetchCities(String stateCode) async {
    requestedStateCodes.add(stateCode);
    return switch (stateCode) {
      'SP' => ['Americana', 'Campinas', 'Santos'],
      'RJ' => ['Niterói', 'Rio de Janeiro'],
      'PR' => ['Curitiba', 'Londrina'],
      _ => [],
    };
  }

  @override
  Future<List<BrazilianStateOption>> fetchStates() async {
    return const [
      BrazilianStateOption(name: 'São Paulo', code: 'SP'),
      BrazilianStateOption(name: 'Rio de Janeiro', code: 'RJ'),
      BrazilianStateOption(name: 'Paraná', code: 'PR'),
    ];
  }
}
