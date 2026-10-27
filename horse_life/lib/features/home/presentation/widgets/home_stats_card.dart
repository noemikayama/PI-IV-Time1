// RESPONSÁVEL PELA ATUALIZAÇÃO: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização dos componentes da Home e dos estados simulados.
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do Guardian à arquitetura Repository/Mapper/Service.
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Extração do componente genérico reutilizável por Guardian e
// Professional, preservando os contratos e visuais de ambos os perfis.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// Os dois layouts existentes são preservados enquanto os dados e a API
/// de renderização tornam-se compartilhados entre Guardian e Professional.
enum HomeStatsCardStyle { guardian, professional }

class HomeStatsCard extends StatelessWidget {
  const HomeStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.gradientColors,
    this.total,
    this.style = HomeStatsCardStyle.guardian,
  });

  final String title;
  final int value;
  final int? total;
  final List<Color> gradientColors;
  final HomeStatsCardStyle style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = style == HomeStatsCardStyle.professional;
    final number = RichText(
      text: TextSpan(children: [
        TextSpan(
          text: '$value',
          style: theme.textTheme.displayMedium?.copyWith(
            color: Colors.white,
            fontSize: compact ? 48 : 52,
            fontWeight: compact ? FontWeight.w400 : FontWeight.w500,
          ),
        ),
        // O Professional omite '/0'; o Guardian preserva sua exibição.
        if (total != null && (!compact || total! > 0))
          TextSpan(
            text: '/$total',
            style: compact
                ? theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white, fontSize: 16)
                : theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
      ]),
    );

    if (compact) {
      return Container(
        height: 150,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 0.98,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: FittedBox(fit: BoxFit.scaleDown, child: number),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Center(child: FittedBox(fit: BoxFit.scaleDown, child: number)),
        ],
      ),
    );
  }
}
