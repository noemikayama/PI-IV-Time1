// RESPONSÁVEL PELA ATUALIZAÇÃO: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Ajuste da tipografia do botão "Mostrar tudo" para labelMedium conforme o tema.
// -----------------------------------------------------------------------------
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão e padronização dos componentes e dados simulados da Home do Responsável, preservando a integração existente.
// -----------------------------------------------------------------------------
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do GuardianRepository e dos modelos com as Cloud
// Functions; documentação das responsabilidades e lógicas principais,
// preservando o comportamento anterior da interface.
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Estrutura visual reutilizável para as seções da Home.
class GuardianSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onShowAll;

  const GuardianSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.blueSpruce,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (onShowAll != null)
                TextButton(
                  onPressed: onShowAll,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    textStyle: theme.textTheme.labelMedium,
                  ),
                  child: Text(
                    'Mostrar tudo',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
