// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 30/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do uso compartilhado e do status opcional.
//
// Data: 28/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do cabeçalho reutilizável de identidade com nome, e-mail
// e indicador opcional de situação profissional.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Cabeçalho compartilhado pelos perfis de responsável e treinador.
/// O status é opcional porque somente o treinador possui situação profissional.
class ProfileIdentityHeader extends StatelessWidget {
  const ProfileIdentityHeader({
    required this.name,
    required this.email,
    this.status,
    super.key,
  });

  final String name;
  final String email;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleStatus = status?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(email, style: theme.textTheme.bodyLarge),
        if (visibleStatus != null && visibleStatus.isNotEmpty) ...[
          const SizedBox(height: 12),
          DecoratedBox(
            key: const Key('profile-status-chip'),
            decoration: BoxDecoration(
              color: AppColors.pearlAqua,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text(
                visibleStatus,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
