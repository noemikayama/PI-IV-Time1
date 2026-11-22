// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do estado do formulário, validação, mensagens de erro
// e componentes visuais usados na conclusão do treino.
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
    final input = TrainingCompletionInput(
      recordId: widget.initialInput.recordId,
      elapsed: widget.initialInput.elapsed,
      performancePerception: _performanceController.text,
      difficulty: _difficultyController.text,
      notes: _notesController.text,
      exercises: widget.initialInput.exercises,
    );
    try {
      await widget.submitter.submit(input);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
                    const SizedBox(height: 46),
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.seaGreen,
                      size: 132,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Treinamento\nconcluído',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Parabéns! Continue assim.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                    const SizedBox(height: 42),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                      decoration: BoxDecoration(
                        color: AppColors.alabasterGray,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Registro do treino',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 18),
                          _SummaryLine(
                            label: 'Tempo total:',
                            value: _formatElapsed(input.elapsed),
                          ),
                          const SizedBox(height: 12),
                          _SummaryLine(
                            label: 'Exercícios concluídos:',
                            value: '${input.completedCount}',
                          ),
                          const SizedBox(height: 12),
                          _SummaryLine(
                            label: 'Exercícios incompletos:',
                            value: '${input.incompleteCount}',
                          ),
                          const SizedBox(height: 22),
                          _CompletionField(
                            controller: _performanceController,
                            label: 'Percepção de desempenho:',
                            helper:
                                'Informe como você acha que o animal se saiu nesta sessão.',
                            hint: 'Ex.: Executado com facilidade',
                          ),
                          const SizedBox(height: 22),
                          _CompletionField(
                            controller: _difficultyController,
                            label: 'Dificuldades encontradas:',
                            helper:
                                'Informe as dificuldades que você percebeu durante a execução dos exercícios.',
                            hint:
                                'Ex.: Complicações quando está na mão esquerda',
                          ),
                          const SizedBox(height: 22),
                          _CompletionField(
                            controller: _notesController,
                            label: 'Observações:',
                            helper:
                                'Informe aquilo que você acha útil que seu treinador saiba sobre a execução de hoje.',
                            hint: 'Ex.: Cavalo mais agitado no início',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),
                    SizedBox(
                      height: 64,
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
                                          .headlineLarge
                                          ?.copyWith(color: Colors.white),
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
          size: 34,
        ),
      ),
      Image.asset('assets/Logo_somente_simbolo.png', width: 70, height: 70),
    ],
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
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 20),
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
  });

  final TextEditingController controller;
  final String label;
  final String helper;
  final String hint;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text(helper, style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 12),
      TextFormField(
        controller: controller,
        minLines: 3,
        maxLines: 5,
        maxLength: 2000,
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          filled: true,
          fillColor: AppColors.whiteSmoke,
          contentPadding: const EdgeInsets.all(18),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(18),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.seaGreen, width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
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
