// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 29/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Modularização do Dashboard Guardian e preparação para dados da Cloud Function.
//
// Data: 03/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Padronização do cabeçalho histórico e inclusão de comentários pontuais sobre a responsabilidade do arquivo.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Apresenta o estado vazio quando não há estatísticas para o filtro escolhido.
class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.blueSpruce,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Container(
      padding: const EdgeInsets.all(23),
      decoration: BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.block, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sem dados para exibir',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Parece que você ainda não realizou nenhum treino até o momento. Volte aqui após concluir algum para visualizar suas estatísticas e os feedbacks respondidos recentemente.',
            style: TextStyle(fontSize: 17),
          ),
        ],
      ),
    ),
  );
}
