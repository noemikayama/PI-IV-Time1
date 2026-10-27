// RESPONSÁVEL PELA ATUALIZAÇÃO: Gabriela Sichiroli Ferrari - 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Revisão e padronização dos componentes e dados simulados da Home do Responsável, preservando a integração existente.
// -----------------------------------------------------------------------------
//
// Data: 25/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Integração do GuardianRepository e dos modelos com as Cloud
// Functions; documentação das responsabilidades e lógicas principais,
// preservando o comportamento anterior da interface.
// -----------------------------------------------------------------------------
//
// Data: 26/10/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Componente definido como compartilhado pelas Homes de Guardian
// e Professional, mantendo a API e o comportamento já existentes.
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';

// Asset oficial que já é utilizado no menu inferior do HorseLife.
/// Centraliza o uso do asset de cavalo e oferece um ícone alternativo caso falhe o carregamento.
class HorseAssetIcon extends StatelessWidget {
  final double size;
  const HorseAssetIcon({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/black-head-horse.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) => Icon(Icons.pets, size: size),
  );
}
