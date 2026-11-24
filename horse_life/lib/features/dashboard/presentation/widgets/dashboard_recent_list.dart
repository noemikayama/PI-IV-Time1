// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Padronização do card de Últimos Feedbacks com HomeSectionCard e
// carrossel horizontal unificado ao modelo de Últimos treinos.
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Adequação dos treinos recentes ao padrão HomeSectionCard, com
// padding uniforme, rolagem horizontal, ícone oficial do cavalo, data e ação
// por treinamento.
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
import 'package:horse_life/features/home/presentation/widgets/home_section_card.dart';
import 'package:horse_life/features/home/presentation/widgets/horse_asset_icon.dart';

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
  final VoidCallback? onShowAll;
  final ValueChanged<Map<String, dynamic>>? onItemTap;

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Constrói a lista horizontal ou o estado vazio do card.
  ///
  /// Mantém a padronização visual entre a listagem de treinos recentes e feedbacks
  /// utilizando o [HomeSectionCard] com padding uniforme e botão "Mostrar tudo" condicional.
  @override
  Widget build(BuildContext context) {
    final count = feedback ? liveFeedbacks.length : liveTrainings.length;
    return HomeSectionCard(
      title: title,
      padding: const EdgeInsets.all(18),
      onShowAll: count > 0 ? onShowAll : null,
      child: count == 0 ? _emptyList() : _carousel(count),
    );
  }

  /// Mantém cada registro como um item independente e revela parte do próximo
  /// card para comunicar visualmente que o conteúdo aceita gesto de rolagem lateral.
  ///
  /// Utiliza identificadores de chave estáveis ([listKey] e [itemPrefix]) para
  /// diferenciar treinos e feedbacks em testes automatizados.
  Widget _carousel(int count) => LayoutBuilder(
    builder: (context, constraints) {
      final cardWidth = count == 1 || constraints.maxWidth <= 250
          ? constraints.maxWidth
          : constraints.maxWidth * .9;
      final listKey = feedback
          ? const Key('dashboard-recent-feedback-list')
          : const Key('dashboard-recent-training-list');
      final itemPrefix = feedback
          ? 'dashboard-recent-feedback-item-'
          : 'dashboard-recent-training-item-';
      return SizedBox(
        height: 235,
        child: ListView.separated(
          key: listKey,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          itemCount: count,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, index) => SizedBox(
            key: Key('$itemPrefix$index'),
            width: cardWidth,
            child: feedback
                ? _liveFeedbackCard(liveFeedbacks[index])
                : _liveTrainingCard(liveTrainings[index]),
          ),
        ),
      );
    },
  );

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
      _detailWidget(
        const HorseAssetIcon(size: 20),
        item['nomeCavalo']?.toString() ?? '',
      ),
      _detail(Icons.assignment_outlined, item['nomePlano']?.toString() ?? ''),
      _detail(Icons.event_available_outlined, _liveDate(item['data'])),
    ],
    buttonLabel: 'Ver treino',
    buttonIcon: Icons.open_in_new,
    onTap: onItemTap == null ? null : () => onItemTap!(item),
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
    onTap: onItemTap == null ? null : () => onItemTap!(item),
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
    VoidCallback? onTap,
  }) => Container(
    padding: const EdgeInsets.all(18),
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
              onTap: onTap,
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

  Widget _detail(IconData icon, String value) =>
      _detailWidget(Icon(icon, size: 20, color: AppColors.text), value);

  Widget _detailWidget(Widget icon, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        SizedBox(width: 20, height: 20, child: Center(child: icon)),
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
