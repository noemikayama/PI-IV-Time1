// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação da estrutura inicial da Home do Responsável,
// seguindo a arquitetura e os padrões visuais oficiais do HorseLife.
// -----------------------------------------------------------------------------
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão de compatibilidade da Home com os cards e cenários simulados; estrutura e comportamentos existentes preservados.
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

/// Cabeçalho institucional com ação para abrir o Drawer da Screen.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(85);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      // Cor e elevação herdadas do AppTheme.
      centerTitle: true,
      toolbarHeight: 85,

      // Botão que abre a Sidebar.
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

      // Título com a fonte oficial League Spartan.
      title: Text(
        'HorseLife',
        style: theme.textTheme.headlineMedium?.copyWith(
          color: AppColors.seaGreen,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Logo oficial já existente no projeto.
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Image.asset(
            'assets/Logo_somente_simbolo.png',
            width: 42,
            height: 42,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
