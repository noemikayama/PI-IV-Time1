// AUTORA: Gabriela Sichiroli Ferrari
// PROJETO: HorseLife
// CRIAÇÃO: 07/11/2026
// HISTÓRICO:
// - 07/11/2026: Entrada da listagem de cavalos para o perfil Responsável.
// - 12/11/2026: Encaminha repositório do cadastro existente e retorno do fluxo.

import 'package:flutter/material.dart';
import '../../../domain/models/horse_list_item.dart';
import '../../../domain/repositories/horse_list_repository.dart';
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
      onNavigationSelected: onNavigationSelected,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
    );
  }
}
