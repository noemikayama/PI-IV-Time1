// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Reorganização da camada de dados e atualização dos imports; padronização
// de autoria e histórico para revisão do PR.
//
// Data: 12/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Encaminha repositório do cadastro existente e retorno do fluxo.
//
// Data: 07/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Entrada da listagem de cavalos para o perfil Responsável.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/home_bottom_nav_bar.dart';
import '../../../data/models/horse_list_item.dart';
import '../../../data/repositories/horse_list_repository.dart';
import '../horse_list_screen.dart';
import 'package:horse_life/features/horses/data/repositories/horse_registration_repository.dart';

class GuardianHorseListScreen extends StatelessWidget {
  final HorseListRepository? repository;
  final ValueChanged<HorseRegistrationResult>? onRegistrationCompleted;
  final ValueChanged<HorseListItem>? onHorseSelected;
  final VoidCallback? onMenuPressed;
  final ValueChanged<int>? onNavigationSelected;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? drawer;

  const GuardianHorseListScreen({
    super.key,
    this.repository,
    this.onRegistrationCompleted,
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
      profile: HorseListProfile.guardian,
      repository: repository,
      onRegistrationCompleted: onRegistrationCompleted,
      onHorseSelected: onHorseSelected,
      onMenuPressed: onMenuPressed,
      onNavigationSelected: onNavigationSelected ??
          (index) {
            Navigator.of(context).pop(HomeNavigationDestination.values[index]);
          },
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
    );
  }
}
