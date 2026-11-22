// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Davi Alves Froza - RA 25016900
// Alteração: Validador local de microchip injetado na tela, porque o de
// produção passou a consultar o servidor pelo Firebase.
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Cobertura da fase final de adaptação estética do cadastro de cavalos:
// etapas de modalidade (AppDropdownField), limitações e saúde (AppAddItemButton,
// AppRemovableItemTile e diálogo com estilo cápsula), lesões (diálogo completo
// com calendário e card 3 linhas) e revisão final de dados com submissão.
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Cobertura da segunda fase de adaptação estética do cadastro de cavalos:
// etapas de raça (autocomplete), pelagem (autocomplete), sexo (AppDropdownField
// com opções Macho e Fêmea) e imagens (AppAddItemButton e AppRemovableItemTile).
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Cobertura de testes para a adaptação estética das 4 primeiras etapas
// do cadastro de cavalos (relacionamento, nome, microchip e data de nascimento),
// modais informativos e localização em português do AppDatePickerField.
// -----------------------------------------------------------------------------

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';
import 'package:horse_life/core/widgets/app_dropdown_field.dart';
import 'package:horse_life/core/widgets/app_info_dialog.dart';
import 'package:horse_life/core/widgets/app_item_list_widgets.dart';
import 'package:horse_life/core/widgets/app_text_form_field.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/form_progress_indicator.dart';
import 'package:horse_life/core/widgets/information_row.dart';
import 'package:horse_life/features/horses/data/models/horse_registration_draft.dart';
import 'package:horse_life/features/horses/data/repositories/horse_microchip_validator.dart';
import '../../../support/features/horses/data/repositories/mock_horse_registration_repository.dart';
import 'package:horse_life/features/horses/presentation/screens/horse_registration_screen.dart';
import 'package:horse_life/features/horses/presentation/services/horse_image_selection_service.dart';
import 'package:horse_life/features/horses/presentation/widgets/horse_injury_dialog.dart';
import 'package:horse_life/features/horses/presentation/widgets/horse_search_field.dart';
import 'package:horse_life/features/horses/presentation/widgets/horse_text_entry_dialog.dart';

class _FakeImageSelectionService implements HorseImageSelectionService {
  const _FakeImageSelectionService(this.files);
  final List<XFile> files;

  @override
  Future<HorseImageSelectionResult> select({required int currentCount}) async {
    return HorseImageSelectionResult(
      accepted: files,
      rejected: 0,
    );
  }
}

void main() {
  Widget buildScreen({
    HorseImageSelectionService? imageSelection,
    VoidCallback? onCompleted,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: HorseRegistrationScreen(
        repository: const MockHorseRegistrationRepository(),
        microchipValidator: const LocalHorseMicrochipValidator(),
        imageSelection:
            imageSelection ?? const HorseImageSelectionService(),
      ),
    );
  }

  testWidgets(
    'relationship step uses shared widgets, no progress bar and blocks athlete',
    (tester) async {
      await tester.pumpWidget(buildScreen());

      expect(find.byType(AuthHeader), findsOneWidget);
      expect(find.byType(AuthNextButton), findsOneWidget);
      expect(find.byType(FormProgressIndicator), findsNothing);
      expect(find.text('Relação com o cavalo'), findsOneWidget);
      expect(find.byType(AppDropdownField<HorseRelationship>), findsOneWidget);
      expect(find.byType(InformationRow), findsNWidgets(3));

      // Seleciona "Atleta" no dropdown arredondado.
      await tester.tap(
        find.byKey(const ValueKey('horse-select-Relação com o cavalo')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Atleta').last);
      await tester.pumpAndSettle();

      // Tenta avançar como atleta e verifica o modal impeditivo.
      final nextButton = find.byKey(const Key('continue-horse-registration'));
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.byType(AppInfoDialog), findsOneWidget);
      expect(find.text('Atletas não podem\ncadastrar cavalos'), findsOneWidget);
      expect(
        find.textContaining('só pode ser efetuado pelo usuário proprietário'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('confirm-horse-registration-notice')));
      await tester.pumpAndSettle();
      expect(find.byType(AppInfoDialog), findsNothing);
      expect(find.text('Relação com o cavalo'), findsOneWidget);
    },
  );

  testWidgets(
    'advances through name, microchip (modal on invalid) and localized birth date',
    (tester) async {
      await tester.pumpWidget(buildScreen());

      // Avança com "Proprietário" (padrão).
      final nextButton = find.byKey(const Key('continue-horse-registration'));
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Etapa 1: Nome do animal (1 de 12 na barra de progresso).
      expect(find.text('Nome do animal'), findsOneWidget);
      expect(find.byType(FormProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 1 de 12'), findsOneWidget);
      expect(find.byType(AppTextFormField), findsOneWidget);

      final segment1 = tester.widget<Container>(
        find.byKey(const Key('horse-progress-segment-1')),
      );
      expect((segment1.decoration! as BoxDecoration).color, AppColors.seaGreen);
      expect(
        find.byKey(const Key('horse-progress-segment-12')),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextFormField), 'Ventania');
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Etapa 2: Microchip do cavalo (2 de 12).
      expect(find.text('Microchip do cavalo'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 2 de 12'), findsOneWidget);
      expect(find.text('Código'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '123');
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Verifica modal de código inválido.
      expect(find.byType(AppInfoDialog), findsOneWidget);
      expect(find.text('Código inválido'), findsOneWidget);
      expect(
        find.text(
          'O número do microchip informado é inválido. Verifique se houve um erro de digitação e tente novamente.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('confirm-horse-registration-notice')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '123456789012345');
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Etapa 3: Data de nascimento (3 de 12).
      expect(find.text('Data de nascimento'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 3 de 12'), findsOneWidget);
      expect(find.byType(AppDatePickerField), findsOneWidget);
      expect(find.text('DD/MM/AAAA'), findsOneWidget);

      // Abre o DatePicker localizado em português.
      await tester.tap(find.byKey(const ValueKey('horse-birth-date')));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    },
  );

  testWidgets(
    'advances through full registration flow to review screen and submits',
    (tester) async {
      final fakeFiles = [
        XFile('imagem_1.png'),
        XFile('imagem_2.jpg'),
        XFile('imagem_3.jpeg'),
      ];

      await tester.pumpWidget(
        buildScreen(
          imageSelection: _FakeImageSelectionService(fakeFiles),
        ),
      );

      final nextButton = find.byKey(const Key('continue-horse-registration'));

      // 0. Relação com o cavalo -> Nome
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // 1. Nome -> Microchip
      await tester.enterText(find.byType(TextFormField), 'Ventania');
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // 2. Microchip -> Data de nascimento
      await tester.enterText(find.byType(TextFormField), '123456789012345');
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // 3. Data de nascimento -> Raça
      await tester.tap(find.byKey(const ValueKey('horse-birth-date')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // 4. Raça (Etapa 4 de 12)
      expect(find.text('Raça'), findsWidgets);
      expect(find.text('Selecione qual é a raça do seu animal.'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 4 de 12'), findsOneWidget);
      expect(find.byType(HorseSearchField), findsOneWidget);

      // Digita 'An' e seleciona 'Andaluz'
      await tester.enterText(
        find.byKey(const ValueKey('horse-search-Raça')),
        'An',
      );
      await tester.pumpAndSettle();
      expect(find.text('Andaluz'), findsOneWidget);

      await tester.tap(find.text('Andaluz'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // 5. Pelagem (Etapa 5 de 12)
      expect(find.text('Pelagem'), findsWidgets);
      expect(find.bySemanticsLabel('Etapa 5 de 12'), findsOneWidget);

      // Digita 'Ba' e seleciona 'Baia'
      await tester.enterText(
        find.byKey(const ValueKey('horse-search-Pelagem')),
        'Ba',
      );
      await tester.pumpAndSettle();
      expect(find.text('Baia'), findsOneWidget);

      await tester.tap(find.text('Baia'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // 6. Sexo (Etapa 6 de 12)
      expect(find.text('Sexo'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 6 de 12'), findsOneWidget);
      expect(find.byType(AppDropdownField<HorseSex>), findsOneWidget);
      expect(find.text('Fêmea'), findsOneWidget);

      // Abre dropdown e seleciona 'Macho'
      await tester.tap(find.byKey(const ValueKey('horse-select-Sexo')));
      await tester.pumpAndSettle();

      expect(find.text('Macho'), findsOneWidget);
      await tester.tap(find.text('Macho').last);
      await tester.pumpAndSettle();

      expect(find.text('Macho'), findsOneWidget);

      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // 7. Imagens (Etapa 7 de 12)
      expect(find.text('Imagens'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 7 de 12'), findsOneWidget);

      final addImageButton = find.byKey(const Key('horse-add-image-button'));
      expect(addImageButton, findsOneWidget);
      expect(find.text('Adicionar imagem'), findsOneWidget);

      // Clica em adicionar imagem
      await tester.tap(addImageButton);
      await tester.pumpAndSettle();

      expect(find.byType(AppRemovableItemTile), findsNWidgets(3));
      expect(find.text('imagem_1.png'), findsOneWidget);
      expect(find.text('imagem_2.jpg'), findsOneWidget);
      expect(find.text('imagem_3.jpeg'), findsOneWidget);

      // Remove a segunda imagem ('imagem_2.jpg')
      final removeSecondButton = find.byKey(
        const ValueKey('remove-horse-image-imagem_2.jpg'),
      );
      expect(removeSecondButton, findsOneWidget);
      await tester.tap(removeSecondButton);
      await tester.pumpAndSettle();

      expect(find.byType(AppRemovableItemTile), findsNWidgets(2));
      expect(find.text('imagem_2.jpg'), findsNothing);

      // Avança para a etapa 8 (Modalidade de treinos)
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // 8. Modalidade (Etapa 8 de 12)
      expect(find.text('Modalidade de treinos'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 8 de 12'), findsOneWidget);
      expect(find.byType(AppDropdownField<HorseModality>), findsOneWidget);
      expect(find.text('Adestramento'), findsOneWidget);

      // Abre dropdown de modalidades e escolhe 'Salto'
      await tester.tap(find.byKey(const ValueKey('horse-select-Modalidade')));
      await tester.pumpAndSettle();
      expect(find.text('Salto'), findsOneWidget);
      await tester.tap(find.text('Salto').last);
      await tester.pumpAndSettle();
      expect(find.text('Salto'), findsOneWidget);

      // Avança para a etapa 9 (Limitações físicas)
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // 9. Limitações físicas (Etapa 9 de 12)
      expect(find.text('Limitações físicas'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 9 de 12'), findsOneWidget);

      final addLimitationButton = find.byKey(
        const Key('horse-add-limitation-button'),
      );
      expect(addLimitationButton, findsOneWidget);
      await tester.tap(addLimitationButton);
      await tester.pumpAndSettle();

      expect(find.byType(HorseTextEntryDialog), findsOneWidget);
      expect(find.text('Adicionar limitação'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('horse-text-entry-input')),
        'Sensibilidade no casco posterior esquerdo.',
      );
      await tester.tap(find.byKey(const Key('save-horse-text-entry')));
      await tester.pumpAndSettle();

      expect(
        find.text('Sensibilidade no casco posterior esquerdo.'),
        findsOneWidget,
      );

      // Avança para a etapa 10 (Observações de saúde)
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // 10. Observações de saúde (Etapa 10 de 12)
      expect(find.text('Observações de saúde'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 10 de 12'), findsOneWidget);

      final addHealthButton = find.byKey(
        const Key('horse-add-health-button'),
      );
      expect(addHealthButton, findsOneWidget);
      await tester.tap(addHealthButton);
      await tester.pumpAndSettle();

      expect(find.byType(HorseTextEntryDialog), findsOneWidget);
      expect(find.text('Adicionar observação'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('horse-text-entry-input')),
        'Vacinas em dia.',
      );
      await tester.tap(find.byKey(const Key('save-horse-text-entry')));
      await tester.pumpAndSettle();

      expect(find.text('Vacinas em dia.'), findsOneWidget);

      // Avança para a etapa 11 (Histórico de lesões)
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // 11. Histórico de lesões (Etapa 11 de 12)
      expect(find.text('Histórico de lesões'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 11 de 12'), findsOneWidget);

      final addInjuryButton = find.byKey(const Key('horse-add-injury-button'));
      expect(addInjuryButton, findsOneWidget);
      await tester.tap(addInjuryButton);
      await tester.pumpAndSettle();

      expect(find.byType(HorseInjuryDialog), findsOneWidget);
      expect(find.text('Adicionar lesão'), findsOneWidget);

      // Seleciona data da lesão
      await tester.tap(find.byKey(const Key('horse-injury-date-picker-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('horse-injury-description')),
        'Distensão leve.',
      );
      await tester.enterText(
        find.byKey(const Key('horse-injury-prescription')),
        'Repouso de 3 dias.',
      );
      await tester.tap(find.byKey(const Key('save-horse-injury')));
      await tester.pumpAndSettle();

      expect(find.text('Distensão leve.'), findsOneWidget);
      expect(find.text('Repouso de 3 dias.'), findsOneWidget);

      // Avança para a etapa 12 (Revisão final)
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // 12. Revise os dados (Etapa 12 de 12)
      expect(find.text('Revise os dados'), findsOneWidget);
      expect(
        find.text('Confira se todas as informações estão corretas antes de continuar.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Etapa 12 de 12'), findsOneWidget);

      expect(find.text('Ventania'), findsOneWidget);
      expect(find.text('123456789012345'), findsOneWidget);
      expect(find.text('Andaluz'), findsOneWidget);
      expect(find.text('Baia'), findsOneWidget);
      expect(find.text('Macho'), findsOneWidget);
      expect(find.text('Salto'), findsOneWidget);

      expect(find.text('Informações adicionadas'), findsOneWidget);
      expect(find.text('Imagens'), findsWidgets);
      expect(find.text('Limitações físicas'), findsWidgets);
      expect(find.text('Observações de saúde'), findsWidgets);
      expect(find.text('Histórico de lesões'), findsWidgets);

      expect(find.text('Cadastrar cavalo'), findsOneWidget);

      // Submete o cadastro
      final submitButton = find.byKey(const Key('continue-horse-registration'));
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();
    },
  );
}
