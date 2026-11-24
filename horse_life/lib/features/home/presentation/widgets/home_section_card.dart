// RESPONSÁVEL PELA ATUALIZAÇÃO: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 23/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão de padding configurável para propagar ajustes visuais a
// seções específicas sem modificar os demais cards compartilhados da Home.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Ajuste da tipografia do botão "Mostrar tudo" para labelMedium conforme o tema.
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
import 'package:horse_life/app/theme/app_colors.dart';

/// Estrutura visual reutilizável para as seções da Home.
class HomeSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onShowAll;
  final EdgeInsetsGeometry padding;

  const HomeSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.onShowAll,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: padding,
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
