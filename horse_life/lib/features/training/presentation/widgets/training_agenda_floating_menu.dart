// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do menu flutuante expansível da agenda profissional para
// acesso à criação de planos de treino, treinamentos e exercícios.
// Documentação dos estados, callbacks e componentes do menu.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

// Menu expansível com os atalhos de criação exclusivos do treinador.
class TrainingAgendaFloatingMenu extends StatefulWidget {
  const TrainingAgendaFloatingMenu({
    this.onCreatePlan,
    this.onCreateTraining,
    this.onCreateExercise,
    super.key,
  });

  // Chamado quando o usuário escolhe criar um plano de treinos.
  final VoidCallback? onCreatePlan;

  // Chamado quando o usuário escolhe criar um treinamento.
  final VoidCallback? onCreateTraining;

  // Chamado quando o usuário escolhe criar um exercício.
  final VoidCallback? onCreateExercise;

  @override
  State<TrainingAgendaFloatingMenu> createState() =>
      _TrainingAgendaFloatingMenuState();
}

class _TrainingAgendaFloatingMenuState
    extends State<TrainingAgendaFloatingMenu> {
  bool _isOpen = false;

  // Alterna a visibilidade das opções e a aparência do botão principal.
  void _toggle() => setState(() => _isOpen = !_isOpen);

  // Fecha o menu antes de encaminhar a ação escolhida.
  void _select(VoidCallback? callback) {
    setState(() => _isOpen = false);
    callback?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: 1,
              child: child,
            ),
          ),
          child: _isOpen
              ? Column(
                  key: const Key('trainer-agenda-fab-options'),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MenuAction(
                      key: const Key('trainer-agenda-create-plan'),
                      label: 'Plano de treinos',
                      onTap: () => _select(widget.onCreatePlan),
                    ),
                    const SizedBox(height: 10),
                    _MenuAction(
                      key: const Key('trainer-agenda-create-training'),
                      label: 'Treinamento',
                      onTap: () => _select(widget.onCreateTraining),
                    ),
                    const SizedBox(height: 10),
                    _MenuAction(
                      key: const Key('trainer-agenda-create-exercise'),
                      label: 'Exercício',
                      onTap: () => _select(widget.onCreateExercise),
                    ),
                    const SizedBox(height: 12),
                  ],
                )
              : const SizedBox.shrink(key: Key('trainer-agenda-fab-closed')),
        ),
        FloatingActionButton(
          key: const Key('trainer-agenda-fab'),
          heroTag: 'trainer-agenda-fab',
          tooltip: _isOpen ? 'Fechar menu de criação' : 'Abrir menu de criação',
          onPressed: _toggle,
          backgroundColor: _isOpen ? AppColors.blueSpruce : AppColors.seaGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(Icons.add_rounded, size: 42),
          ),
        ),
      ],
    );
  }
}

// Opção textual reutilizada dentro do menu flutuante.
class _MenuAction extends StatelessWidget {
  const _MenuAction({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.pearlAqua,
      borderRadius: BorderRadius.circular(32),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 190, minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 20,
                color: AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
