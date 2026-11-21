// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 09/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da listagem rolável de regiões de atendimento, com ação
// de inclusão e estado vazio orientativo.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Bottom sheet de consulta das regiões de atendimento do treinador.
class TrainerServiceRegionsSheet extends StatelessWidget {
  const TrainerServiceRegionsSheet({
    required this.regions,
    required this.onAdd,
    super.key,
  });

  /// Textos formatados a partir de estado, cidade e complemento remotos.
  final List<String> regions;

  /// Inicia o fluxo compartilhado de escolha de abrangência.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FractionallySizedBox(
      heightFactor: 0.72,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.whiteSmoke,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.grey,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Regiões de atendimento',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Divider(indent: 24, endIndent: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('add-trainer-service-region-button'),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adicionar'),
                ),
              ),
            ),
            Expanded(
              child: regions.isEmpty
                  ? const _EmptyServiceRegions()
                  : ListView.separated(
                      key: const Key('trainer-service-regions-scroll'),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                      itemCount: regions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final region = regions[index];
                        return Container(
                          key: ValueKey('trainer-service-region-$index'),
                          constraints: const BoxConstraints(minHeight: 76),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.alabasterGray.withValues(
                              alpha: 0.45,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.blueSpruce,
                                size: 34,
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Text(
                                  region,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(color: AppColors.text),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyServiceRegions extends StatelessWidget {
  const _EmptyServiceRegions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 22, 36, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.block_rounded,
                  key: Key('empty-service-regions-icon'),
                  color: AppColors.text,
                  size: 38,
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    'Nenhuma região informada',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Adicione uma para que os usuários saibam onde podem usar seus serviços.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.text,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
