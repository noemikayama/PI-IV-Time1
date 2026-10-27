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
import 'package:horse_life/app/theme/app_colors.dart';
import 'horse_asset_icon.dart';

enum HomeListTileDensity { spacious, compact }

/// Uma única implementação de linha; tamanho e ícones dependem do layout.
class HomeListTile extends StatelessWidget {
  const HomeListTile({
    super.key,
    required this.label,
    this.icon = Icons.person,
    this.useHorseAsset = false,
    this.showArrow = false,
    this.onTap,
    this.density = HomeListTileDensity.spacious,
  });

  final String label;
  final IconData icon;
  final bool useHorseAsset;
  final bool showArrow;
  final VoidCallback? onTap;
  final HomeListTileDensity density;

  @override
  Widget build(BuildContext context) {
    final compact = density == HomeListTileDensity.compact;
    final radius = compact ? 13.0 : 18.0;
    return Material(
      color: AppColors.whiteSmoke,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: SizedBox(
          height: compact ? 56 : 70,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18),
            child: Row(
              children: [
                useHorseAsset
                    ? HorseAssetIcon(size: compact ? 25 : 28)
                    : Icon(
                        icon,
                        size: compact ? 23.0 : 28.0,
                        color: compact ? null : AppColors.prussianBlue,
                      ),
                SizedBox(width: compact ? 8 : 14),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: compact
                        ? Theme.of(context).textTheme.bodyMedium
                        : Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                if (showArrow)
                  Icon(
                    compact ? Icons.chevron_right_rounded : Icons.chevron_right,
                    size: compact ? 24.0 : null,
                    color: compact ? null : AppColors.prussianBlue,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
