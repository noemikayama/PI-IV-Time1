// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos testes da etapa 7 de 7 (Revisão dos dados do plano de
// treinamento), cobrindo exibição completa, edição inline e submissão ao backend.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/core/widgets/app_date_picker_field.dart';
import 'package:horse_life/features/exercises/data/models/trainer_linked_horse.dart';
import 'package:horse_life/features/training_plans/application/controllers/training_plan_registration_controller.dart';
import 'package:horse_life/features/training_plans/application/states/training_plan_registration_draft.dart';
import 'package:horse_life/features/training_plans/data/models/training_plan_gallery_item.dart';
import 'package:horse_life/features/training_plans/data/models/training_plan_weekday.dart';
import 'package:horse_life/features/training_plans/data/repositories/training_plan_repository.dart';
import 'package:horse_life/features/training_plans/presentation/routes/training_plan_registration_flow_route.dart';
import 'package:horse_life/features/training_plans/presentation/screens/training_plan_confirmation_screen.dart';

class _SpyTrainingPlanRepository extends LocalTrainingPlanRepository {
  TrainingPlanRegistrationDraft? submittedDraft;

  @override
  Future<TrainingPlanRegistrationResult> createTrainingPlan({
    required TrainingPlanRegistrationDraft draft,
  }) async {
    submittedDraft = draft;
    return super.createTrainingPlan(draft: draft);
  }
}

void main() {
  Widget buildApp(Widget screen) {
    return MaterialApp(theme: AppTheme.light, home: screen);
  }

  const calvino = TrainerLinkedHorse(id: 'horse-calvino', name: 'Calvino');
  const sampleTraining = TrainingPlanGalleryItem(
    id: 'tr-1',
    code: 42,
    title: 'Trabalho de transições',
    estimatedDurationMinutes: 45,
    exerciseNames: ['Aquecimento ao passo', 'Transições trote-galope'],
  );

  TrainingPlanRegistrationDraft buildSampleDraft() {
    final startDate = TrainingPlanRegistrationDraft.dateOnly(DateTime.now());
    final endDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day + 21,
    );
    return TrainingPlanRegistrationDraft(
      title: 'Condicionamento 1,00 m',
      objective: 'Ganhar condicionamento para percursos de 1,00 m',
      horse: calvino,
      startDate: startDate,
      endDate: endDate,
      trainingsByDay: const {
        TrainingPlanWeekday.monday: sampleTraining,
        TrainingPlanWeekday.wednesday: sampleTraining,
      },
    );
  }

  testWidgets(
    'renders fields, selected horse and weekdays and allows inline editing before submit',
    (tester) async {
      final draft = buildSampleDraft();
      TrainingPlanRegistrationDraft? submittedDraft;

      await tester.pumpWidget(
        buildApp(
          TrainingPlanConfirmationScreen(
            draft: draft,
            onSubmitted: (updated) => submittedDraft = updated,
          ),
        ),
      );

      expect(find.text('Revise os dados'), findsOneWidget);
      expect(find.bySemanticsLabel('Etapa 7 de 7'), findsOneWidget);
      expect(find.text('Condicionamento 1,00 m'), findsOneWidget);
      expect(
        find.text('Ganhar condicionamento para percursos de 1,00 m'),
        findsOneWidget,
      );
      expect(find.text(formatAppDate(draft.startDate)), findsOneWidget);
      expect(find.text(formatAppDate(draft.endDate)), findsOneWidget);
      expect(
        find.byKey(const Key('training-plan-review-selected-horse')),
        findsOneWidget,
      );
      expect(find.text('Calvino'), findsOneWidget);
      expect(find.text('Segunda-feira'), findsOneWidget);
      expect(find.text('Quarta-feira'), findsOneWidget);
      expect(find.text('Terça-feira'), findsNothing);

      await tester.tap(find.byTooltip('Editar Título'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('training-plan-review-title')),
        'Condicionamento Avançado',
      );
      await tester.pump();

      final submitButton = find.byKey(
        const Key('submit-training-plan-registration'),
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(submittedDraft, isNotNull);
      expect(submittedDraft!.title, 'Condicionamento Avançado');
      expect(submittedDraft!.horse, calvino);
      expect(submittedDraft!.selectedWeekdayEntries, hasLength(2));
    },
  );

  testWidgets(
    'submits plan through controller and pops training plan flow route',
    (tester) async {
      final spyRepository = _SpyTrainingPlanRepository();
      final controller = TrainingPlanRegistrationController(
        planRepository: spyRepository,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(
                          name: TrainingPlanRegistrationFlowRoute.routeName,
                        ),
                        builder: (_) => TrainingPlanConfirmationScreen(
                          draft: buildSampleDraft(),
                          controller: controller,
                        ),
                      ),
                    );
                  },
                  child: const Text('Abrir revisão do plano'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir revisão do plano'));
      await tester.pumpAndSettle();

      expect(find.byType(TrainingPlanConfirmationScreen), findsOneWidget);

      final submitButton = find.byKey(
        const Key('submit-training-plan-registration'),
      );
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(spyRepository.submittedDraft, isNotNull);
      expect(spyRepository.submittedDraft!.title, 'Condicionamento 1,00 m');
      expect(find.byType(TrainingPlanConfirmationScreen), findsNothing);
      expect(find.text('Abrir revisão do plano'), findsOneWidget);
    },
  );
}
