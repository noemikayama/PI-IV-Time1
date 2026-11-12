// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Extração dos modais de região, estado e cidade para core/widgets,
// permitindo o mesmo fluxo encadeado no cadastro e na edição do perfil.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/features/authentication/application/states/trainer_service_area.dart';
import 'package:horse_life/features/authentication/data/models/brazilian_country_region.dart';
import 'package:horse_life/features/authentication/data/repositories/brazilian_locations_repository.dart';

/// Callback tipado usado pelos dropdowns compartilhados dos modais.
typedef AppModalDropdownChanged<T> = void Function(T? value);

/// Primeiro passo compartilhado: escolhe se a abrangência é região, estado
/// ou cidade.
class ServiceAreaTypeDialog extends StatefulWidget {
  const ServiceAreaTypeDialog({super.key});

  @override
  State<ServiceAreaTypeDialog> createState() => _ServiceAreaTypeDialogState();
}

class _ServiceAreaTypeDialogState extends State<ServiceAreaTypeDialog> {
  TrainerServiceAreaType _selectedType = TrainerServiceAreaType.countryRegion;

  @override
  Widget build(BuildContext context) {
    return AppModalFrame(
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
          AppModalSaveButton(
            buttonKey: const Key('continue-service-area-type'),
            label: 'Continuar',
            onPressed: () => Navigator.pop(context, _selectedType),
          ),
        ],
      ),
    );
  }
}

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
      borderRadius: BorderRadius.circular(14),
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
                fillColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? AppColors.seaGreen
                      : AppColors.grey,
                ),
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

/// Modal compartilhado que reproduz a seleção encadeada usada no cadastro.
class ServiceAreaSelectionDialog extends StatefulWidget {
  const ServiceAreaSelectionDialog({
    required this.type,
    this.locationsRepository =
        const CountryStateCityBrazilianLocationsRepository(),
    super.key,
  });

  /// Define quais níveis do formulário serão exibidos e validados.
  final TrainerServiceAreaType type;

  /// Fonte injetável de UFs e municípios; por padrão usa o catálogo do app.
  final BrazilianLocationsRepository locationsRepository;

  @override
  State<ServiceAreaSelectionDialog> createState() =>
      _ServiceAreaSelectionDialogState();
}

class _ServiceAreaSelectionDialogState
    extends State<ServiceAreaSelectionDialog> {
  static const _initialCountryRegionName = 'Sudeste';

  late BrazilianCountryRegion _selectedRegion;
  List<BrazilianStateOption> _states = const [];
  BrazilianStateOption? _selectedState;
  List<String> _cities = const [];
  String? _selectedCity;
  bool _isLoadingStates = false;
  bool _isLoadingCities = false;
  bool _hasLoadError = false;
  int _cityRequest = 0;

  @override
  void initState() {
    super.initState();
    _selectedRegion = BrazilianCountryRegions.values.firstWhere(
      (region) => region.name == _initialCountryRegionName,
    );
    if (widget.type != TrainerServiceAreaType.countryRegion) _loadStates();
  }

  List<BrazilianStateOption> get _filteredStates => _states
      .where((state) => _selectedRegion.stateCodes.contains(state.code))
      .toList(growable: false);

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
      if (widget.type == TrainerServiceAreaType.city) await _loadCities();
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoadingStates = false;
        _hasLoadError = true;
      });
    }
  }

  void _selectFirstState() {
    final states = _filteredStates;
    _selectedState = states.isEmpty ? null : states.first;
    _selectedCity = null;
    _cities = const [];
  }

  Future<void> _loadCities() async {
    final stateCode = _selectedState?.code;
    if (stateCode == null) return;
    // O contador impede que uma resposta lenta de uma UF anterior sobrescreva
    // a cidade da UF mais recentemente escolhida.
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

  void _changeRegion(BrazilianCountryRegion? region) {
    if (region == null) return;
    setState(() {
      _selectedRegion = region;
      _selectFirstState();
    });
    if (widget.type == TrainerServiceAreaType.city) _loadCities();
  }

  void _changeState(BrazilianStateOption? state) {
    if (state == null) return;
    setState(() => _selectedState = state);
    if (widget.type == TrainerServiceAreaType.city) _loadCities();
  }

  bool get _canSave => switch (widget.type) {
    TrainerServiceAreaType.countryRegion => true,
    TrainerServiceAreaType.state => _selectedState != null,
    TrainerServiceAreaType.city => _selectedCity != null,
  };

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
    final title = switch (widget.type) {
      TrainerServiceAreaType.countryRegion => 'Adicionar região',
      TrainerServiceAreaType.state => 'Adicionar estado',
      TrainerServiceAreaType.city => 'Adicionar cidade',
    };

    return AppModalFrame(
      title: title,
      onClose: () => Navigator.pop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppModalDropdown<BrazilianCountryRegion>(
            dropdownKey: const Key('country-region-dropdown'),
            label: 'Região do país',
            value: _selectedRegion,
            items: BrazilianCountryRegions.values,
            itemLabel: (region) => region.name,
            onChanged: _changeRegion,
          ),
          if (widget.type != TrainerServiceAreaType.countryRegion) ...[
            const SizedBox(height: 20),
            AppModalDropdown<BrazilianStateOption>(
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
            AppModalDropdown<String>(
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
          AppModalSaveButton(
            buttonKey: const Key('save-service-area'),
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

/// Dropdown visual padronizado para campos encadeados dentro dos modais.
class AppModalDropdown<T> extends StatelessWidget {
  const AppModalDropdown({
    required this.dropdownKey,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.isLoading = false,
    super.key,
  });

  final Key dropdownKey;

  /// Rótulo apresentado acima do campo.
  final String label;

  /// Seleção atual; pode ser nula enquanto opções dependentes são carregadas.
  final T? value;

  /// Opções válidas para o nível geográfico atual.
  final List<T> items;

  /// Projeta o tipo de domínio no texto mostrado ao usuário.
  final String Function(T item) itemLabel;

  /// Recebe a escolha sem acoplar o componente ao estado chamador.
  final AppModalDropdownChanged<T> onChanged;

  /// Troca temporariamente o campo por um indicador de progresso.
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
          decoration: BoxDecoration(
            color: const Color(0xFFE9E9E9),
            borderRadius: BorderRadius.circular(18),
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
                    borderRadius: BorderRadius.circular(18),
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

/// Moldura responsiva comum: título, fechamento, limite de altura e rolagem.
class AppModalFrame extends StatelessWidget {
  const AppModalFrame({
    required this.title,
    required this.onClose,
    required this.child,
    super.key,
  });

  final String title;

  /// Fecha o modal sem produzir seleção.
  final VoidCallback onClose;

  /// Formulário específico inserido sob o cabeçalho padronizado.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(36)),
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

/// Botão de confirmação compartilhado, incluindo aparência desabilitada.
class AppModalSaveButton extends StatelessWidget {
  const AppModalSaveButton({
    required this.buttonKey,
    required this.onPressed,
    this.label = 'Salvar',
    super.key,
  });

  final Key buttonKey;

  /// Callback nulo representa formulário ainda inválido ou em carregamento.
  final VoidCallback? onPressed;

  /// Texto do botão; por padrão confirma o salvamento.
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      key: buttonKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.seaGreen,
        disabledForegroundColor: AppColors.grey,
        side: BorderSide(
          color: onPressed == null ? AppColors.grey : AppColors.seaGreen,
          width: 2,
        ),
        minimumSize: const Size.fromHeight(60),
        shape: const StadiumBorder(),
        textStyle: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
