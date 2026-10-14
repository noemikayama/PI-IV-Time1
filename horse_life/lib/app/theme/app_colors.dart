// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação dos tokens de cores institucionais e semânticas do
// HorseLife, incluindo Emerald para sucesso e Inferno para erro.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

// Catálogo central dos tokens de cor usados pelo tema e pelos componentes.
// A classe não pode ser instanciada porque expõe apenas valores constantes.
abstract final class AppColors {
  // Paleta principal.
  static const prussianBlue = Color(0xFF002240);
  static const blueSpruce = Color(0xFF027068);
  static const seaGreen = Color(0xFF009373);
  static const goldenApricot = Color(0xFFCB904D);
  static const whiteSmoke = Color(0xFFF4F4F4);
  static const text = Color(0xFF000000);

  // Paleta secundária.
  static const grey = Color(0xFF808080);
  static const alabasterGray = Color(0xFFD9D9D9);
  static const pearlAqua = Color(0xFF7AC4B4);
  static const tropicalTeal = Color(0xFF38A3A5);
  static const emerald = Color(0xFF5BBA6F);
  static const inferno = Color(0xFFAA0000);

  // Cores semânticas. Esses nomes expressam intenção e evitam que as telas
  // dependam diretamente do nome visual escolhido na paleta.
  static const success = emerald;
  static const error = inferno;
}
