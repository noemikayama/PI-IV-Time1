// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Readequação da altura dos cards para 326px (métricas em 155px e feedback em 125px),
// proporções quadradas, e ampliação do donut de planos para preencher a largura do card.
//
// Data: 30/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Painel profissional modular com períodos, métricas e donut de planos.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Remoção dos valores profissionais simulados; apresentação recebe somente dados mapeados da Function.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários pontuais sobre a responsabilidade do arquivo.
//
// Data: 11/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Uso direto do tema nos títulos e indicadores do painel profissional.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import '../../data/models/trainer_professional_snapshot.dart';
import 'dashboard_plans_donut.dart';

/// Exibe métricas profissionais recebidas do backend.
class TrainerProfessionalContent extends StatelessWidget {
  const TrainerProfessionalContent({
    super.key,
    required this.liveData,
    this.onPeriodChanged,
  });

  final TrainerProfessionalSnapshot liveData;
  final ValueChanged<String>? onPeriodChanged;

  static const _green = [AppColors.seaGreen, AppColors.pearlAqua];
  static const _orange = [AppColors.goldenApricot, Color(0xFFFFC488)];
  static const _blue = [AppColors.tropicalTeal, AppColors.prussianBlue];
  static const _purple = [Color(0xFFD5B4D5), AppColors.pearlAqua];

  @override
  Widget build(BuildContext context) {
    final data = liveData;
    return LayoutBuilder(
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
                      context,
                      'Planos criados até o momento',
                      '0',
                      _green,
                      height: 155,
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: _stat(
                      context,
                      'Planos ativos até o momento',
                      '0',
                      _orange,
                      height: 155,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _stat(
                context,
                'Percentual de feedbacks dados',
                '0%',
                _purple,
                height: 125,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      context,
                      'Clientes vinculados',
                      '${data.clients}',
                      _orange,
                      height: 155,
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: _stat(
                      context,
                      'Cavalos vinculados',
                      '${data.linkedHorses}',
                      _blue,
                      height: 155,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      context,
                      'Avaliações feitas até o momento',
                      '${data.evaluations}',
                      _orange,
                      height: 155,
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: _stat(
                      context,
                      'Exercícios criados até o momento',
                      '${data.exercises}',
                      _green,
                      height: 155,
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
                  height: 326,
                  child: _plansCard(context, data),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: Column(
                    children: [
                      _stat(
                        context,
                        'Clientes vinculados',
                        '${data.clients}',
                        _orange,
                        height: 155,
                      ),
                      const SizedBox(height: 16),
                      _stat(
                        context,
                        'Cavalos vinculados',
                        '${data.linkedHorses}',
                        _blue,
                        height: 155,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _stat(
              context,
              'Percentual de feedbacks dados',
              '${data.feedbackPercent}%',
              _purple,
              height: 125,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _stat(
                    context,
                    'Avaliações feitas até o momento',
                    '${data.evaluations}',
                    _orange,
                    height: 155,
                  ),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: _stat(
                    context,
                    'Exercícios criados até o momento',
                    '${data.exercises}',
                    _green,
                    height: 155,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _stat(
    BuildContext context,
    String title,
    String value,
    List<Color> colors, {
    double height = 155,
  }) => Container(
    height: height,
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.1,
            letterSpacing: 0,
            color: Colors.white,
          ),
        ),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontSize: 48,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                  letterSpacing: 0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _plansCard(
    BuildContext context,
    TrainerProfessionalSnapshot data,
  ) => Container(
    padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
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
        Text(
          'Planos criados',
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.0,
            letterSpacing: 0,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.whiteSmoke,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const SizedBox(height: 2),
                SizedBox(
                  height: 116,
                  child: DashboardPlansDonut(
                    active: data.activePlans,
                    completed: data.completedPlans,
                    cancelled: data.cancelledPlans,
                  ),
                ),
                const SizedBox(height: 4),
                _legend('Ativos', AppColors.pearlAqua),
                _legend('Concluídos', AppColors.blueSpruce),
                _legend('Cancelados', AppColors.inferno),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'total: ',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 18,
                            height: 1,
                          ),
                        ),
                      ),
                      Text(
                        '${data.createdPlans}',
                        style: const TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 42,
                          height: 1,
                        ),
                      ),
                    ],
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
    padding: const EdgeInsets.only(top: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(height: 10, width: 10, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontFamily: 'Urbanist', fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
