// AUTORA: Gabriela Sichiroli Ferrari
// PROJETO: HorseLife
// CRIAÇÃO: 07/11/2026
// HISTÓRICO:
// - 07/11/2026: Estados vazios próprios de Responsável e Profissional.
// - 12/11/2026: Reutiliza o AppColors do tema oficial; não duplica assets.

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import '../../domain/models/horse_list_item.dart';

class HorseListEmptyState extends StatelessWidget {
  final HorseListProfile profile;
  final VoidCallback? onAddHorse;

  const HorseListEmptyState({
    super.key,
    required this.profile,
    this.onAddHorse,
  });

  @override
  Widget build(BuildContext context) {
    final isGuardian = profile == HorseListProfile.guardian;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 410),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.block_outlined, size: 21, color: Colors.black87),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isGuardian ? 'Nenhum animal cadastrado' : 'Nenhum animal vinculado',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isGuardian
                  ? 'Cadastre um cavalo agora mesmo e comece a desfrutar do HorseLife!'
                  : 'Prescreva treinos para os cavalos vinculados a você.\n'
                    'Se nenhum animal aparece, aguarde até que os usuários responsáveis '
                    'o adicionem ao cavalo, para então consultar os seus dados.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, height: 1.34),
            ),
            if (isGuardian) ...<Widget>[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.seaGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const StadiumBorder(),
                  ),
                  onPressed: onAddHorse,
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text(
                    'Cadastrar animal',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
