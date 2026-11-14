// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela autônoma de relação com o cavalo (etapa preliminar
// sem barra de progresso), integrando AuthHeader, cabeçalho e botão Seguinte
// com validação impeditiva de atletas por diálogo padronizado.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/core/widgets/app_dropdown_field.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/information_row.dart';

import '../../application/controllers/horse_registration_controller.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../data/repositories/horse_registration_repository.dart';
import '../services/horse_image_selection_service.dart';
import '../widgets/horse_registration_alert.dart';
import 'horse_name_screen.dart';

typedef HorseRelationshipCallback = void Function(HorseRegistrationDraft draft);

/// Tela inicial de seleção de relacionamento com o animal (etapa preliminar).
class HorseRelationshipScreen extends StatefulWidget {
  const HorseRelationshipScreen({
    this.draft,
    this.repository,
    this.microchipValidator,
    this.controller,
    this.imageSelection = const HorseImageSelectionService(),
    this.onContinue,
    this.onBack,
    super.key,
  });

  final HorseRegistrationDraft? draft;
  final HorseRegistrationRepository? repository;
  final HorseMicrochipValidator? microchipValidator;
  final HorseRegistrationController? controller;
  final HorseImageSelectionService imageSelection;
  final HorseRelationshipCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<HorseRelationshipScreen> createState() =>
      _HorseRelationshipScreenState();
}

class _HorseRelationshipScreenState extends State<HorseRelationshipScreen> {
  late final HorseRegistrationDraft _draft;
  late HorseRelationship _selectedRelationship;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft ?? HorseRegistrationDraft();
    _selectedRelationship = _draft.relationship;
  }

  Future<void> _goBack() async {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    if (await confirmHorseRegistrationExit(context) && mounted) {
      Navigator.maybePop(context);
    }
  }

  Future<void> _continue() async {
    if (!_selectedRelationship.mayRegister) {
      await showHorseRegistrationNotice(
        context,
        title: 'Atletas não podem\ncadastrar cavalos',
        message:
            'O vínculo entre os animais e seus atletas só pode ser efetuado '
            'pelo usuário proprietário o animal. Para que isso seja feito, '
            'entre em contato com ele para que ele estabeleça o vínculo entre vocês.',
      );
      return;
    }

    _draft.relationship = _selectedRelationship;

    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(_draft);
      return;
    }

    final result = await Navigator.push<HorseRegistrationResult>(
      context,
      MaterialPageRoute<HorseRegistrationResult>(
        builder: (context) => HorseNameScreen(
          draft: _draft,
          repository: widget.repository,
          microchipValidator: widget.microchipValidator,
          controller: widget.controller,
          imageSelection: widget.imageSelection,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 18, 32, 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 50,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthHeader(onBack: _goBack),
                      const SizedBox(height: 64),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Relação com o cavalo',
                                textAlign: TextAlign.center,
                                style: textTheme.displaySmall?.copyWith(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Antes dos próximos passos,\n'
                                'precisamos saber qual seu nível de\n'
                                'relacionamento com o animal.',
                                textAlign: TextAlign.center,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontSize: 20,
                                  height: 1.18,
                                ),
                              ),
                              const SizedBox(height: 40),
                              AppDropdownField<HorseRelationship>(
                                style: AppDropdownStyle.rounded,
                                label: 'Selecionar relacionamento',
                                dropdownKey: const ValueKey(
                                  'horse-select-Relação com o cavalo',
                                ),
                                value: _selectedRelationship,
                                options: HorseRelationship.values,
                                labelFor: (item) => item.label,
                                isOpen: _isMenuOpen,
                                onTap: () => setState(() => _isMenuOpen = true),
                                onChanged: (value) => setState(() {
                                  _selectedRelationship = value;
                                  _isMenuOpen = false;
                                }),
                              ),
                              const SizedBox(height: 36),
                              const InformationRow(
                                text:
                                    'Proprietários são capazes de cadastrar e gerenciar '
                                    'os dados dos cavalos e seus treinos, mas não podem executá-los.',
                              ),
                              const SizedBox(height: 24),
                              const InformationRow(
                                text:
                                    'Atletas não têm permissão de cadastro ou edição '
                                    'dos dados do animal, mas podem executar os treinos prescritos para ele.',
                              ),
                              const SizedBox(height: 24),
                              const InformationRow(
                                text:
                                    'Proprietários que também são atletas, por outro lado, '
                                    'possuem ambos os privilégios dos tipos de relacionamentos citados acima.',
                              ),
                              const SizedBox(height: 64),
                              AuthNextButton(
                                buttonKey: const Key(
                                  'continue-horse-registration',
                                ),
                                onPressed: _continue,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Alias para manter compatibilidade com testes e rotas existentes.
typedef HorseRegistrationScreen = HorseRelationshipScreen;
