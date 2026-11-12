// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 09/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da listagem rolável de certificações, com abertura de PDF,
// ação de inclusão e estado vazio orientativo.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/features/profile/data/models/trainer_profile_data.dart';

/// Bottom sheet de consulta das certificações já confirmadas pelo backend.
class TrainerCertificationsSheet extends StatelessWidget {
  const TrainerCertificationsSheet({
    required this.certifications,
    required this.onOpen,
    required this.onAdd,
    super.key,
  });

  /// Documentos remotos que podem ser abertos pelo leitor compartilhado.
  final List<TrainerExperienceDocument> certifications;

  /// Fecha o sheet e entrega o documento selecionado à tela de perfil.
  final ValueChanged<TrainerExperienceDocument> onOpen;

  /// Abre o modal de seleção de novas certificações.
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
                  'Certificações',
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
                  key: const Key('add-trainer-certification-button'),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Adicionar'),
                ),
              ),
            ),
            Expanded(
              child: certifications.isEmpty
                  ? const _EmptyCertifications()
                  : ListView.separated(
                      key: const Key('trainer-certifications-scroll'),
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                      itemCount: certifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final document = certifications[index];
                        return Material(
                          color: AppColors.alabasterGray.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            key: ValueKey(
                              'trainer-certification-${document.fileName}',
                            ),
                            minTileHeight: 76,
                            leading: const Icon(
                              Icons.picture_as_pdf_outlined,
                              color: AppColors.blueSpruce,
                              size: 34,
                            ),
                            title: Text(
                              document.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppColors.text,
                              ),
                            ),
                            trailing: Text(
                              'Abrir',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppColors.blueSpruce,
                              ),
                            ),
                            onTap: () => onOpen(document),
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

class _EmptyCertifications extends StatelessWidget {
  const _EmptyCertifications();

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
                  key: Key('empty-trainer-certifications-icon'),
                  color: AppColors.text,
                  size: 38,
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Text(
                    'Nenhuma certificação anexada',
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
              'Adicione uma para que os usuários vejam o que você alcançou.',
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
