// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação do estado de expansão e da composição visual do
// card recolhível compartilhado.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do card recolhível reutilizável para seções de
// conteúdo da aplicação.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Card genérico que permite mostrar ou ocultar seu conteúdo pelo cabeçalho.
class CollapsibleSectionCard extends StatefulWidget {
  const CollapsibleSectionCard({
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
    this.backgroundColor = AppColors.alabasterGray,
    this.margin = const EdgeInsets.only(bottom: 20),
    super.key,
  });

  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final Color backgroundColor;
  final EdgeInsetsGeometry margin;

  @override
  State<CollapsibleSectionCard> createState() => _CollapsibleSectionCardState();
}

class _CollapsibleSectionCardState extends State<CollapsibleSectionCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Semantics(
      button: true,
      expanded: _expanded,
      child: Container(
        margin: widget.margin,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: radius,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _toggle,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 14, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0 : 0.5,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(Icons.keyboard_arrow_up_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      child: widget.child,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
