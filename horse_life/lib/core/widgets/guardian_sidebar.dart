// RESPONSÁVEL: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Adição do link funcional "Cadastrar cavalo" na barra lateral do
// responsável para abertura direta do fluxo de cadastro de cavalos.
//
// Data: 27/10/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Migração do componente para core/widgets com ajuste dos imports.
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
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/features/home/data/models/guardian_home_data.dart';
import 'package:horse_life/features/horses/presentation/routes/horse_registration_flow_route.dart';

/// Menu lateral que compartilha a Future da Home e mantém o fluxo de logout recebido por callback.
class GuardianSidebar extends StatefulWidget {
  const GuardianSidebar({
    required this.onLogout,
    this.homeFuture,
    this.onRegisterHorse,
    super.key,
  });

  final Future<GuardianHomeData>? homeFuture;

  final Future<void> Function() onLogout;

  /// Callback opcional que permite sobrescrever a abertura do fluxo de cadastro
  /// de cavalos em composições externas ou testes.
  final VoidCallback? onRegisterHorse;

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
  ];

  // Fecha o menu lateral e direciona o responsável ao fluxo de cadastro de cavalos.
  void _handleRegisterHorse() {
    final navigator = Navigator.of(context);
    navigator.pop();

    final onRegisterHorse = widget.onRegisterHorse;
    if (onRegisterHorse != null) {
      onRegisterHorse();
      return;
    }

    navigator.push(HorseRegistrationFlowRoute.build());
  }

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
                        // Reutiliza a mesma Future da Home, evitando uma segunda chamada ao servidor.
                        FutureBuilder<GuardianHomeData>(
                          future: widget.homeFuture,
                          builder: (context, snapshot) => Text(
                            snapshot.data?.guardianName ?? '<Usuário>',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        Text(
                          'Conta de responsável',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),

                        FutureBuilder<GuardianHomeData>(
                          future: widget.homeFuture,
                          builder: (context, snapshot) => Text(
                            'Animais registrados: ${snapshot.data?.horsesCount ?? 0}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                            ),
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

              ListTile(
                key: const Key('guardian-sidebar-register-horse'),
                contentPadding: EdgeInsets.zero,
                minTileHeight: 50,
                leading: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                title: Text(
                  'Cadastrar cavalo',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                onTap: _handleRegisterHorse,
              ),

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

