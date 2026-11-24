// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Abertura direta de TrainingExecutionRecordScreen ao tocar no card
// de histórico de execuções quando onViewHistory não for fornecido.
//
// Data: 21/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Ajuste do círculo colorido do calendário para acompanhar somente
// o dia selecionado, inclusive quando a nova data não possui treinos; revisão
// da documentação das fontes autoritativas fornecidas pelo backend.
//
// Data: 20/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Suporte aos dados diários e históricos fornecidos pelo backend,
// atualização remota da semana e filtragem dos planos pelo dia selecionado.
//
// Data: 18/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Implementação da agenda semanal compartilhada entre responsável
// e treinador, incluindo status por data, cards, carrossel e estados vazios.
// Alteração: Inclusão da navegação entre semanas e do modal de planos ativos,
// adaptado às informações permitidas para cada perfil.
// Documentação da API pública, estados e regras visuais da agenda.
// -----------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/features/feedback/data/repositories/training_feedback_repository.dart';
import 'package:horse_life/features/feedback/presentation/routes/training_feedback_route.dart';
import 'package:horse_life/features/home/presentation/widgets/horse_asset_icon.dart';
import 'package:horse_life/features/training/data/models/training_agenda_data.dart';

// Callback das ações associadas a um treino da agenda.
typedef TrainingAgendaEntryCallback = void Function(TrainingAgendaEntry entry);

// Agenda semanal compartilhada pelas experiências de responsável e treinador.
//
// A tela recebe dados já adaptados e comunica as interações por callbacks,
// sem depender diretamente dos repositórios ou modelos das respectivas Homes.
class TrainingAgendaScreen extends StatefulWidget {
  const TrainingAgendaScreen({
    required this.activePlansCount,
    required this.plans,
    required this.trainings,
    this.calendarPlans,
    this.todayTrainings,
    this.history,
    this.audience = TrainingAgendaAudience.guardian,
    this.initialDate,
    this.maxDayIndicators = 3,
    this.onViewPlans,
    this.onViewPlan,
    this.onStartTraining,
    this.onViewTraining,
    this.onViewHistory,
    this.onWeekChanged,
    this.feedbackRepository,
    super.key,
  }) : assert(maxDayIndicators > 0);

  // Quantidade total de planos ativos apresentada no resumo.
  final int activePlansCount;

  // Planos disponíveis na semana e no modal de planos ativos.
  final List<TrainingAgendaPlan> plans;

  // Treinos usados pelo calendário, carrossel diário e histórico.
  final List<TrainingAgendaEntry> trainings;

  // Representações dos treinos semanais usadas na lista sob o calendário.
  // Quando presentes, são filtradas pelo dia; quando ausentes, a tela mantém a
  // listagem legada de planos ativos da semana.
  final List<TrainingAgendaPlan>? calendarPlans;

  // Listas autoritativas retornadas pelo backend para as seções diárias. Se não
  // forem fornecidas, a tela as deduz de [trainings] para compatibilidade.
  final List<TrainingAgendaEntry>? todayTrainings;
  final List<TrainingAgendaEntry>? history;

  // Público atual, usado para ajustar textos e informações sensíveis.
  final TrainingAgendaAudience audience;

  // Data inicialmente selecionada; quando ausente, usa o dia atual.
  final DateTime? initialDate;

  // Quantidade máxima de bolinhas mostradas sob cada data.
  final int maxDayIndicators;

  // Substitui a abertura padrão do modal de planos ativos.
  final VoidCallback? onViewPlans;

  // Chamado ao selecionar um plano no modal ou na lista semanal.
  final ValueChanged<TrainingAgendaPlan>? onViewPlan;

  // Chamado quando um treino está liberado para execução.
  final TrainingAgendaEntryCallback? onStartTraining;

  // Chamado quando um treino permite somente consulta.
  final TrainingAgendaEntryCallback? onViewTraining;

  // Chamado ao selecionar uma execução no histórico.
  final TrainingAgendaEntryCallback? onViewHistory;

  // Solicita ao contêiner uma nova semana após o usuário navegar no calendário.
  final ValueChanged<DateTime>? onWeekChanged;

  /// Fonte de feedback injetável para consulta e gravação do registro.
  final TrainingFeedbackRepository? feedbackRepository;

  @override
  State<TrainingAgendaScreen> createState() => _TrainingAgendaScreenState();
}

class _TrainingAgendaScreenState extends State<TrainingAgendaScreen> {
  // Dia que orienta a semana visível e o conteúdo das seções diárias.
  late DateTime _selectedDate;

  // Controla o carrossel quando há mais de um treino no dia.
  final PageController _trainingPageController = PageController();
  int _trainingPage = 0;

  static const _monthNames = <String>[
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];

  static const _weekdays = <String>[
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(widget.initialDate ?? DateTime.now());
  }

  @override
  void dispose() {
    _trainingPageController.dispose();
    super.dispose();
  }

  // Treinos correspondentes ao dia selecionado, sem considerar o horário.
  List<TrainingAgendaEntry> get _selectedTrainings => widget.trainings
      .where((training) => _sameDay(training.date, _selectedDate))
      .toList(growable: false);

  // Execuções concluídas ou parciais mostradas da mais recente para a antiga.
  List<TrainingAgendaEntry> get _selectedHistory => _selectedTrainings
      .where((training) => training.wasExecuted)
      .toList(growable: false)
      .reversed
      .toList(growable: false);

  // Avança ou retrocede semanas completas e reinicia o carrossel diário.
  void _changeWeek(int offset) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offset * 7));
      _trainingPage = 0;
    });
    _resetTrainingPage();
    widget.onWeekChanged?.call(_selectedDate);
  }

  // Seleciona um dia do calendário e reinicia o carrossel diário.
  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = _dateOnly(date);
      _trainingPage = 0;
    });
    _resetTrainingPage();
  }

  // Retorna o PageView à primeira página após a reconstrução do frame.
  void _resetTrainingPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _trainingPageController.hasClients) {
        _trainingPageController.jumpToPage(0);
      }
    });
  }

  // Exibe a lista de planos ativos quando o chamador não fornece outra ação.
  Future<void> _showActivePlans() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ActivePlansSheet(
        audience: widget.audience,
        plans: widget.plans,
        onPlanSelected: (plan) {
          Navigator.of(sheetContext).pop();
          widget.onViewPlan?.call(plan);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= 720 ? 40.0 : 20.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            24,
            horizontalPadding,
            32,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Agenda de treinos',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 24),
                  _AgendaSummary(
                    count: widget.activePlansCount,
                    onViewPlans: widget.onViewPlans ?? _showActivePlans,
                    showViewPlans:
                        widget.audience != TrainingAgendaAudience.trainer ||
                        widget.activePlansCount > 0,
                  ),
                  const SizedBox(height: 20),
                  _buildCalendar(context),
                  const SizedBox(height: 20),
                  _buildDailyTrainings(context),
                  const SizedBox(height: 20),
                  _buildHistory(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Monta o calendário semanal e seus planos ou estado vazio.
  Widget _buildCalendar(BuildContext context) {
    final days = _daysForVisibleWeek();
    final firstDay = days.first;
    final lastDay = days.last;
    final weekTrainings = widget.trainings
        .where(
          (training) =>
              !_dateOnly(training.date).isBefore(firstDay) &&
              !_dateOnly(training.date).isAfter(lastDay),
        )
        .toList(growable: false);
    // A API conectada fornece representações por dia; a API legada fornece
    // planos ativos e, por isso, mantém o filtro pelos limites da semana.
    final weekPlans = widget.calendarPlans != null
        ? widget.calendarPlans!
              .where((plan) => _sameDay(plan.date, _selectedDate))
              .toList(growable: false)
        : widget.plans
              .where(
                (plan) =>
                    !_dateOnly(plan.date).isBefore(firstDay) &&
                    !_dateOnly(plan.date).isAfter(lastDay),
              )
              .toList(growable: false);
    final showEmptyState = widget.calendarPlans != null
        ? weekPlans.isEmpty
        : weekTrainings.isEmpty;
    return _AgendaSection(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                key: const Key('agenda-previous-week'),
                tooltip: 'Semana anterior',
                onPressed: () => _changeWeek(-1),
                icon: const Icon(Icons.chevron_left_rounded, size: 34),
              ),
              Expanded(
                child: Text(
                  '${_monthNames[_selectedDate.month - 1]} ${_selectedDate.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                key: const Key('agenda-next-week'),
                tooltip: 'Próxima semana',
                onPressed: () => _changeWeek(1),
                icon: const Icon(Icons.chevron_right_rounded, size: 34),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: days
                .map(
                  (day) => Expanded(
                    child: _CalendarDay(
                      date: day,
                      weekday: _weekdays[day.weekday - 1],
                      selected: _sameDay(day, _selectedDate),
                      trainings: widget.trainings
                          .where((training) => _sameDay(training.date, day))
                          .toList(growable: false),
                      maxIndicators: widget.maxDayIndicators,
                      onTap: () => _selectDate(day),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          if (showEmptyState) ...[
            const SizedBox(height: 18),
            _AgendaEmptyCard(
              icon: Icons.event_busy_outlined,
              title: 'Nenhum treino marcado',
              description: widget.audience == TrainingAgendaAudience.trainer
                  ? 'Não há nenhum treino agendado no período selecionado.\n'
                        'Aproveite para se organizar ou aguarde até que algum '
                        'proprietário vincule você ao cavalo dele e você possa '
                        'prescrever seus treinos.'
                  : 'Não há nenhum treino agendado no período selecionado.\n'
                        'Aproveite para descansar ou entre em contato com um '
                        'treinador para que ele monte o plano ideal para você.',
            ),
          ] else if (weekPlans.isNotEmpty) ...[
            const SizedBox(height: 18),
            _PlanList(plans: weekPlans, onViewPlan: widget.onViewPlan),
          ],
        ],
      ),
    );
  }

  // Monta o treino do dia, o carrossel ou o estado vazio correspondente.
  Widget _buildDailyTrainings(BuildContext context) {
    final trainings = widget.todayTrainings ?? _selectedTrainings;
    final allCompleted =
        trainings.isNotEmpty &&
        trainings.every((training) => training.wasExecuted);
    return _AgendaSection(
      title: 'Treinos do dia',
      child: allCompleted
          ? const _AgendaEmptyCard(
              icon: Icons.event_available_outlined,
              title: 'Todos concluídos',
              description:
                  'Continue assim! Consistência e dedicação são o caminho '
                  'para o sucesso.',
            )
          : trainings.isEmpty
          ? _AgendaEmptyCard(
              icon: Icons.event_busy_outlined,
              title: 'Nenhum treino marcado',
              description: widget.audience == TrainingAgendaAudience.trainer
                  ? 'Aproveite o dia para responder feedbacks ou montar novos '
                        'treinos.'
                  : 'Não há nenhum treino agendado para esta data.',
            )
          : Column(
              children: [
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    controller: _trainingPageController,
                    itemCount: trainings.length,
                    onPageChanged: (page) =>
                        setState(() => _trainingPage = page),
                    itemBuilder: (context, index) => _DailyTrainingCard(
                      training: trainings[index],
                      position: index + 1,
                      total: trainings.length,
                      onStart: widget.onStartTraining,
                      onView: widget.onViewTraining,
                      audience: widget.audience,
                    ),
                  ),
                ),
                if (trainings.length > 1) ...[
                  const SizedBox(height: 10),
                  _PageIndicator(
                    count: trainings.length,
                    selected: _trainingPage,
                    onSelected: (page) => _trainingPageController.animateToPage(
                      page,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  void _openExecutionRecord(BuildContext context, TrainingAgendaEntry entry) {
    Navigator.of(context).push<dynamic>(
      TrainingFeedbackRoute.fromAgenda(
        entry: entry,
        audience: widget.audience,
        repository: widget.feedbackRepository,
      ),
    );
  }

  // Monta as execuções do dia ou a orientação adequada ao público atual.
  Widget _buildHistory(BuildContext context) {
    final history = widget.history ?? _selectedHistory;
    return _AgendaSection(
      title: 'Histórico de execuções',
      child: history.isEmpty
          ? _AgendaEmptyCard(
              icon: Icons.block_rounded,
              title: 'Nenhuma execução registrada',
              description: widget.audience == TrainingAgendaAudience.trainer
                  ? 'Aguarde até que algum atleta execute o treino para que '
                        'você possa ter acesso aos dados e escrever feedbacks.'
                  : 'Execute um treino para registrar o progresso do seu '
                        'animal e poder obter feedbacks do treinador.',
            )
          : Column(
              children: history
                  .map(
                    (training) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _HistoryCard(
                        training: training,
                        onTap: () {
                          if (widget.onViewHistory != null) {
                            widget.onViewHistory!(training);
                          } else {
                            _openExecutionRecord(context, training);
                          }
                        },
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }

  // Retorna os sete dias, de segunda a domingo, da semana selecionada.
  List<DateTime> _daysForVisibleWeek() {
    final monday = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }
}

// Resumo da quantidade de planos e acesso à listagem completa.
class _AgendaSummary extends StatelessWidget {
  const _AgendaSummary({
    required this.count,
    required this.showViewPlans,
    this.onViewPlans,
  });

  final int count;
  final bool showViewPlans;
  final VoidCallback? onViewPlans;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Planos ativos: ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: '$count'),
              ],
            ),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (showViewPlans)
          TextButton(onPressed: onViewPlans, child: const Text('Ver planos')),
      ],
    );
  }
}

// Modal rolável com os planos ativos permitidos ao público atual.
class _ActivePlansSheet extends StatelessWidget {
  const _ActivePlansSheet({
    required this.audience,
    required this.plans,
    required this.onPlanSelected,
  });

  final TrainingAgendaAudience audience;
  final List<TrainingAgendaPlan> plans;
  final ValueChanged<TrainingAgendaPlan> onPlanSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FractionallySizedBox(
      key: const Key('active-plans-sheet'),
      heightFactor: 0.82,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        decoration: const BoxDecoration(
          color: AppColors.whiteSmoke,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                const Icon(Icons.assignment_outlined, size: 36),
                const SizedBox(width: 12),
                Text('Planos ativos', style: theme.textTheme.headlineLarge),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.grey),
            const SizedBox(height: 18),
            Expanded(
              child: plans.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum plano ativo.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    )
                  : ListView.separated(
                      itemCount: plans.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        return _ActivePlanTile(
                          plan: plan,
                          showTrainer:
                              audience == TrainingAgendaAudience.guardian,
                          onTap: () => onPlanSelected(plan),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Item selecionável de plano ativo, com identidade do treinador opcional.
class _ActivePlanTile extends StatelessWidget {
  const _ActivePlanTile({
    required this.plan,
    required this.showTrainer,
    required this.onTap,
  });

  final TrainingAgendaPlan plan;
  final bool showTrainer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.alabasterGray,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        key: ValueKey<String>('active-plan-${plan.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.planName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    if (showTrainer)
                      _InfoRow(
                        icon: const Icon(Icons.sports_rounded, size: 21),
                        text: plan.trainerName,
                      ),
                    _InfoRow(
                      icon: const HorseAssetIcon(size: 21),
                      text: plan.horseName,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, size: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// Superfície visual comum às seções da agenda.
class _AgendaSection extends StatelessWidget {
  const _AgendaSection({this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.alabasterGray,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

// Dia selecionável do calendário com destaque de seleção e indicadores.
class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.weekday,
    required this.selected,
    required this.trainings,
    required this.maxIndicators,
    required this.onTap,
  });

  final DateTime date;
  final String weekday;
  final bool selected;
  final List<TrainingAgendaEntry> trainings;
  final int maxIndicators;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _dayStatusColor(trainings);
    final background = selected ? statusColor ?? AppColors.tropicalTeal : null;
    final foreground = background != null
        ? _contrastingColor(background)
        : AppColors.text;
    final visibleIndicators = math.min(trainings.length, maxIndicators);

    return Semantics(
      selected: selected,
      button: true,
      label: '$weekday, ${date.day}, ${trainings.length} treino(s)',
      child: InkWell(
        key: ValueKey<String>(
          'agenda-day-${date.year}-${date.month}-${date.day}',
        ),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          child: Column(
            children: [
              Text(
                weekday,
                maxLines: 1,
                overflow: TextOverflow.fade,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: date.weekday >= DateTime.saturday
                      ? AppColors.blueSpruce
                      : AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${date.day}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 7,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(
                      visibleIndicators,
                      (_) => Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                          color: AppColors.blueSpruce,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    if (trainings.length > visibleIndicators)
                      Text(
                        '+${trainings.length - visibleIndicators}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.blueSpruce,
                          fontSize: 8,
                          height: 0.8,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Lista semanal limitada visualmente a três planos antes de habilitar rolagem.
class _PlanList extends StatelessWidget {
  const _PlanList({required this.plans, this.onViewPlan});

  final List<TrainingAgendaPlan> plans;
  final ValueChanged<TrainingAgendaPlan>? onViewPlan;

  @override
  Widget build(BuildContext context) {
    final visibleCount = math.min(plans.length, 3);
    final listHeight =
        visibleCount * 224.0 + math.max(0, visibleCount - 1) * 12;
    return SizedBox(
      height: listHeight,
      child: ListView.separated(
        physics: plans.length > 3
            ? const AlwaysScrollableScrollPhysics()
            : const NeverScrollableScrollPhysics(),
        itemCount: plans.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final plan = plans[index];
          return _PlanCard(
            plan: plan,
            onTap: onViewPlan == null ? null : () => onViewPlan!(plan),
          );
        },
      ),
    );
  }
}

// Resumo de um plano associado à semana visível.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, this.onTap});

  final TrainingAgendaPlan plan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 224,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plan.trainingName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          _InfoRow(icon: const HorseAssetIcon(size: 20), text: plan.horseName),
          _InfoRow(
            icon: const Icon(Icons.assignment_outlined, size: 21),
            text: plan.planName,
          ),
          _InfoRow(
            icon: const Icon(Icons.calendar_today_outlined, size: 20),
            text: _formatDate(plan.date),
          ),
          Text(
            'Status: ${_statusLabel(plan.status)}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.seaGreen,
                side: const BorderSide(color: AppColors.seaGreen, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Ver detalhes'),
            ),
          ),
        ],
      ),
    );
  }
}

// Card do carrossel diário, adaptado à ação e ao público permitidos.
class _DailyTrainingCard extends StatelessWidget {
  const _DailyTrainingCard({
    required this.training,
    required this.position,
    required this.total,
    this.onStart,
    this.onView,
    required this.audience,
  });

  final TrainingAgendaEntry training;
  final int position;
  final int total;
  final TrainingAgendaEntryCallback? onStart;
  final TrainingAgendaEntryCallback? onView;
  final TrainingAgendaAudience audience;

  @override
  Widget build(BuildContext context) {
    final canStart = training.action == TrainingAgendaAction.start;
    final callback = canStart ? onStart : onView;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  training.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text('$position/$total'),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: const HorseAssetIcon(size: 21),
            text: training.horseName,
          ),
          if (audience != TrainingAgendaAudience.trainer) ...[
            _InfoRow(
              icon: const Icon(Icons.person_outline, size: 22),
              text: training.trainerName,
            ),
            _InfoRow(
              icon: const Icon(Icons.timer_outlined, size: 22),
              text: '${training.durationMinutes} minutos',
            ),
          ],
          _InfoRow(
            icon: const Icon(Icons.assignment_outlined, size: 22),
            text: training.planName,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.seaGreen, AppColors.blueSpruce],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: callback == null ? null : () => callback(training),
                  borderRadius: BorderRadius.circular(28),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          canStart
                              ? Icons.play_arrow_rounded
                              : Icons.open_in_new_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          canStart ? 'Iniciar treino' : 'Ver treino',
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Execução selecionável exibida no histórico do dia.
class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.training, this.onTap});

  final TrainingAgendaEntry training;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(training.status);
    return Material(
      color: AppColors.whiteSmoke,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.history_rounded),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(training.date),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(_statusLabel(training.status)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      training.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    _InfoRow(
                      icon: const HorseAssetIcon(size: 20),
                      text: training.horseName,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// Linha compacta de ícone e texto usada nos cards da agenda.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox.square(dimension: 24, child: Center(child: icon)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// Indicador navegável da posição atual no carrossel diário.
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final int count;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isSelected = selected == index;
        return InkWell(
          onTap: () => onSelected(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isSelected ? 24 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// Mensagem contextual usada quando uma seção não possui conteúdo.
class _AgendaEmptyCard extends StatelessWidget {
  const _AgendaEmptyCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 34, color: AppColors.text),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.25),
          ),
        ],
      ),
    );
  }
}

// Calcula a cor agregada do dia pela situação de maior atenção.
Color? _dayStatusColor(List<TrainingAgendaEntry> trainings) {
  if (trainings.isEmpty) return null;
  if (trainings.any(
    (training) => training.status == TrainingAgendaStatus.notCompleted,
  )) {
    return AppColors.inferno;
  }
  if (trainings.any(
    (training) => training.status == TrainingAgendaStatus.partial,
  )) {
    return AppColors.goldenApricot;
  }
  if (trainings.every(
    (training) => training.status == TrainingAgendaStatus.completed,
  )) {
    return AppColors.emerald;
  }
  return AppColors.tropicalTeal;
}

// Retorna a cor semântica de uma situação individual.
Color _statusColor(TrainingAgendaStatus status) => switch (status) {
  TrainingAgendaStatus.completed => AppColors.emerald,
  TrainingAgendaStatus.partial => AppColors.goldenApricot,
  TrainingAgendaStatus.notCompleted => AppColors.inferno,
  TrainingAgendaStatus.planned => AppColors.tropicalTeal,
};

// Traduz a situação normalizada para o rótulo apresentado ao usuário.
String _statusLabel(TrainingAgendaStatus status) => switch (status) {
  TrainingAgendaStatus.completed => 'Realizado',
  TrainingAgendaStatus.partial => 'Parcial',
  TrainingAgendaStatus.notCompleted => 'Não realizado',
  TrainingAgendaStatus.planned => 'Planejado',
};

// Escolhe texto claro ou escuro de acordo com o brilho do fundo.
Color _contrastingColor(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : Colors.black;
}

// Remove o horário para permitir comparações exclusivamente por calendário.
DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

// Compara duas datas sem considerar hora ou fuso armazenado.
bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

// Formata uma data no padrão brasileiro usado pelos cards.
String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
