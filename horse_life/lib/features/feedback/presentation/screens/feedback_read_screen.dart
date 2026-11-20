// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Extração da consulta de feedback para uma tela independente,
// compartilhada por responsável e profissional e sem ações de edição.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import 'package:horse_life/features/feedback/data/models/training_execution_record.dart';
import 'package:horse_life/features/feedback/presentation/widgets/feedback_display_fields.dart';

class FeedbackReadScreen extends StatelessWidget {
  const FeedbackReadScreen({required this.feedback, super.key});

  final TrainingExecutionFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthHeader(onBack: () => Navigator.of(context).pop()),
                  const SizedBox(height: 30),
                  Text(
                    'Feedback',
                    textAlign: TextAlign.center,
                    style: theme.displayMedium?.copyWith(fontSize: 36),
                  ),
                  const SizedBox(height: 34),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.alabasterGray,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FeedbackDetailLine(
                          label: 'Data do registro',
                          value: formatFeedbackDate(feedback.createdAt),
                        ),
                        const SizedBox(height: 10),
                        FeedbackReadOnlyField(
                          label: 'Comentários sobre a execução',
                          value: feedback.comment,
                          description: 'O que o treinador observou sobre a execução dos exercícios.',
                        ),
                        const SizedBox(height: 24),
                        FeedbackReadOnlyField(
                          label: 'Dificuldades identificadas',
                          value: feedback.difficultiesText,
                          description: 'As dificuldades/pontos fracos percebidos nos relatos.',
                        ),
                        const SizedBox(height: 24),
                        FeedbackReadOnlyField(
                          label: 'Correções e orientações',
                          value: feedback.guidelinesText,
                          description: 'Correções e ajustes para as próximas execuções.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: HomeBottomNavBar(
        selectedDestination: HomeNavigationDestination.trainings,
        onDestinationSelected: (destination) => Navigator.of(context).pop(destination),
      ),
    );
  }
}
