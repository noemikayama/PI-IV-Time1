// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Substituição dos modais locais pelos widgets compartilhados de
// core/widgets, preservando seleção, validação e navegação do cadastro.
//
// Data: 16/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Transferência da região inicial para a camada de apresentação e
// adoção do catálogo geográfico separado do repositório de localidades.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da sexta etapa do treinador, com seleção encadeada de
// macrorregião, estado e cidade e listagem das áreas de atendimento.
// -----------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../../../core/widgets/service_area_dialogs.dart';
import '../../application/controllers/registration_controller.dart';
import '../../application/states/registration_draft.dart';
import '../../application/states/trainer_service_area.dart';
import '../../data/repositories/brazilian_locations_repository.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_next_button.dart';
import '../widgets/registration_progress_indicator.dart';
import 'registration_password_screen.dart';

// Entrega à coordenação do fluxo o draft atualizado com todas as áreas.
typedef ServiceAreasCallback =
    void Function(TrainerRegistrationDraft registration);

// Sexta etapa do treinador: adiciona áreas em três níveis geográficos.
class ServiceAreasScreen extends StatefulWidget {
  const ServiceAreasScreen({
    required this.registration,
    this.locationsRepository =
        const CountryStateCityBrazilianLocationsRepository(),
    this.registrationController,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainerRegistrationDraft registration;
  final BrazilianLocationsRepository locationsRepository;
  final RegistrationController? registrationController;
  final ServiceAreasCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<ServiceAreasScreen> createState() => _ServiceAreasScreenState();
}

class _ServiceAreasScreenState extends State<ServiceAreasScreen> {
  // A lista cresce até três itens; depois disso permanece com altura fixa e rola.
  static const _areaHeight = 72.0;
  static const _areaSpacing = 12.0;
  static const _maximumVisibleAreas = 3;

  // Estado local editável, iniciado com as escolhas que já existem no draft.
  final ScrollController _areasScrollController = ScrollController();
  late final List<TrainerServiceArea> _areas;

  @override
  void initState() {
    super.initState();
    _areas = List.of(widget.registration.serviceAreas);
  }

  @override
  void dispose() {
    _areasScrollController.dispose();
    super.dispose();
  }

  // Permite que testes e coordenadores externos assumam a navegação de retorno.
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  // Executa os dois modais em sequência: primeiro o tipo, depois a localidade.
  Future<void> _addArea() async {
    final type = await showDialog<TrainerServiceAreaType>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ServiceAreaTypeDialog(),
    );
    if (!mounted || type == null) return;

    final area = await showDialog<TrainerServiceArea>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ServiceAreaSelectionDialog(
        type: type,
        locationsRepository: widget.locationsRepository,
      ),
    );
    if (!mounted || area == null) return;

    // A chave normalizada impede a inclusão repetida da mesma abrangência.
    if (_areas.any((selected) => selected.identifier == area.identifier)) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.info_outline_rounded,
        message: 'Essa região já foi adicionada.',
      );
      return;
    }

    setState(() => _areas.add(area));
  }

  // Mantém a lista e a interface sincronizadas após uma exclusão.
  void _removeArea(int index) {
    setState(() => _areas.removeAt(index));
  }

  // Persiste uma cópia imutável das áreas antes de abrir a etapa de senha.
  void _continue() {
    final updatedRegistration = widget.registration.withServiceAreas(_areas);
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedRegistration);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => RegistrationPasswordScreen(
          registration: updatedRegistration,
          registrationController: widget.registrationController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Estrutura responsiva compartilhada pelas etapas do cadastro profissional.
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
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
                    const SizedBox(height: 44),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const RegistrationProgressIndicator(
                              configuration:
                                  RegistrationProgressConfiguration.trainer,
                              currentStep: 6,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Regiões de\natendimento',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                height: 0.98,
                              ),
                            ),
                            const SizedBox(height: 36),
                            Text(
                              'Informe em quais regiões do país\n'
                              'você está disponível para atender\n'
                              'seus treinadores.\n'
                              'Você pode editar isso mais tarde,\n'
                              'se precisar.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 46),
                            _buildAddButton(context),
                            if (_areas.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildAreasList(),
                            ],
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key('continue-service-areas'),
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
    );
  }

  // Campo de ação com semântica de botão para abrir o fluxo de seleção.
  Widget _buildAddButton(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(18));

    return Semantics(
      button: true,
      label: 'Adicionar região de atendimento',
      child: Material(
        color: const Color(0xFFE9E9E9),
        borderRadius: borderRadius,
        child: InkWell(
          key: const Key('add-service-area'),
          onTap: _addArea,
          borderRadius: borderRadius,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Adicionar região',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 20),
                    ),
                  ),
                  const Icon(
                    Icons.add_rounded,
                    color: AppColors.text,
                    size: 32,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Limita a altura visual a três itens e habilita rolagem quando necessário.
  Widget _buildAreasList() {
    final visibleCount = math.min(_areas.length, _maximumVisibleAreas);
    final listHeight =
        visibleCount * _areaHeight + (visibleCount - 1) * _areaSpacing;
    final isScrollable = _areas.length > _maximumVisibleAreas;

    return SizedBox(
      key: const Key('selected-service-areas-list'),
      height: listHeight,
      child: Scrollbar(
        controller: _areasScrollController,
        thumbVisibility: isScrollable,
        child: ListView.separated(
          controller: _areasScrollController,
          primary: false,
          padding: EdgeInsets.only(right: isScrollable ? 14 : 0),
          itemCount: _areas.length,
          separatorBuilder: (_, _) => const SizedBox(height: _areaSpacing),
          itemBuilder: (context, index) {
            final area = _areas[index];
            return Container(
              key: ValueKey('selected-service-area-${area.identifier}'),
              height: _areaHeight,
              padding: const EdgeInsets.only(left: 20, right: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFE9E9E9),
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.blueSpruce,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          area.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          area.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: ValueKey('remove-service-area-${area.identifier}'),
                    onPressed: () => _removeArea(index),
                    tooltip: 'Remover ${area.label}',
                    icon: const Icon(
                      Icons.delete_rounded,
                      color: AppColors.error,
                      size: 30,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
