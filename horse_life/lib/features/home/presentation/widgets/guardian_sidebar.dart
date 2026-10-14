import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';

class GuardianSidebar extends StatefulWidget {
  const GuardianSidebar({required this.onLogout, super.key});

  final Future<void> Function() onLogout;

  @override
  State<GuardianSidebar> createState() => _GuardianSidebarState();
}

class _GuardianSidebarState extends State<GuardianSidebar> {
  bool _isLoggingOut = false;

  // Itens provisórios da Sidebar.
  static const List<String> _menuItems = [
    'Item 1',
    'Item 1',
    'Item 1',
    'Item 1',
  ];

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

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
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
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
              // Cabeçalho do responsável.
              Row(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.alabasterGray,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '<Usuário>',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        Text(
                          'Conta de responsável',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),

                        Text(
                          'Animais registrados: 0',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Divider(color: AppColors.alabasterGray),

              const SizedBox(height: 12),

              // Itens provisórios.
              ..._menuItems.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  minTileHeight: 50,
                  leading: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  title: Text(
                    item,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),

                  // Sem ação até as telas serem criadas.
                  onTap: null,
                ),
              ),

              const SizedBox(height: 12),

              const Divider(color: AppColors.alabasterGray),

              const SizedBox(height: 8),

              // Botão de logout.
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: !_isLoggingOut,

                leading: _isLoggingOut
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 28,
                      ),

                title: Text(
                  _isLoggingOut ? 'Saindo...' : 'Sair',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 21,
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
