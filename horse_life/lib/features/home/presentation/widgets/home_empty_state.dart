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
import '../../../../app/theme/app_colors.dart';

/// Estado vazio visual comum aos cards da Home.
/// Apresenta mensagens de ausência de dados sem duplicar layout nos cards.
class HomeEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HomeEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 24, color: AppColors.text),
              const SizedBox(width: 10),
              Expanded(child: Text(title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 10),
          Text(description, style: theme.textTheme.bodyMedium),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_box_outlined),
                label: Text(actionLabel!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
