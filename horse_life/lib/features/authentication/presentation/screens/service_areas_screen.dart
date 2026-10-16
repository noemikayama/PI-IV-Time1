// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 16/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Transferência da região inicial para a camada de apresentação e
// adoção do catálogo geográfico separado do repositório de localidades, além
// da substituição de ValueChanged<T?> pelo typedef _ModalDropdownChanged<T>.
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
import '../../application/controllers/registration_controller.dart';
import '../../application/states/registration_draft.dart';
import '../../application/states/trainer_service_area.dart';
import '../../data/models/brazilian_country_region.dart';
import '../../data/repositories/brazilian_locations_repository.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_next_button.dart';
import '../widgets/registration_progress_indicator.dart';
import 'registration_password_screen.dart';

// Entrega à coordenação do fluxo o draft atualizado com todas as áreas.
typedef ServiceAreasCallback =
    void Function(TrainerRegistrationDraft registration);
typedef _ModalDropdownChanged<T> = void Function(T? value);

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
      builder: (context) => const _AreaTypeDialog(),
    );
    if (!mounted || type == null) return;

    final area = await showDialog<TrainerServiceArea>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AreaSelectionDialog(
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

// Primeiro modal: define a abrangência geográfica que será cadastrada.
class _AreaTypeDialog extends StatefulWidget {
  const _AreaTypeDialog();

  @override
  State<_AreaTypeDialog> createState() => _AreaTypeDialogState();
}

class _AreaTypeDialogState extends State<_AreaTypeDialog> {
  // A macrorregião é a escolha inicial apresentada pelo protótipo.
  TrainerServiceAreaType _selectedType = TrainerServiceAreaType.countryRegion;

  @override
  Widget build(BuildContext context) {
    return _ServiceAreaDialogFrame(
      title: 'Adicionar região',
      onClose: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Selecione o tipo de região que\ndeseja adicionar:',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontSize: 20, height: 1.2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          RadioGroup<TrainerServiceAreaType>(
            groupValue: _selectedType,
            onChanged: (value) {
              if (value != null) setState(() => _selectedType = value);
            },
            child: Column(
              children: [
                _AreaTypeOption(
                  optionKey: const Key('service-area-type-region'),
                  label: 'Região do país',
                  value: TrainerServiceAreaType.countryRegion,
                  onSelected: () => setState(
                    () => _selectedType = TrainerServiceAreaType.countryRegion,
                  ),
                ),
                _AreaTypeOption(
                  optionKey: const Key('service-area-type-state'),
                  label: 'Estado',
                  value: TrainerServiceAreaType.state,
                  onSelected: () => setState(
                    () => _selectedType = TrainerServiceAreaType.state,
                  ),
                ),
                _AreaTypeOption(
                  optionKey: const Key('service-area-type-city'),
                  label: 'Cidade',
                  value: TrainerServiceAreaType.city,
                  onSelected: () => setState(
                    () => _selectedType = TrainerServiceAreaType.city,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          AuthNextButton(
            buttonKey: const Key('continue-service-area-type'),
            onPressed: () => Navigator.pop(context, _selectedType),
          ),
        ],
      ),
    );
  }
}

// Linha reutilizável que amplia a área clicável do controle de rádio.
class _AreaTypeOption extends StatelessWidget {
  const _AreaTypeOption({
    required this.optionKey,
    required this.label,
    required this.value,
    required this.onSelected,
  });

  final Key optionKey;
  final String label;
  final TrainerServiceAreaType value;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: optionKey,
      onTap: onSelected,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Transform.scale(
              scale: 1.75,
              child: Radio<TrainerServiceAreaType>(
                key: ValueKey('radio-${value.name}'),
                value: value,
                activeColor: AppColors.seaGreen,
                fillColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? AppColors.seaGreen
                      : AppColors.grey;
                }),
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? AppColors.pearlAqua.withValues(alpha: 0.35)
                      : Colors.transparent;
                }),
                side: const BorderSide(width: 2, color: AppColors.grey),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Segundo modal: coleta os valores exigidos pelo nível geográfico escolhido.
class _AreaSelectionDialog extends StatefulWidget {
  const _AreaSelectionDialog({
    required this.type,
    required this.locationsRepository,
  });

  final TrainerServiceAreaType type;
  final BrazilianLocationsRepository locationsRepository;

  @override
  State<_AreaSelectionDialog> createState() => _AreaSelectionDialogState();
}

class _AreaSelectionDialogState extends State<_AreaSelectionDialog> {
  static const _initialCountryRegionName = 'Sudeste';

  // Seleções encadeadas; trocar um nível invalida os níveis mais específicos.
  late BrazilianCountryRegion _selectedRegion;
  List<BrazilianStateOption> _states = const [];
  BrazilianStateOption? _selectedState;
  List<String> _cities = const [];
  String? _selectedCity;
  // Indicadores independentes evitam salvar enquanto dados ainda são buscados.
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;
  bool _hasLoadError = false;
  // Versão da requisição usada para ignorar respostas antigas de municípios.
  int _cityRequest = 0;

  @override
  void initState() {
    super.initState();
    _selectedRegion = BrazilianCountryRegions.values.firstWhere(
      (region) => region.name == _initialCountryRegionName,
    );
    if (widget.type != TrainerServiceAreaType.countryRegion) {
      _loadStates();
    }
  }

  // Exibe somente as UFs pertencentes à macrorregião atualmente selecionada.
  List<BrazilianStateOption> get _filteredStates => _states
      .where((state) => _selectedRegion.stateCodes.contains(state.code))
      .toList(growable: false);

  // Carrega todas as UFs uma vez e prepara a seleção dependente inicial.
  Future<void> _loadStates() async {
    setState(() {
      _isLoadingStates = true;
      _hasLoadError = false;
    });
    try {
      final states = await widget.locationsRepository.fetchStates();
      if (!mounted) return;
      setState(() {
        _states = states;
        _isLoadingStates = false;
        _selectFirstState();
      });
      if (widget.type == TrainerServiceAreaType.city) {
        await _loadCities();
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoadingStates = false;
        _hasLoadError = true;
      });
    }
  }

  // Reinicia os níveis dependentes usando a primeira UF válida como padrão.
  void _selectFirstState() {
    final states = _filteredStates;
    _selectedState = states.isEmpty ? null : states.first;
    _selectedCity = null;
    _cities = const [];
  }

  // Busca os municípios da UF e descarta resultados de requisições obsoletas.
  Future<void> _loadCities() async {
    final stateCode = _selectedState?.code;
    if (stateCode == null) return;
    final request = ++_cityRequest;
    setState(() {
      _isLoadingCities = true;
      _hasLoadError = false;
      _cities = const [];
      _selectedCity = null;
    });
    try {
      final cities = await widget.locationsRepository.fetchCities(stateCode);
      if (!mounted || request != _cityRequest) return;
      setState(() {
        _cities = cities;
        _selectedCity = cities.firstOrNull;
        _isLoadingCities = false;
      });
    } on Object {
      if (!mounted || request != _cityRequest) return;
      setState(() {
        _isLoadingCities = false;
        _hasLoadError = true;
      });
    }
  }

  // Propaga a mudança da macrorregião para estado e, se necessário, cidade.
  void _changeRegion(BrazilianCountryRegion? region) {
    if (region == null) return;
    setState(() {
      _selectedRegion = region;
      _selectFirstState();
    });
    if (widget.type == TrainerServiceAreaType.city) {
      _loadCities();
    }
  }

  // Recarrega municípios somente quando o tipo selecionado exige uma cidade.
  void _changeState(BrazilianStateOption? state) {
    if (state == null) return;
    setState(() => _selectedState = state);
    if (widget.type == TrainerServiceAreaType.city) {
      _loadCities();
    }
  }

  // A validação exige apenas os campos aplicáveis à abrangência escolhida.
  bool get _canSave => switch (widget.type) {
    TrainerServiceAreaType.countryRegion => true,
    TrainerServiceAreaType.state => _selectedState != null,
    TrainerServiceAreaType.city => _selectedCity != null,
  };

  // Converte a hierarquia selecionada no construtor de domínio correspondente.
  void _save() {
    final state = _selectedState;
    final area = switch (widget.type) {
      TrainerServiceAreaType.countryRegion => TrainerServiceArea.countryRegion(
        countryRegion: _selectedRegion.name,
      ),
      TrainerServiceAreaType.state => TrainerServiceArea.state(
        countryRegion: _selectedRegion.name,
        stateCode: state!.code,
        stateName: state.name,
      ),
      TrainerServiceAreaType.city => TrainerServiceArea.city(
        countryRegion: _selectedRegion.name,
        stateCode: state!.code,
        stateName: state.name,
        cityName: _selectedCity!,
      ),
    };
    Navigator.pop(context, area);
  }

  @override
  Widget build(BuildContext context) {
    // Compõe progressivamente os dropdowns exigidos por região, estado ou cidade.
    final title = switch (widget.type) {
      TrainerServiceAreaType.countryRegion => 'Adicionar região',
      TrainerServiceAreaType.state => 'Adicionar estado',
      TrainerServiceAreaType.city => 'Adicionar cidade',
    };

    return _ServiceAreaDialogFrame(
      title: title,
      onClose: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModalDropdown<BrazilianCountryRegion>(
            dropdownKey: const Key('country-region-dropdown'),
            label: 'Região do país',
            value: _selectedRegion,
            items: BrazilianCountryRegions.values,
            itemLabel: (region) => region.name,
            onChanged: _changeRegion,
          ),
          if (widget.type != TrainerServiceAreaType.countryRegion) ...[
            const SizedBox(height: 20),
            _ModalDropdown<BrazilianStateOption>(
              dropdownKey: const Key('service-area-state-dropdown'),
              label: 'Estado',
              value: _selectedState,
              items: _filteredStates,
              itemLabel: (state) => state.code,
              onChanged: _changeState,
              isLoading: _isLoadingStates,
            ),
          ],
          if (widget.type == TrainerServiceAreaType.city) ...[
            const SizedBox(height: 20),
            _ModalDropdown<String>(
              dropdownKey: const Key('service-area-city-dropdown'),
              label: 'Cidade',
              value: _selectedCity,
              items: _cities,
              itemLabel: (city) => city,
              onChanged: (city) => setState(() => _selectedCity = city),
              isLoading: _isLoadingCities,
            ),
          ],
          if (_hasLoadError) ...[
            const SizedBox(height: 14),
            TextButton(
              key: const Key('retry-service-area-locations'),
              onPressed: _isLoadingStates || _isLoadingCities
                  ? null
                  : _loadStates,
              child: const Text('Não foi possível carregar. Tentar novamente'),
            ),
          ],
          const SizedBox(height: 42),
          AuthNextButton(
            buttonKey: const Key('save-service-area'),
            label: 'Salvar',
            showArrow: false,
            onPressed:
                _canSave &&
                    !_isLoadingStates &&
                    !_isLoadingCities &&
                    !_hasLoadError
                ? _save
                : null,
          ),
        ],
      ),
    );
  }
}

// Dropdown genérico com o mesmo tratamento visual e estado de carregamento.
class _ModalDropdown<T> extends StatelessWidget {
  const _ModalDropdown({
    required this.dropdownKey,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.isLoading = false,
  });

  final Key dropdownKey;
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final _ModalDropdownChanged<T> onChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 8),
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: Color(0xFFE9E9E9),
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    key: dropdownKey,
                    value: items.contains(value) ? value : null,
                    isExpanded: true,
                    menuMaxHeight: 300,
                    borderRadius: const BorderRadius.all(Radius.circular(18)),
                    dropdownColor: Colors.white,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.text,
                      size: 34,
                    ),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.text,
                      fontSize: 20,
                    ),
                    hint: const Text('Selecione'),
                    items: [
                      for (final item in items)
                        DropdownMenuItem<T>(
                          value: item,
                          child: Text(
                            itemLabel(item),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: items.isEmpty ? null : onChanged,
                  ),
                ),
        ),
      ],
    );
  }
}

// Moldura comum aos modais, responsável por título, fechamento e limites.
class _ServiceAreaDialogFrame extends StatelessWidget {
  const _ServiceAreaDialogFrame({
    required this.title,
    required this.onClose,
    required this.child,
  });

  final String title;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(36)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(30, 24, 30, 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 42),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      key: const Key('close-service-area-dialog'),
                      onPressed: onClose,
                      tooltip: 'Fechar',
                      icon: const Icon(Icons.close_rounded, size: 38),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
