// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 06/11/2026 (cadastro persistido e modularização)
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Repositório Firebase na produção, controlador independente,
// componentes visuais extraídos e teste mockado via injeção.
//
// Data: 06/11/2026 (revisão após testes no celular)
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Corrigida navegação final bloqueada pelo PopScope, calendário
// iniciado na data atual com cores HorseLife, menus com seleção verde/check,
// diálogos com título destacado e ícones alinhados aos protótipos.
//
// Data: 06/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Wizard de cadastro de cavalos conforme protótipos 1 a 28,
// com revisão, campos opcionais, catálogos locais permanentes e verificação
// isolada do microchip para futura integração apenas desse campo ao Java.
// -----------------------------------------------------------------------------

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import '../../data/mocks/mock_horse_catalog.dart';
import '../../data/models/horse_registration_draft.dart';
import '../../data/repositories/horse_registration_repository.dart';
import '../../data/repositories/horse_microchip_validator.dart';
import '../../horse_registration_composition.dart';
import '../../application/controllers/horse_registration_controller.dart';
import '../widgets/horse_choice_field.dart';
import '../widgets/horse_registration_calendar.dart';
import '../widgets/horse_registration_entry_tile.dart';
import '../widgets/horse_registration_review_widgets.dart';
import '../widgets/horse_search_field.dart';
import '../widgets/horse_registration_pictogram.dart';

/// Feature independente: pode ser aberta por qualquer rota.
/// Sem injeção, salva com registerHorse no Firebase. Tests usam repositório fake.
/// O resultado retorna ao chamador; a screen não conhece widgets da Home.
class HorseRegistrationScreen extends StatefulWidget {
  const HorseRegistrationScreen({
    this.repository,
    this.microchipValidator,
    super.key,
  });

  final HorseRegistrationRepository? repository;

  /// Quando a API Java estiver pronta, basta injetar sua implementação.
  /// O catálogo de raças/pelagens continuará sempre local.
  final HorseMicrochipValidator? microchipValidator;

  @override
  State<HorseRegistrationScreen> createState() =>
      _HorseRegistrationScreenState();
}

class _HorseRegistrationScreenState extends State<HorseRegistrationScreen> {
  static const _lastStep = 12;
  static const _maxImages = 10;
  static const _maxImageBytes = 5 * 1024 * 1024;

  final _draft = HorseRegistrationDraft();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _chipController = TextEditingController();
  int _step = 0;
  bool _saving = false;
  // Permite Navigator.pop(result) após concluir o registro. Antes, PopScope
  // bloqueava a saída na etapa de revisão, especialmente perceptível no Android.
  bool _completed = false;
  bool _validatingMicrochip = false;
  late final HorseMicrochipValidator _microchipValidator;
  late final HorseRegistrationRepository _repository;
  late final HorseRegistrationController _controller;
  late Future<List<HorseModality>> _modalitiesFuture;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        HorseRegistrationComposition.productionRepository();
    _microchipValidator =
        widget.microchipValidator ??
        HorseRegistrationComposition.productionMicrochipValidator();
    _controller = HorseRegistrationController(
      repository: _repository,
      microchipValidator: _microchipValidator,
    );
    _modalitiesFuture = _repository.getModalities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _chipController.dispose();
    super.dispose();
  }

  Future<void> _notice(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.whiteSmoke,
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.prussianBlue,
          ),
        ),
        content: Text(message, textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.seaGreen,
              side: const BorderSide(color: AppColors.seaGreen),
              minimumSize: const Size(220, 44),
            ),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmExit() async {
    if (_step == 0) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sair do cadastro?'),
            content: const Text('Os dados preenchidos ainda não foram salvos.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continuar cadastro'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sair'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _back() async {
    if (_saving || _validatingMicrochip) return;
    if (_step > 0) {
      setState(() => _step--);
    } else if (await _confirmExit() && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _next() async {
    if (_saving || _validatingMicrochip) return;
    if (_step == _lastStep) {
      await _submit();
      return;
    }
    if (_step == 0 && !_draft.relationship.mayRegister) {
      await _notice(
        'Atletas não podem cadastrar cavalos',
        'O vínculo de atleta permite executar treinos, mas o cadastro do cavalo é exclusivo do proprietário.',
      );
      return;
    }
    if (_step == 1 && !_formKey.currentState!.validate()) return;
    if (_step == 2) {
      // O Flutter confere o formato; a verificação remota será feita apenas
      // por uma implementação do contrato HorseMicrochipValidator.
      if (!_formKey.currentState!.validate()) {
        await _notice(
          'Código inválido',
          'O microchip deve conter exatamente 15 números, sem letras ou espaços.',
        );
        return;
      }
      setState(() => _validatingMicrochip = true);
      try {
        await _microchipValidator.validate(_draft.microchip);
      } on HorseMicrochipValidationFailure catch (error) {
        await _notice('Código inválido', error.message);
        return;
      } catch (_) {
        await _notice(
          'Verificação indisponível',
          'Não foi possível verificar o microchip agora. Tente novamente.',
        );
        return;
      } finally {
        if (mounted) setState(() => _validatingMicrochip = false);
      }
      if (!mounted) return;
    }
    if (_step == 3) {
      final date = _draft.birthDate;
      final now = DateTime.now();
      final oldest = DateTime(now.year - 50, now.month, now.day);
      if (date == null || date.isAfter(now) || date.isBefore(oldest)) {
        await _notice(
          'Data inválida',
          'Selecione uma data de nascimento válida, entre hoje e 50 anos atrás.',
        );
        return;
      }
    }
    if (_step == 4 && _draft.breed.isEmpty) {
      await _notice(
        'Raça obrigatória',
        'Digite e selecione uma raça entre as sugestões.',
      );
      return;
    }
    if (_step == 5 && _draft.coat.isEmpty) {
      await _notice(
        'Pelagem obrigatória',
        'Digite e selecione uma pelagem entre as sugestões.',
      );
      return;
    }
    if (_step == 11 &&
        _draft.birthDate != null &&
        _draft.injuries.any(
          (injury) => injury.date.isBefore(_draft.birthDate!),
        )) {
      await _notice(
        'Data de lesão inválida',
        'Uma lesão não pode ser anterior ao nascimento do cavalo.',
      );
      return;
    }
    setState(() => _step++);
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final result = await _controller.register(_draft);
      if (!mounted) return;
      // Primeiro libera PopScope, depois conclui a rota com seu resultado.
      // Sem isso, Navigator.pop(result) era rejeitado na última etapa.
      setState(() => _completed = true);
      // PopScope só atualiza o bloqueio depois do próximo build. Sem aguardar
      // o frame, a chamada seguinte ainda vê canPop=false no Android.
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.of(context).pop(result);
    } on HorseRegistrationFailure catch (error) {
      await _notice('Cadastro não realizado', error.message);
    } catch (_) {
      await _notice(
        'Falha no cadastro',
        'Não foi possível concluir o cadastro. Verifique sua conexão e tente novamente.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate({
    bool birth = true,
    ValueChanged<DateTime>? onPicked,
  }) async {
    final now = DateTime.now();
    final min = DateTime(now.year - 50, now.month, now.day);
    // Antes o picker iniciava invariavelmente cinco anos no passado.
    // Agora abre no mês atual até que o usuário selecione um nascimento.
    final date = await showHorseRegistrationCalendar(
      context: context,
      initialDate: birth ? (_draft.birthDate ?? now) : now,
      firstDate: birth ? min : (_draft.birthDate ?? min),
      lastDate: now,
      title: birth ? 'Data de nascimento' : 'Data da lesão',
    );
    if (!mounted || date == null) return;
    setState(() {
      if (birth) {
        _draft.birthDate = date;
        _draft.injuries.removeWhere((injury) => injury.date.isBefore(date));
      } else {
        onPicked?.call(date);
      }
    });
  }

  String _displayDate(DateTime? date) => date == null
      ? 'DD/MM/AAAA'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Future<void> _selectImages() async {
    try {
      const imagesGroup = XTypeGroup(
        label: 'Imagens JPEG ou PNG',
        extensions: ['jpg', 'jpeg', 'png'],
      );
      final selected = await openFiles(acceptedTypeGroups: [imagesGroup]);
      if (!mounted) return;
      var rejected = 0;
      for (final file in selected) {
        if (_draft.images.length >= _maxImages) {
          rejected++;
          continue;
        }
        final ext = file.name.toLowerCase();
        if (!(ext.endsWith('.png') ||
                ext.endsWith('.jpg') ||
                ext.endsWith('.jpeg')) ||
            await file.length() > _maxImageBytes) {
          rejected++;
          continue;
        }
        _draft.images.add(file);
      }
      setState(() {});
      if (rejected > 0) {
        await _notice(
          'Algumas imagens foram ignoradas',
          'São permitidas até $_maxImages imagens JPG ou PNG, com no máximo 5 MB por arquivo.',
        );
      }
    } catch (_) {
      await _notice(
        'Não foi possível abrir os arquivos',
        'Tente novamente ou avance sem imagens.',
      );
    }
  }

  Future<void> _addTextItem({
    required String title,
    required List<String> list,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(hintText: 'Descreva aqui'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    // O controller pertence ao diálogo; descarta após o frame de fechamento.
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());
    if (mounted && value != null && value.isNotEmpty) {
      if (list.length >= 30) {
        await _notice(
          'Limite atingido',
          'São permitidos até 30 registros nesta seção.',
        );
      } else {
        setState(() => list.add(value));
      }
    }
  }

  Future<void> _addInjury() async {
    final description = TextEditingController();
    final prescription = TextEditingController();
    DateTime? injuryDate;
    final result = await showDialog<HorseInjury>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: const Text('Adicionar lesão'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    injuryDate == null
                        ? 'Selecionar data da lesão'
                        : _displayDate(injuryDate),
                  ),
                  onPressed: () async {
                    final now = DateTime.now();
                    final min = _draft.birthDate ?? DateTime(now.year - 50);
                    // Abre o picker da feature com as mesmas cores e limites.
                    final picked = await showHorseRegistrationCalendar(
                      context: context,
                      initialDate: now,
                      firstDate: min,
                      lastDate: now,
                      title: 'Data da lesão',
                    );
                    if (picked != null && dialogContext.mounted) {
                      update(() => injuryDate = picked);
                    }
                  },
                ),
                TextField(
                  controller: description,
                  maxLength: 500,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descrição da lesão',
                  ),
                ),
                TextField(
                  controller: prescription,
                  maxLength: 500,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Prescrição médica (opcional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            OutlinedButton(
              onPressed: () {
                if (injuryDate == null || description.text.trim().isEmpty)
                  return;
                Navigator.pop(
                  dialogContext,
                  HorseInjury(
                    date: injuryDate!,
                    description: description.text.trim(),
                    prescription: prescription.text.trim(),
                  ),
                );
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      description.dispose();
      prescription.dispose();
    });
    if (mounted && result != null) {
      if (_draft.injuries.length >= 50) {
        await _notice('Limite atingido', 'São permitidas até 50 lesões.');
      } else {
        setState(() => _draft.injuries.add(result));
      }
    }
  }

  String get _title => switch (_step) {
    0 => 'Relação com o cavalo',
    1 => 'Nome do animal',
    2 => 'Microchip do cavalo',
    3 => 'Data de nascimento',
    4 => 'Raça',
    5 => 'Pelagem',
    6 => 'Sexo',
    7 => 'Imagens',
    8 => 'Modalidade de treinos',
    9 => 'Limitações físicas',
    10 => 'Observações de saúde',
    11 => 'Histórico de lesões',
    _ => 'Revise os dados',
  };

  String get _subtitle => switch (_step) {
    0 =>
      'Antes dos próximos passos, precisamos saber qual seu nível de relacionamento com o animal.',
    1 => 'Informe qual é o nome do seu companheiro equino.',
    2 => 'Informe o número do microchip do seu animal.',
    3 => 'Informe quando seu cavalo nasceu, para calcularmos sua idade.',
    4 => 'Selecione qual é a raça do seu animal.',
    5 => 'Selecione qual é a coloração da pelagem do seu cavalo.',
    6 => 'Selecione qual é o sexo do seu animal.',
    7 =>
      'Anexe uma ou mais imagens do seu companheiro de treinos. Você pode preencher isso mais tarde, se preferir.',
    8 => 'Selecione qual modalidade de esporte seu cavalo pratica.',
    9 =>
      'Informe se seu animal possui alguma limitação que o impossibilita de realizar algum tipo de exercício. Você pode preencher isso mais tarde, se preferir.',
    10 =>
      'Informe uma ou mais observações de saúde que possam ser úteis para a avaliação do profissional que prescreverá os treinos. Você pode preencher isso mais tarde, se preferir.',
    11 =>
      'Adicione um histórico das lesões que seu animal já sofreu, incluindo a data, a descrição e qual foi a prescrição dada com base na lesão. Você pode preencher isso mais tarde, se preferir.',
    _ => 'Confira se todas as informações estão corretas antes de continuar.',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: _completed || (_step == 0 && !_saving && !_validatingMicrochip),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_completed) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.whiteSmoke,
        appBar: AppBar(
          toolbarHeight: 78,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.seaGreen,
            ),
            tooltip: 'Voltar',
            onPressed: _back,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Image.asset(
                'assets/Logo_somente_simbolo.png',
                width: 52,
                height: 52,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.pets, color: AppColors.seaGreen),
              ),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  child: Row(
                    children: List.generate(
                      _lastStep + 1,
                      (index) => Expanded(
                        child: Container(
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: index <= _step
                                ? AppColors.seaGreen
                                : AppColors.alabasterGray,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 38, 28, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _title,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _subtitle,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 36),
                          _stepContent(),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                    child: OutlinedButton(
                      onPressed: (_saving || _validatingMicrochip)
                          ? null
                          : _next,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        side: const BorderSide(
                          color: AppColors.seaGreen,
                          width: 2,
                        ),
                        foregroundColor: AppColors.seaGreen,
                        shape: const StadiumBorder(),
                      ),
                      child: (_saving || _validatingMicrochip)
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _step == _lastStep
                                  ? 'Cadastrar cavalo'
                                  : 'Seguinte →',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepContent() => switch (_step) {
    0 => _relationshipStep(),
    1 => TextFormField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      maxLength: 80,
      decoration: const InputDecoration(labelText: 'Nome'),
      onChanged: (value) => _draft.name = value,
      validator: (value) => (value?.trim().length ?? 0) < 2
          ? 'Informe ao menos 2 caracteres.'
          : null,
    ),
    2 => TextFormField(
      controller: _chipController,
      key: const ValueKey('horse-microchip'),
      maxLength: 15,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'Código',
        helperText: '15 dígitos numéricos, sem letras ou espaços.',
      ),
      // Não bloqueia teclas alfabéticas: o usuário vê o erro ao avançar.
      // O campo não trata a verificação local como confirmação do servidor.
      onChanged: (value) => _draft.microchip = value,
      validator: (value) => !RegExp(r'^\d{15}$').hasMatch(value ?? '')
          ? 'O microchip deve conter exatamente 15 números.'
          : null,
    ),
    3 => _dateSelector(),
    4 => HorseSearchField(
      key: const ValueKey('horse-breed-field'),
      label: 'Raça',
      options: MockHorseCatalog.breeds,
      value: _draft.breed,
      onSelected: (value) => setState(() => _draft.breed = value),
    ),
    5 => HorseSearchField(
      key: const ValueKey('horse-coat-field'),
      label: 'Pelagem',
      options: MockHorseCatalog.coats,
      value: _draft.coat,
      onSelected: (value) => setState(() => _draft.coat = value),
    ),
    6 => HorseChoiceField<HorseSex>(
      label: 'Sexo',
      value: _draft.sex,
      options: HorseSex.values,
      name: (item) => item.label,
      onChanged: (item) => setState(() => _draft.sex = item),
    ),
    7 => _imagesStep(),
    8 => _modalityStep(),
    9 => _entriesStep(
      label: 'Adicionar limitação',
      icon: const Icon(
        Icons.do_not_touch_outlined,
        size: 24,
        color: AppColors.blueSpruce,
      ),
      list: _draft.physicalLimitations,
    ),
    10 => _entriesStep(
      label: 'Adicionar observação',
      icon: const HorseRegistrationPictogram(kind: HorsePictogram.health),
      list: _draft.healthNotes,
    ),
    11 => _injuryStep(),
    _ => _reviewStep(),
  };

  Widget _relationshipStep() => Column(
    children: [
      HorseChoiceField<HorseRelationship>(
        label: 'Relação com o cavalo',
        value: _draft.relationship,
        options: HorseRelationship.values,
        name: (item) => item.label,
        onChanged: (item) => setState(() => _draft.relationship = item),
      ),
      const SizedBox(height: 28),
      _infoText(
        'Proprietários são capazes de cadastrar e gerenciar os dados dos cavalos e seus treinos, mas não podem executá-los.',
      ),
      _infoText(
        'Atletas não têm permissão de cadastro ou edição dos dados do animal, mas podem executar os treinos prescritos para ele.',
      ),
      _infoText(
        'Proprietários que também são atletas possuem ambos os privilégios dos relacionamentos citados acima.',
      ),
    ],
  );

  Widget _infoText(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: AppColors.seaGreen),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );

  Widget _dateSelector() => InkWell(
    key: const ValueKey('horse-birth-date'),
    onTap: () => _pickDate(),
    child: InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Data de nascimento',
        suffixIcon: Icon(Icons.calendar_month, color: AppColors.seaGreen),
      ),
      child: Text(_displayDate(_draft.birthDate)),
    ),
  );

  Widget _imagesStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _smallAddButton('Adicionar imagem', Icons.add, _selectImages),
      const SizedBox(height: 14),
      for (final file in List<XFile>.of(_draft.images))
        HorseRegistrationEntryTile(
          file.name,
          const Icon(
            Icons.image_outlined,
            size: 24,
            color: AppColors.blueSpruce,
          ),
          () => setState(() => _draft.images.remove(file)),
        ),
      const SizedBox(height: 10),
      Text(
        'Opcional • JPG ou PNG • até 5 MB cada • máximo de 10 imagens',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  Widget _modalityStep() => FutureBuilder<List<HorseModality>>(
    future: _modalitiesFuture,
    builder: (context, snapshot) {
      if (!snapshot.hasData && !snapshot.hasError) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Column(
          children: [
            const Text('Não foi possível carregar as modalidades.'),
            TextButton(
              onPressed: () => setState(
                () => _modalitiesFuture = _repository.getModalities(),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        );
      }
      final options = snapshot.data ?? <HorseModality>[];
      return HorseChoiceField<String>(
        label: 'Modalidade',
        value: _draft.modality?.id ?? '',
        options: ['', ...options.map((option) => option.id)],
        name: (id) => id.isEmpty
            ? 'Sem modalidade'
            : options.firstWhere((option) => option.id == id).name,
        onChanged: (id) => setState(() {
          _draft.modality = id.isEmpty
              ? null
              : options.firstWhere((option) => option.id == id);
        }),
      );
    },
  );

  /// Botão do protótipo com o sinal de adição à direita do rótulo.
  Widget _smallAddButton(String label, IconData icon, VoidCallback onPressed) =>
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.alabasterGray.withValues(alpha: 0.35),
            foregroundColor: AppColors.prussianBlue,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Icon(icon, size: 19, color: AppColors.prussianBlue),
            ],
          ),
        ),
      );

  Widget _entriesStep({
    required String label,
    required Widget icon,
    required List<String> list,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _smallAddButton(
        label,
        Icons.add,
        () => _addTextItem(title: label, list: list),
      ),
      const SizedBox(height: 14),
      for (final item in List<String>.of(list))
        HorseRegistrationEntryTile(
          item,
          icon,
          () => setState(() => list.remove(item)),
        ),
    ],
  );

  Widget _injuryStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _smallAddButton('Adicionar lesão', Icons.add, _addInjury),
      const SizedBox(height: 14),
      for (final injury in List<HorseInjury>.of(_draft.injuries))
        HorseRegistrationEntryTile(
          '${_displayDate(injury.date)}\n${injury.description}'
          '${injury.prescription == null || injury.prescription!.isEmpty ? '' : '\n${injury.prescription}'}',
          const HorseRegistrationPictogram(kind: HorsePictogram.injury),
          () => setState(() => _draft.injuries.remove(injury)),
        ),
    ],
  );

  // Permite voltar da revisão ao campo escolhido.
  void _editStep(int step) => setState(() => _step = step);

  Widget _reviewStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      HorseRegistrationReviewField(
        'Relação',
        _draft.relationship.label,
        0,
        onEdit: _editStep,
      ),
      HorseRegistrationReviewField('Nome', _draft.name, 1, onEdit: _editStep),
      HorseRegistrationReviewField(
        'Microchip',
        _draft.microchip,
        2,
        onEdit: _editStep,
      ),
      HorseRegistrationReviewField(
        'Nascimento',
        _displayDate(_draft.birthDate),
        3,
        onEdit: _editStep,
      ),
      HorseRegistrationReviewField('Raça', _draft.breed, 4, onEdit: _editStep),
      HorseRegistrationReviewField(
        'Pelagem',
        _draft.coat,
        5,
        onEdit: _editStep,
      ),
      HorseRegistrationReviewField(
        'Sexo',
        _draft.sex.label,
        6,
        onEdit: _editStep,
      ),
      HorseRegistrationReviewField(
        'Modalidade',
        _draft.modality?.name ?? 'Sem modalidade',
        8,
        onEdit: _editStep,
      ),
      const SizedBox(height: 26),
      Text(
        'Informações adicionadas',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 14),
      HorseRegistrationReviewSectionTitle('Imagens', 7, onEdit: _editStep),
      for (final img in List<XFile>.of(_draft.images))
        HorseRegistrationEntryTile(
          img.name,
          const Icon(
            Icons.image_outlined,
            size: 24,
            color: AppColors.blueSpruce,
          ),
          () => setState(() => _draft.images.remove(img)),
        ),
      HorseRegistrationReviewSectionTitle(
        'Limitações físicas',
        9,
        onEdit: _editStep,
      ),
      for (final item in List<String>.of(_draft.physicalLimitations))
        HorseRegistrationEntryTile(
          item,
          const Icon(
            Icons.do_not_touch_outlined,
            size: 24,
            color: AppColors.blueSpruce,
          ),
          () => setState(() => _draft.physicalLimitations.remove(item)),
        ),
      HorseRegistrationReviewSectionTitle(
        'Observações de saúde',
        10,
        onEdit: _editStep,
      ),
      for (final item in List<String>.of(_draft.healthNotes))
        HorseRegistrationEntryTile(
          item,
          const HorseRegistrationPictogram(kind: HorsePictogram.health),
          () => setState(() => _draft.healthNotes.remove(item)),
        ),
      HorseRegistrationReviewSectionTitle(
        'Histórico de lesões',
        11,
        onEdit: _editStep,
      ),
      for (final injury in List<HorseInjury>.of(_draft.injuries))
        HorseRegistrationEntryTile(
          '${_displayDate(injury.date)} • ${injury.description}',
          const HorseRegistrationPictogram(kind: HorsePictogram.injury),
          () => setState(() => _draft.injuries.remove(injury)),
        ),
    ],
  );
}
