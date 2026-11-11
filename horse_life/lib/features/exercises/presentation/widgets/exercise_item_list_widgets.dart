// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos componentes modulares compartilhados entre as etapas
// de listagem (orientações, materiais e mídias) e a tela de revisão final do
// cadastro de exercícios.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

// Botão cinza arredondado padronizado para inclusão de novos itens (orientações,
// materiais ou mídias auxiliares) ao longo das etapas do cadastro de exercícios.
class ExerciseAddItemButton extends StatelessWidget {
  const ExerciseAddItemButton({
    required this.buttonKey,
    required this.label,
    required this.onPressed,
    this.semanticsLabel,
    this.isLoading = false,
    super.key,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback? onPressed;
  final String? semanticsLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(18));

    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      child: Material(
        color: const Color(0xFFE9E9E9),
        borderRadius: borderRadius,
        child: InkWell(
          key: buttonKey,
          onTap: isLoading ? null : onPressed,
          borderRadius: borderRadius,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isLoading)
                    const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  else
                    const Icon(
                      Icons.add_rounded,
                      color: AppColors.text,
                      size: 32,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Card reutilizável com ícone temático, rótulo descritivo e botão de remoção,
// compartilhado pelas etapas de orientações, materiais, mídias e revisão final.
class ExerciseRemovableItemTile extends StatelessWidget {
  const ExerciseRemovableItemTile({
    required this.icon,
    required this.label,
    required this.removeKey,
    required this.onRemove,
    this.minHeight = 64,
    this.maxLines = 1,
    super.key,
  });

  final IconData icon;
  final String label;
  final Key removeKey;
  final VoidCallback? onRemove;
  final double minHeight;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
      decoration: const BoxDecoration(
        color: Color(0xFFE9E9E9),
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blueSpruce, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontSize: 19, height: 1.2),
            ),
          ),
          IconButton(
            key: removeKey,
            onPressed: onRemove,
            tooltip: 'Remover $label',
            icon: const Icon(
              Icons.delete_rounded,
              color: AppColors.error,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

// Agrupa visualmente uma seção da revisão final do exercício com título e itens.
class ExerciseReviewSection extends StatelessWidget {
  const ExerciseReviewSection({
    required this.title,
    required this.emptyMessage,
    required this.children,
    super.key,
  });

  final String title;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (children.isEmpty)
          Text(
            emptyMessage,
            key: ValueKey('empty-$title'),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.grey),
          )
        else
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }
}
