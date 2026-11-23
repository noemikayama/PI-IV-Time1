// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Padronização da SnackBar de conclusão do treino com a cor de
// sucesso definida no tema do aplicativo.
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Integração do envio com o contrato do backend, validação da nota de
// desempenho, limites textuais e retorno de sucesso para atualizar a navegação.
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do estado do formulário, validação, mensagens de erro
// e componentes visuais usados na conclusão do treino. Adequação da percepção
// numérica e dos campos condicionais ao contrato do backend.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do formulário final do treino, com resumo da execução,
// percepção de desempenho, dificuldade, observações e envio ao backend.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/features/training/data/models/training_completion_data.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';

/// Coleta a avaliação do atleta e persiste o resultado da execução encerrada.
class TrainingCompletionScreen extends StatefulWidget {
  const TrainingCompletionScreen({
    required this.submitter,
    required this.initialInput,
    super.key,
  });

  /// Porta de persistência, injetável para testes e composições alternativas.
  final TrainingCompletionSubmitter submitter;

  /// Snapshot imutável do tempo e dos exercícios produzido pela tela ativa.
  final TrainingCompletionInput initialInput;

  @override
  State<TrainingCompletionScreen> createState() =>
      _TrainingCompletionScreenState();
}

class _TrainingCompletionScreenState extends State<TrainingCompletionScreen> {
  // Controllers pertencem à rota e são descartados junto com seu estado.
  final _formKey = GlobalKey<FormState>();
  final _performanceController = TextEditingController();
  final _difficultyController = TextEditingController();
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _performanceController.dispose();
    _difficultyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Valida uma única vez, bloqueia envios concorrentes e traduz erros remotos em
  // mensagens acionáveis antes de liberar novamente o formulário.
  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final hasCompletedExercises = widget.initialInput.completedCount > 0;
    final input = TrainingCompletionInput(
      recordId: widget.initialInput.recordId,
      elapsed: widget.initialInput.elapsed,
      performancePerception: hasCompletedExercises
          ? int.parse(_performanceController.text.trim())
          : null,
      difficulty: hasCompletedExercises ? _difficultyController.text : '',
      notes: _notesController.text,
      exercises: widget.initialInput.exercises,
    );
    try {
      await widget.submitter.submit(input);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Registro do treino enviado com sucesso.'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      final message = switch (error) {
        FirebaseFunctionsException(:final code)
            when code == 'unauthenticated' =>
          'Sua sessão expirou. Entre novamente.',
        FirebaseFunctionsException(:final code)
            when code == 'permission-denied' =>
          'Seu perfil não pode registrar este treino.',
        FirebaseFunctionsException(:final code) when code == 'not-found' =>
          'Este registro de treino não está mais disponível.',
        FirebaseFunctionsException(:final code)
            when code == 'failed-precondition' =>
          'Este treino não pode mais ser finalizado.',
        _ => 'Não foi possível enviar o registro. Tente novamente.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(message),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final input = widget.initialInput;
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CompletionHeader(
                      onBack: _submitting
                          ? null
                          : () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(height: 34),
                    const Center(child: _CompletionSeal()),
                    const SizedBox(height: 18),
                    Text(
                      'Treinamento\nconcluído',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Parabéns! Continue assim.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontFamily: 'Urbanist',
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.fromLTRB(23, 26, 23, 24),
                      decoration: BoxDecoration(
                        color: AppColors.alabasterGray,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Registro do treino',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(fontSize: 20),
                          ),
                          const SizedBox(height: 14),
                          _SummaryLine(
                            label: 'Tempo total:',
                            value: _formatElapsed(input.elapsed),
                          ),
                          const SizedBox(height: 8),
                          _SummaryLine(
                            label: 'Exercícios concluídos:',
                            value: '${input.completedCount}',
                          ),
                          const SizedBox(height: 8),
                          _SummaryLine(
                            label: 'Exercícios incompletos:',
                            value: '${input.incompleteCount}',
                          ),
                          const SizedBox(height: 18),
                          if (input.completedCount > 0) ...[
                            _PerformanceField(
                              controller: _performanceController,
                            ),
                            const SizedBox(height: 18),
                            _CompletionField(
                              controller: _difficultyController,
                              label: 'Dificuldades encontradas:',
                              helper:
                                  'Informe as dificuldades que você percebeu durante a execução dos exercícios.',
                              hint:
                                  'Ex.: Complicações quando está na mão esquerda',
                              maxLength: 1000,
                            ),
                            const SizedBox(height: 18),
                          ],
                          _CompletionField(
                            controller: _notesController,
                            label: 'Observações:',
                            helper:
                                'Informe aquilo que você acha útil que seu treinador saiba sobre a execução de hoje.',
                            hint: 'Ex.: Cavalo mais agitado no início',
                            maxLength: 500,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 34),
                    SizedBox(
                      height: 60,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.seaGreen, AppColors.blueSpruce],
                          ),
                          borderRadius: BorderRadius.circular(34),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: const Key('submit-training-completion'),
                            onTap: _submitting ? null : _submit,
                            borderRadius: BorderRadius.circular(34),
                            child: Center(
                              child: _submitting
                                  ? const SizedBox.square(
                                      dimension: 26,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      'Submeter registro',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontSize: 20,
                                          ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Cabeçalho que desabilita o retorno enquanto o formulário está sendo enviado.
class _CompletionHeader extends StatelessWidget {
  const _CompletionHeader({required this.onBack});
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton(
        onPressed: onBack,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.seaGreen,
          size: 28,
        ),
      ),
      Image.asset('assets/Logo_somente_simbolo.png', width: 52, height: 52),
    ],
  );
}

// Selo do protótipo: círculo de traço espesso com confirmação central.
class _CompletionSeal extends StatelessWidget {
  const _CompletionSeal();

  @override
  Widget build(BuildContext context) => Container(
    width: 84,
    height: 84,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.seaGreen, width: 8),
    ),
    child: const Icon(Icons.check_rounded, color: AppColors.seaGreen, size: 54),
  );
}

// Linha textual usada no resumo imutável da execução.
class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
      children: [
        TextSpan(
          text: '$label ',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        TextSpan(text: value),
      ],
    ),
  );
}

// Campo multilinha padronizado; a obrigatoriedade é definida pelo formulário.
class _CompletionField extends StatelessWidget {
  const _CompletionField({
    required this.controller,
    required this.label,
    required this.helper,
    required this.hint,
    required this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String helper;
  final String hint;
  final int maxLength;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
      ),
      const SizedBox(height: 4),
      Text(
        helper,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: controller,
        minLines: 2,
        maxLines: 4,
        maxLength: maxLength,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          filled: true,
          fillColor: AppColors.whiteSmoke,
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.grey, fontSize: 16),
          contentPadding: const EdgeInsets.all(16),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.seaGreen, width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    ],
  );
}

// Campo numérico obrigatório para execuções totais ou parciais.
class _PerformanceField extends StatelessWidget {
  const _PerformanceField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Percepção de desempenho:',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
      ),
      const SizedBox(height: 4),
      Text(
        'Avalie o desempenho do animal nesta sessão de 1 a 10.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: 2,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
        decoration: InputDecoration(
          counterText: '',
          hintText: 'Informe uma nota de 1 a 10',
          filled: true,
          fillColor: AppColors.whiteSmoke,
          hintStyle: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.grey, fontSize: 16),
          contentPadding: const EdgeInsets.all(16),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.seaGreen, width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: (value) {
          final score = int.tryParse(value?.trim() ?? '');
          if (score == null || score < 1 || score > 10) {
            return 'Informe uma nota inteira de 1 a 10.';
          }
          return null;
        },
      ),
    ],
  );
}

// Mantém o resumo temporal no mesmo formato HH:MM:SS da execução ativa.
String _formatElapsed(Duration elapsed) {
  final hours = elapsed.inHours.toString().padLeft(2, '0');
  final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
