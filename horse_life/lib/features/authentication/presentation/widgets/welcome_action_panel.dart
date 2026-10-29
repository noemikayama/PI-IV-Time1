// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 27/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos e segmentos do código de autenticação,
// detalhando responsabilidades, fluxo de dados e integração entre camadas.
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do painel fixo de ações da tela inicial, utilizando os
// estilos de texto, cores e botões definidos pelo tema do HorseLife.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../../../../core/widgets/gradient_button.dart';

// Rodapé da tela inicial que separa as duas entradas da autenticação: acessar
// uma sessão existente ou iniciar a seleção de perfil para um novo cadastro.
class WelcomeActionPanel extends StatelessWidget {
  const WelcomeActionPanel({
    required this.onAccessAccount,
    required this.onCreateAccount,
    super.key,
  });

  // Altura-base sem a área segura inferior adicionada durante a composição.
  static const double height = 280;

  // A tela-pai decide como abrir login e cadastro; o painel cuida apenas da UI.
  final VoidCallback onAccessAccount;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Mantém a área de ações fixa e visualmente separada da fotografia.
    return Container(
      key: const Key('welcome-action-panel'),
      height: height + MediaQuery.paddingOf(context).bottom,
      padding: EdgeInsets.fromLTRB(
        17,
        35,
        17,
        22 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'É bom te ter no HorseLife',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 28),
          GradientButton(label: 'Acessar conta', onPressed: onAccessAccount),
          const SizedBox(height: 25),
          SizedBox(
            height: 60,
            child: OutlinedButton(
              onPressed: onCreateAccount,
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary, width: 3),
                shape: const StadiumBorder(),
                textStyle: theme.textTheme.labelLarge,
              ),
              child: const Text('Abrir uma nova conta'),
            ),
          ),
        ],
      ),
    );
  }
}
