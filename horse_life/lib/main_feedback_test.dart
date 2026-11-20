// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Entrada de demonstração isolada para testar visualmente as telas
// de registro, estado vazio, cadastro e leitura de feedback dos dois perfis.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_theme.dart';
import 'package:horse_life/features/feedback/data/repositories/mock_training_feedback_repository.dart';
import 'package:horse_life/features/feedback/presentation/routes/training_feedback_route.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'HorseLife — Feedback Mock',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const _FeedbackMockLauncher(),
  ));
}

class _FeedbackMockLauncher extends StatelessWidget {
  const _FeedbackMockLauncher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(title: const Text('Feedback — Demo HorseLife')),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: [
                  const Text(
                    'Prévia das telas mockadas (sem Firebase).',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _openButton(context, 'Responsável: sem feedback',
                      TrainingAgendaAudience.guardian, 'feedback-demo-pendente'),
                  _openButton(context, 'Profissional: escrever feedback',
                      TrainingAgendaAudience.trainer, 'feedback-demo-pendente'),
                  _openButton(context, 'Responsável: visualizar feedback',
                      TrainingAgendaAudience.guardian, 'feedback-demo-registrado'),
                  _openButton(context, 'Profissional: feedback registrado',
                      TrainingAgendaAudience.trainer, 'feedback-demo-registrado'),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () {
                      MockTrainingFeedbackRepository.instance.reset();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Cenários demonstrativos restaurados.'),
                      ));
                    },
                    child: const Text('Restaurar dados mockados'),
                  ),
                ],
              ),
            ),
          ),
        );
  }

  Widget _openButton(BuildContext context, String label,
      TrainingAgendaAudience audience, String id) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: FilledButton(
          onPressed: () => Navigator.of(context).push(
            TrainingFeedbackRoute.forRecord(
              recordId: id,
              audience: audience,
            ),
          ),
          child: Text(label),
        ),
      );
}
