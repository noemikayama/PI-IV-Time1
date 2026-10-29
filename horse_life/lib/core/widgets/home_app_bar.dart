// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Migração do componente para core/widgets e aplicação de gradiente linear
// vertical (whiteSmoke -> alabasterGray) como cor de fundo da AppBar.
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do GuardianRepository e dos modelos com as Cloud
// Functions; documentação das responsabilidades e lógicas principais,
// preservando o comportamento anterior da interface.
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão de compatibilidade da Home com os cards e cenários simulados; estrutura e comportamentos existentes preservados.
//
// Data: 13/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação da estrutura inicial da Home do Responsável,
// seguindo a arquitetura e os padrões visuais oficiais do HorseLife.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Cabeçalho institucional com ação para abrir o Drawer da Screen e fundo em gradiente.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(85);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Fundo transparente e sem elevação padrão para exibição nítida do gradiente.
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      toolbarHeight: 85,

      // Gradiente linear do topo central à parte de baixo central (whiteSmoke -> alabasterGray).
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.alabasterGray,
              AppColors.whiteSmoke,
            ],
          ),
        ),
      ),

      // Botão que abre a Sidebar lateral.
      leading: Builder(
        builder: (context) {
          return IconButton(
            tooltip: 'Abrir menu',
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.seaGreen,
              size: 36,
            ),
          );
        },
      ),

      // Logo institucional exibida no canto direito da barra.
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Image.asset(
            'assets/Logo_HorseLife.png',
            width: 48,
            height: 48,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
