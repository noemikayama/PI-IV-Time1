// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Implementação do menu lateral do Profissional com especialidade,
// quantidade de cavalos vinculados e saída protegida contra toques repetidos.
// -----------------------------------------------------------------------------
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão de integração e compatibilidade com a arquitetura
// Repository/Mapper/Service, sem alterar a composição visual aprovada.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import '../../data/models/professional_home_data.dart';

class ProfessionalSidebar extends StatefulWidget {
  const ProfessionalSidebar({
    super.key,
    required this.onLogout,
    required this.homeFuture,
  });

  final Future<void> Function() onLogout;
  final Future<ProfessionalHomeData> homeFuture;

  @override
  State<ProfessionalSidebar> createState() => _ProfessionalSidebarState();
}

class _ProfessionalSidebarState extends State<ProfessionalSidebar> {
  bool _isLoggingOut = false;

  // Itens provisórios do protótipo; substituir ao integrar as respectivas rotas.
  static const List<String> _menuItems = ['Item 1', 'Item 1', 'Item 1', 'Item 1'];

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await widget.onLogout();
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline,
        message: 'Não foi possível sair. Tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      backgroundColor: AppColors.blueSpruce,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<ProfessionalHomeData>(
                future: widget.homeFuture,
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  return Row(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.alabasterGray,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data?.professionalName ?? '<Usuário>',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Treinador de ${data?.specialty ?? '<modalidade>'}',
                              maxLines: 2,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Animais vinculados: ${data?.linkedHorsesCount ?? 0}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              const Divider(color: AppColors.alabasterGray),
              const SizedBox(height: 12),
              ..._menuItems.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: 48,
                  leading: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  title: Text(
                    item,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  // Não executar rotas fictícias enquanto as telas não existirem.
                  onTap: null,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.alabasterGray),
              const SizedBox(height: 8),
              ListTile(
                enabled: !_isLoggingOut,
                contentPadding: EdgeInsets.zero,
                leading: _isLoggingOut
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.logout_rounded, color: Colors.white),
                title: Text(
                  _isLoggingOut ? 'Saindo...' : 'Sair',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                onTap: _isLoggingOut ? null : _handleLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
