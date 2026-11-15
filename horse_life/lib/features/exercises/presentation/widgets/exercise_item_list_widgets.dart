// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 12/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Re-exportação dos modelos de lista e revisão migrados para
// core/widgets/app_item_list_widgets.dart, mantendo retrocompatibilidade.
//
// Data: 11/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos componentes modulares compartilhados entre as etapas
// de listagem (orientações, materiais e mídias) e a tela de revisão final do
// cadastro de exercícios.
// -----------------------------------------------------------------------------

export '../../../../core/widgets/app_item_list_widgets.dart';

import '../../../../core/widgets/app_item_list_widgets.dart';

typedef ExerciseAddItemButton = AppAddItemButton;
typedef ExerciseRemovableItemTile = AppRemovableItemTile;
typedef ExerciseReviewSection = AppReviewSection;
