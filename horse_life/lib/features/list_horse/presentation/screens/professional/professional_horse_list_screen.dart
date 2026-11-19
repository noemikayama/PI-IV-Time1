// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Reorganização da camada de dados e atualização dos imports; padronização
// de autoria e histórico para revisão do PR.
//
// Data: 07/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Entrada da listagem de cavalos para o perfil Profissional.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../../data/models/horse_list_item.dart';
import '../../../data/repositories/horse_list_repository.dart';
import '../horse_list_screen.dart';

class ProfessionalHorseListScreen extends StatelessWidget {
  final HorseListRepository? repository;
  final ValueChanged<HorseListItem>? onHorseSelected;
  final VoidCallback? onMenuPressed;
  final ValueChanged<int>? onNavigationSelected;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? drawer;

  const ProfessionalHorseListScreen({
    super.key,
    this.repository,
    this.onHorseSelected,
    this.onMenuPressed,
    this.onNavigationSelected,
    this.appBar,
    this.bottomNavigationBar,
    this.drawer,
  });

  @override
  Widget build(BuildContext context) {
    return HorseListScreen(
      profile: HorseListProfile.professional,
      repository: repository,
      onHorseSelected: onHorseSelected,
      onMenuPressed: onMenuPressed,
      onNavigationSelected: onNavigationSelected,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
    );
  }
}
