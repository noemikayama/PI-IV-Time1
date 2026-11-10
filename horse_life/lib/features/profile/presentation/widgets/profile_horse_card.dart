// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do card reutilizável de cavalo com imagem remota e fallback.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Card compartilhado pelos perfis que exibem um vínculo com um cavalo.
class ProfileHorseCard extends StatelessWidget {
  const ProfileHorseCard({
    required this.name,
    required this.relationship,
    this.imageUrl,
    super.key,
  });

  /// Nome do cavalo.
  final String name;

  /// Papel do usuário em relação ao cavalo, exibido abaixo do nome.
  final String relationship;

  /// Imagem assinada opcional; falhas de rede também usam o fallback local.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 190,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 112,
            width: double.infinity,
            child: _HorseImage(imageUrl: imageUrl),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 3),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFC6E9E1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  relationship,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HorseImage extends StatelessWidget {
  const _HorseImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) return const _HorseImageFallback();

    return Image.network(
      url,
      key: const Key('profile-horse-network-image'),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _HorseImageFallback(),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const ColoredBox(
              color: AppColors.alabasterGray,
              child: Center(child: CircularProgressIndicator()),
            ),
    );
  }
}

class _HorseImageFallback extends StatelessWidget {
  const _HorseImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const Key('profile-horse-image-fallback'),
      color: AppColors.alabasterGray,
      child: Center(
        child: Image.asset(
          'assets/black-head-horse.png',
          width: 66,
          height: 66,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
