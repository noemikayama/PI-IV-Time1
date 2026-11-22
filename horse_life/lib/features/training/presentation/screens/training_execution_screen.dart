// RESPONSÁVEL: Noemi Kayama - RA 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Ocultação da ação de execução para perfis com acesso somente de
// leitura, preservando a indicação de registros já finalizados.
//
// Data: 22/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do carregamento, nova tentativa, conteúdo consultivo,
// estados finais e navegação para a execução ativa.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da tela de detalhes da execução, com carregamento completo,
// estados de erro, conteúdo do treino e navegação para a execução ativa.
// -----------------------------------------------------------------------------

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/features/training/data/models/training_execution_data.dart';
import 'package:horse_life/features/training/data/repositories/training_completion_repository.dart';
import 'package:horse_life/features/training/data/repositories/training_execution_repository.dart';
import 'package:horse_life/features/training/presentation/screens/active_training_screen.dart';

/// Carrega e apresenta os detalhes de um treino antes de sua execução ativa.
class TrainingExecutionScreen extends StatefulWidget {
  const TrainingExecutionScreen({
    required this.loader,
    required this.reference,
    required this.completionSubmitter,
    this.onStart,
    super.key,
  });

  /// Fonte dos detalhes consolidados do treino.
  final TrainingExecutionLoader loader;

  /// Identidade recebida da agenda para localizar a prescrição correta.
  final TrainingExecutionReference reference;

  /// Dependência repassada à execução ativa e ao formulário final.
  final TrainingCompletionSubmitter completionSubmitter;

  /// Substitui a navegação padrão ao iniciar, principalmente em testes.
  final ValueChanged<TrainingExecutionData>? onStart;

  @override
  State<TrainingExecutionScreen> createState() =>
      _TrainingExecutionScreenState();
}

class _TrainingExecutionScreenState extends State<TrainingExecutionScreen> {
  // A Future é armazenada para que reconstruções visuais não repitam a consulta.
  late Future<TrainingExecutionData> _future;

  // Controla o carrossel consultivo dos exercícios.
  final _pageController = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.loader.fetchTraining(widget.reference);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Cria uma nova consulta somente por ação explícita após uma falha.
  void _retry() => setState(() {
    _future = widget.loader.fetchTraining(widget.reference);
  });

  // Prioriza a ação injetada; sem ela, abre a execução ativa padrão.
  void _startTraining(TrainingExecutionData training) {
    final callback = widget.onStart;
    if (callback != null) {
      callback(training);
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ActiveTrainingScreen(
          training: training,
          completionSubmitter: widget.completionSubmitter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<TrainingExecutionData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _ExecutionError(error: snapshot.error, onRetry: _retry);
            }
            return _buildContent(snapshot.data!);
          },
        ),
      ),
    );
  }

  // Monta o conteúdo e só oferece início quando permissão e estado permitem;
  // registros concluídos continuam visíveis com ação final desabilitada.
  Widget _buildContent(TrainingExecutionData training) {
    final canStart = training.canStart && !training.isFinished;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      key: const Key('training-execution-back'),
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.seaGreen,
                        size: 34,
                      ),
                    ),
                    Image.asset(
                      'assets/Logo_somente_simbolo.png',
                      width: 70,
                      height: 70,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  training.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 28),
                _LabeledText(
                  key: const Key('training-duration-text'),
                  label: 'Duração estimada:',
                  value: _duration(training.durationMinutes),
                  inline: true,
                ),
                const SizedBox(height: 20),
                _LabeledText(
                  key: const Key('training-description-text'),
                  label: 'Descrição:',
                  value: training.description.isEmpty
                      ? 'Sem descrição.'
                      : training.description,
                ),
                const SizedBox(height: 24),
                Text(
                  'Orientações:',
                  key: const Key('training-guidelines-title'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (training.guidelines.isEmpty)
                  const _GuidelineCard(text: 'Nenhuma orientação informada.')
                else
                  for (final guideline in training.guidelines) ...[
                    _GuidelineCard(text: guideline),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 14),
                Text(
                  'Exercícios:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (training.exercises.isEmpty)
                  const _EmptyExercises()
                else ...[
                  SizedBox(
                    height: 332,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: training.exercises.length,
                      onPageChanged: (value) => setState(() => _page = value),
                      itemBuilder: (context, index) => _ExerciseCard(
                        exercise: training.exercises[index],
                        position: index + 1,
                        total: training.exercises.length,
                      ),
                    ),
                  ),
                  if (training.exercises.length > 1) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        training.exercises.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: index == _page ? 40 : 13,
                          height: 13,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.grey,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                if (canStart || training.isFinished) ...[
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 64,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: training.isFinished ? AppColors.grey : null,
                        gradient: training.isFinished
                            ? null
                            : const LinearGradient(
                                colors: [
                                  AppColors.seaGreen,
                                  AppColors.blueSpruce,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(34),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const Key('training-execution-primary-action'),
                          onTap: canStart
                              ? () => _startTraining(training)
                              : null,
                          borderRadius: BorderRadius.circular(34),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!training.isFinished) ...[
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  training.isFinished
                                      ? 'Treino finalizado'
                                      : 'Iniciar treino',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineLarge
                                      ?.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Exibe rótulo e valor em linha ou em bloco com tipografia consistente.
class _LabeledText extends StatelessWidget {
  const _LabeledText({
    required this.label,
    required this.value,
    this.inline = false,
    super.key,
  });
  final String label;
  final String value;
  final bool inline;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$label${inline ? ' ' : '\n'}',
          style: const TextStyle(
            fontFamily: 'LeagueSpartan',
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextSpan(text: value),
      ],
    ),
    style: Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontFamily: 'Urbanist', fontSize: 18),
  );
}

// Cartão individual das orientações gerais do treinamento.
class _GuidelineCard extends StatelessWidget {
  const _GuidelineCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    decoration: _cardDecoration(radius: 24),
    child: Row(
      children: [
        const Icon(Icons.chat_bubble_outline_rounded, size: 34),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: 'Urbanist',
              fontSize: 18,
            ),
          ),
        ),
      ],
    ),
  );
}

// Resumo paginado de um exercício com acesso à descrição completa.
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.position,
    required this.total,
  });
  final TrainingExecutionExercise exercise;
  final int position;
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
    decoration: _cardDecoration(radius: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                exercise.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Text(
              '$position/$total',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            style: Theme.of(context).textTheme.bodyLarge,
            children: [
              const TextSpan(
                text: 'Duração estimada: ',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: _duration(exercise.durationMinutes)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.bodyLarge,
              children: [
                const TextSpan(
                  text: 'Descrição: ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: exercise.description.isEmpty
                      ? 'Sem descrição.'
                      : exercise.description,
                ),
              ],
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(
          height: 50,
          child: OutlinedButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (context) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: _LabeledText(
                  label: exercise.name,
                  value: exercise.description.isEmpty
                      ? 'Sem descrição.'
                      : exercise.description,
                ),
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.seaGreen,
              side: const BorderSide(color: AppColors.seaGreen, width: 2.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Ver detalhes'),
          ),
        ),
      ],
    ),
  );
}

// Estado vazio preserva a leitura dos demais detalhes sem bloquear a tela.
class _EmptyExercises extends StatelessWidget {
  const _EmptyExercises();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: _cardDecoration(radius: 18),
    child: const Text('Nenhum exercício informado.'),
  );
}

// Traduz falhas conhecidas e oferece uma nova tentativa para erros recuperáveis.
class _ExecutionError extends StatelessWidget {
  const _ExecutionError({required this.error, required this.onRetry});
  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (error) {
      FirebaseFunctionsException(:final code) when code == 'not-found' =>
        'Este treino não está mais disponível.',
      FirebaseFunctionsException(:final code) when code == 'unauthenticated' =>
        'Sua sessão expirou. Entre novamente.',
      _ => 'Não foi possível carregar o treino.',
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

// Decoração compartilhada pelos cartões consultivos da tela.
BoxDecoration _cardDecoration({required double radius}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  boxShadow: const [
    BoxShadow(color: Color(0x22000000), blurRadius: 7, offset: Offset(0, 2)),
  ],
);

// Formata a duração estimada com flexão simples de singular.
String _duration(int minutes) => minutes == 1 ? '1 minuto' : '$minutes minutos';
