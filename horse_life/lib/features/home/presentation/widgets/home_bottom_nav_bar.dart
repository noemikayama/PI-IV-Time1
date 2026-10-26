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
import '../../../../app/theme/app_colors.dart';

/// Barra inferior controlada pela Screen; recebe índice ativo e callback de seleção.
class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    required this.selectedIndex,
    required this.onItemSelected,
    super.key,
  });

  // Estado e ação recebidos da Home.
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  // Configurações do ícone personalizado.
  static const double _horseIconWidth = 36;
  static const double _horseIconHeight = 36;
  static const double _horseIconScale = 0.8;

  // Configurações dos demais ícones.
  static const double _defaultIconSize = 30;
  static const double _iconContainerHeight = 48;

  // Asset do ícone de cavalo.
  static const String _horseIconPath = 'assets/black-head-horse.png';

  // Ícones da barra de navegação.
  static const List<IconData?> _icons = [
    Icons.home_rounded,
    Icons.calendar_month_rounded,
    null, // Cavalos utiliza a imagem personalizada.
    Icons.bar_chart_rounded,
    Icons.person_rounded,
  ];

  // Identificação das opções.
  static const List<String> _labels = [
    'Home',
    'Treinos',
    'Cavalos',
    'Dashboard',
    'Perfil',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
          child: Row(
            children: List.generate(_labels.length, (index) {
              final isSelected = selectedIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => onItemSelected(index),
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Área visual de seleção.
                        Container(
                          width: double.infinity,
                          height: _iconContainerHeight,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.pearlAqua
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(28),
                          ),

                          // Ícone de cada opção.
                          child: index == 2
                              ? Center(
                                  child: Transform.scale(
                                    scale: _horseIconScale,
                                    child: Image.asset(
                                      _horseIconPath,
                                      width: _horseIconWidth,
                                      height: _horseIconHeight,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                )
                              : Icon(
                                  _icons[index],
                                  color: AppColors.text,
                                  size: _defaultIconSize,
                                ),
                        ),

                        const SizedBox(height: 4),

                        // Rótulo com tipografia do tema.
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _labels[index],
                            maxLines: 1,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
