// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 29/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Cards independentes de treinos e feedbacks, com rolagem horizontal.
//
// Data: 30/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Refinamento Figma: tipografia, espaçamento, ícones, botão em degradê.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Exclusão de treinos e feedbacks fictícios; cards renderizam apenas registros retornados pelo backend.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários pontuais sobre a responsabilidade do arquivo.
//
// Data: 11/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Uso direto do tema nos títulos das listas de treinos e feedbacks.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Mostra registros reais recentes com rolagem lateral e estado vazio.
class DashboardRecentList extends StatelessWidget {
  const DashboardRecentList({
    super.key,
    required this.title,
    this.feedback = false,
    this.onShowAll,
    this.onItemTap,
    this.liveTrainings = const [],
    this.liveFeedbacks = const [],
  });
  final String title;
  final bool feedback;
  final List<Map<String, dynamic>> liveTrainings, liveFeedbacks;
  final VoidCallback? onShowAll, onItemTap;

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final count = feedback ? liveFeedbacks.length : liveTrainings.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.blueSpruce,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: 0,
                    color: Colors.white,
                  ),
                ),
              ),
              if (count > 0)
                TextButton(
                  onPressed: onShowAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                  ),
                  child: const Text(
                    'Mostrar tudo',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      color: Colors.white70,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (count == 0)
            _emptyList()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // Mostra o início do próximo card, indicando a rolagem lateral.
                final cardWidth = constraints.maxWidth <= 230
                    ? constraints.maxWidth
                    : constraints.maxWidth * .92;
                return SizedBox(
                  height: 245,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.hardEdge,
                    itemCount: count,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => SizedBox(
                      width: cardWidth,
                      child: feedback
                          ? _liveFeedbackCard(liveFeedbacks[index])
                          : _liveTrainingCard(liveTrainings[index]),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _emptyList() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
    decoration: BoxDecoration(
      color: AppColors.whiteSmoke,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Icon(
          feedback ? Icons.rate_review_outlined : Icons.event_busy_outlined,
          size: 34,
        ),
        const SizedBox(height: 10),
        Text(
          feedback
              ? 'Nenhum feedback neste filtro.'
              : 'Nenhum treino neste filtro.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'LeagueSpartan',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Experimente selecionar outro cavalo ou período.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Urbanist', fontSize: 13),
        ),
      ],
    ),
  );

  Widget _liveTrainingCard(Map<String, dynamic> item) => _card(
    title: item['nomeTreino']?.toString() ?? '',
    details: [
      _detail(Icons.pets, item['nomeCavalo']?.toString() ?? ''),
      _detail(Icons.assignment_outlined, item['nomePlano']?.toString() ?? ''),
      _detail(Icons.event_available_outlined, _liveDate(item['data'])),
    ],
    buttonLabel: 'Ver treino',
    buttonIcon: Icons.open_in_new,
  );
  Widget _liveFeedbackCard(Map<String, dynamic> item) => _card(
    title: item['nomeTreino']?.toString() ?? '',
    details: [
      _detail(Icons.feedback_outlined, item['nomeTreino']?.toString() ?? ''),
      _detail(Icons.assignment_outlined, item['nomePlano']?.toString() ?? ''),
      _detail(Icons.event_available_outlined, _liveDate(item['data'])),
    ],
    buttonLabel: 'Ver feedback',
    buttonIcon: Icons.open_in_new,
  );
  String _liveDate(Object? date) {
    final parsed = DateTime.tryParse(date?.toString() ?? '');
    return parsed == null ? '' : _date(parsed);
  }

  Widget _card({
    required String title,
    required List<Widget> details,
    required String buttonLabel,
    required IconData buttonIcon,
  }) => Container(
    padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
    decoration: BoxDecoration(
      color: AppColors.whiteSmoke,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'LeagueSpartan',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...details,
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [AppColors.seaGreen, AppColors.blueSpruce],
              ),
            ),
            child: InkWell(
              onTap: onItemTap,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 45,
                width: double.infinity,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonLabel,
                        style: const TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(buttonIcon, size: 18, color: Colors.white),
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

  Widget _detail(IconData icon, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.text),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 15,
              height: 1.1,
            ),
          ),
        ),
      ],
    ),
  );
}
