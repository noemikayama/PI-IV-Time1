// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// HISTÓRICO DE ALTERAÇÕES
// 30/10/2026 - Painel profissional modular com períodos, métricas e donut de planos.
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import '../../data/trainer_dashboard_mock_data.dart';
import 'dashboard_plans_donut.dart';
import 'dashboard_text_styles.dart';

class TrainerProfessionalContent extends StatefulWidget {
  const TrainerProfessionalContent({super.key, this.forceEmpty = false});
  final bool forceEmpty;
  @override
  State<TrainerProfessionalContent> createState() =>
      _TrainerProfessionalContentState();
}

class _TrainerProfessionalContentState
    extends State<TrainerProfessionalContent> {
  String _period = 'Desde sempre';
  @override
  Widget build(BuildContext context) {
    final data = widget.forceEmpty
        ? TrainerProfessionalSnapshot.empty
        : TrainerDashboardMockData.forPeriod(_period);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: ActionChip(
            avatar: const Icon(Icons.hourglass_empty, color: Colors.black),
            label: Text(
              _period,
              style: const TextStyle(fontFamily: 'Urbanist', fontSize: 16),
            ),
            backgroundColor: AppColors.alabasterGray,
            side: BorderSide.none,
            onPressed: () => _selectPeriod(context),
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 16.0;
            final width = (constraints.maxWidth - gap) / 2;
            if (data.createdPlans == 0) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _stat(
                          'Planos criados até o momento',
                          '0',
                          _green,
                        ),
                      ),
                      const SizedBox(width: gap),
                      Expanded(
                        child: _stat(
                          'Planos ativos até o momento',
                          '0',
                          _orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _stat(
                    'Percentual de feedbacks dados',
                    '0%',
                    _blue,
                    height: 156,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _stat(
                          'Clientes vinculados',
                          '${data.clients}',
                          _purple,
                        ),
                      ),
                      const SizedBox(width: gap),
                      Expanded(
                        child: _stat(
                          'Cavalos vinculados',
                          '${data.linkedHorses}',
                          _green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _stat(
                          'Avaliações feitas até o momento',
                          '${data.evaluations}',
                          _orange,
                        ),
                      ),
                      const SizedBox(width: gap),
                      Expanded(
                        child: _stat(
                          'Exercícios criados até o momento',
                          '${data.exercises}',
                          _blue,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: width,
                      height: 410,
                      child: _plansCard(data),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: Column(
                        children: [
                          _stat(
                            'Clientes vinculados',
                            '${data.clients}',
                            _orange,
                            height: 197,
                          ),
                          const SizedBox(height: 16),
                          _stat(
                            'Cavalos vinculados',
                            '${data.linkedHorses}',
                            _blue,
                            height: 197,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _stat(
                  'Percentual de feedbacks dados',
                  '${data.feedbackPercent}%',
                  _purple,
                  height: 160,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _stat(
                        'Avaliações feitas até o momento',
                        '${data.evaluations}',
                        _orange,
                      ),
                    ),
                    const SizedBox(width: gap),
                    Expanded(
                      child: _stat(
                        'Exercícios criados até o momento',
                        '${data.exercises}',
                        _green,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  static const _green = [AppColors.seaGreen, AppColors.pearlAqua];
  static const _orange = [AppColors.goldenApricot, Color(0xFFFFC488)];
  static const _blue = [AppColors.tropicalTeal, AppColors.prussianBlue];
  static const _purple = [Color(0xFFD5B4D5), AppColors.pearlAqua];

  Widget _stat(
    String title,
    String value,
    List<Color> colors, {
    double height = 205,
  }) => Container(
    height: height,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: DashboardTextStyles.cardTitle(context)),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: DashboardTextStyles.metricValue(context),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _plansCard(TrainerProfessionalSnapshot data) => Container(
    padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        colors: _green,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Planos criados', style: DashboardTextStyles.cardTitle(context)),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.whiteSmoke,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                DashboardPlansDonut(
                  active: data.activePlans,
                  completed: data.completedPlans,
                  cancelled: data.cancelledPlans,
                ),
                const SizedBox(height: 8),
                _legend('Ativos', AppColors.pearlAqua),
                _legend('Concluídos', AppColors.blueSpruce),
                _legend('Cancelados', AppColors.inferno),
                const Spacer(),
                FittedBox(
                  child: Text(
                    'total: ${data.createdPlans}',
                    style: const TextStyle(
                      fontFamily: 'Urbanist',
                      fontSize: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _legend(String label, Color color) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(height: 12, width: 12, color: color),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(fontFamily: 'Urbanist', fontSize: 12),
        ),
      ],
    ),
  );

  Future<void> _selectPeriod(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Selecionar período',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...TrainerDashboardMockData.periods.map(
              (p) => ListTile(
                leading: p == _period
                    ? const Icon(Icons.check, color: AppColors.seaGreen)
                    : const SizedBox(width: 24),
                title: Text(p),
                onTap: () => Navigator.pop(context, p),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _period = selected);
  }
}
