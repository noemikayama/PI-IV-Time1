// AUTORA: Gabriela Sichiroli Ferrari
// PROJETO: HorseLife
// CRIAÇÃO: 07/11/2026
// HISTÓRICO:
// - 07/11/2026: Entrada da listagem de cavalos para o perfil Profissional.

import 'package:flutter/material.dart';
import '../../../domain/models/horse_list_item.dart';
import '../../../domain/repositories/horse_list_repository.dart';
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
