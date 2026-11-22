// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento da documentação e comentários explicativos para
// facilitar a compreensão dos fluxos de edição de exercícios, transição de
// privacidade (genérico vs específico), validação de cavalos vinculados,
// reutilização de modais e manipulação de mídias.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação da tela de edição de exercício (ExerciseEditScreen) com
// alternância dinâmica de privacidade (Genérico/Específico), seletor de cavalo
// vinculado, campos editáveis inline e adição de orientações, materiais e
// mídias utilizando os modais/seletores do cadastro.
// -----------------------------------------------------------------------------

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_dropdown_field.dart';
import 'package:horse_life/core/widgets/app_item_list_widgets.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/auth_header.dart';
import 'package:horse_life/core/widgets/auth_next_button.dart';
import 'package:horse_life/core/widgets/editable_review_field.dart';

import '../../application/states/exercise_material.dart';
import '../../application/states/exercise_media.dart';
import '../../data/models/exercise_detail_data.dart';
import '../../data/models/exercise_type.dart';
import '../../data/models/trainer_linked_horse.dart';
import '../../data/repositories/firebase_trainer_linked_horse_repository.dart';
import '../../data/repositories/trainer_linked_horse_repository.dart';
import '../widgets/add_exercise_guideline_dialog.dart';
import '../widgets/add_exercise_material_dialog.dart';
import 'exercise_media_screen.dart';

const _maxImageBytes = 5 * 1024 * 1024; // 5 MB por foto
const _maxVideoBytes = 50 * 1024 * 1024; // 50 MB por vídeo
const _maxImages = 10; // Cota máxima de imagens por exercício
const _maxVideos = 3; // Cota máxima de vídeos por exercício

const _supportedImageExtensions = <String>{'png', 'jpg', 'jpeg'};
const _supportedVideoExtensions = <String>{'mp4'};

/// Formulário de edição de um exercício existente no HorseLife.
///
/// Decisões arquiteturais e comportamentais:
/// 1. **Campos cadastrais com edição inline**: Nome, Descrição e Duração utilizam
///    [EditableReviewField] com alternância entre visualização estática e modo de edição
///    via ícone de lápis/check.
/// 2. **Transição de privacidade reativa**:
///    - Permite alternar entre `Genérico` e `Específico`;
///    - Ao selecionar `Específico`, exibe dinamicamente o seletor de cavalos vinculados;
///    - Carrega a lista de cavalos do treinador via [horseRepository] sob demanda;
///    - Preserva o cavalo originalmente vinculado mesmo que a listagem de animais
///      vinculados sofra variações de paginação;
///    - Bloqueia o salvamento caso a privacidade seja específica e nenhum cavalo
///      tenha sido selecionado.
/// 3. **Reutilização de modais do cadastro**:
///    - O link "Adicionar" de orientações abre [showAddExerciseGuidelineDialog];
///    - O link "Adicionar" de materiais abre [showAddExerciseMaterialDialog];
///    - O link "Adicionar" de mídias abre o seletor nativo de arquivos [pickExerciseMediaFiles],
///      validando as cotas de quantidade (10 imagens, 3 vídeos) e tamanho máximo (5MB/50MB).
/// 4. **Salvamento de alterações**:
///    - O botão de confirmação exibe o rótulo "Salvar alterações";
///    - Dispara [onSaved] ou retorna via [Navigator.pop] um objeto [ExerciseUpdate]
///      contendo os deltas a serem persistidos pela Cloud Function `updateExercise`.
class ExerciseEditScreen extends StatefulWidget {
  const ExerciseEditScreen({
    required this.exercise,
    this.horseRepository = const FirebaseTrainerLinkedHorseRepository(),
    this.initialHorses,
    this.filePicker = pickExerciseMediaFiles,
    this.fileSizeLoader,
    this.onSaved,
    this.onBack,
    super.key,
  });

  /// Exercício original cujos valores preenchem inicialmente o formulário.
  final ExerciseDetailData exercise;

  /// Repositório remoto de cavalos vinculados ao treinador autenticado.
  final TrainerLinkedHorseRepository horseRepository;

  /// Lista pré-carregada de animais vinculados (útil para testes unitários).
  final List<TrainerLinkedHorse>? initialHorses;

  /// Seletor de arquivos de mídia (injetável para testes).
  final ExerciseMediaFilePicker filePicker;

  /// Loader assíncrono de tamanho de arquivo em bytes.
  final ExerciseMediaFileSizeLoader? fileSizeLoader;

  /// Callback opcional executado ao salvar as alterações.
  final ValueChanged<ExerciseUpdate>? onSaved;

  /// Callback de retorno para a tela anterior.
  final VoidCallback? onBack;

  @override
  State<ExerciseEditScreen> createState() => _ExerciseEditScreenState();
}

class _ExerciseEditScreenState extends State<ExerciseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _durationController;
  final _nameFocus = FocusNode();
  final _descriptionFocus = FocusNode();
  final _durationFocus = FocusNode();
  final Set<_ExerciseEditFieldId> _editingFields = {};

  late ExerciseType _privacy;
  TrainerLinkedHorse? _selectedHorse;
  List<TrainerLinkedHorse> _linkedHorses = const [];
  bool _hasLoadedHorses = false;
  bool _isLoadingHorses = false;
  bool _hasHorsesLoadError = false;
  bool _isPrivacyMenuOpen = false;
  bool _isHorseMenuOpen = false;
  bool _isPickingMedia = false;

  late final List<String> _guidelines;
  late final List<ExerciseMaterial> _materials;
  late final List<ExerciseDetailMedia> _existingMedia;
  final List<String> _removedMediaPaths = [];
  final List<ExerciseMedia> _addedMedia = [];

  @override
  void initState() {
    super.initState();
    _privacy = widget.exercise.privacy;
    _selectedHorse = widget.exercise.horse;
    _nameController = TextEditingController(text: widget.exercise.name);
    _descriptionController = TextEditingController(
      text: widget.exercise.description,
    );
    _durationController = TextEditingController(
      text: widget.exercise.defaultDurationMinutes.toString(),
    );
    _guidelines = List.of(widget.exercise.guidelines);
    _materials = List.of(widget.exercise.materials);
    _existingMedia = List.of(widget.exercise.allMedia);

    final initialHorses = widget.initialHorses;
    if (initialHorses != null) {
      _linkedHorses = List.unmodifiable(initialHorses);
      _hasLoadedHorses = true;
      _syncSelectedHorseWithAvailable();
    } else if (_privacy == ExerciseType.specific) {
      _loadLinkedHorses();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _durationFocus.dispose();
    super.dispose();
  }

  /// Combina os cavalos vinculados retornados pela API com o cavalo atual do
  /// exercício (garantindo que edições mantendo o mesmo animal continuem válidas).
  List<TrainerLinkedHorse> get _availableHorses {
    final result = List<TrainerLinkedHorse>.of(_linkedHorses);
    final current = widget.exercise.horse;
    if (current != null &&
        !result.any((item) => item.id == current.id)) {
      result.insert(0, current);
    }
    return List.unmodifiable(result);
  }

  void _syncSelectedHorseWithAvailable() {
    final available = _availableHorses;
    if (available.isEmpty) {
      _selectedHorse = null;
      return;
    }
    final current = _selectedHorse;
    if (current != null) {
      final match = available.where((h) => h.id == current.id).firstOrNull;
      if (match != null) {
        _selectedHorse = match;
        return;
      }
    }
    _selectedHorse = available.first;
  }

  /// Carrega remotamente os animais vinculados ao treinador.
  Future<void> _loadLinkedHorses() async {
    if (_isLoadingHorses) return;
    setState(() {
      _isLoadingHorses = true;
      _hasHorsesLoadError = false;
    });

    try {
      final response = await widget.horseRepository.fetchLinkedHorses();
      final horses = response
          .map(
            (horse) => TrainerLinkedHorse(
              id: horse.id.trim(),
              name: horse.name.trim(),
            ),
          )
          .where((horse) => horse.name.isNotEmpty)
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _linkedHorses = horses;
        _hasLoadedHorses = true;
        _isLoadingHorses = false;
        _syncSelectedHorseWithAvailable();
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _isLoadingHorses = false;
        _hasHorsesLoadError = true;
      });
    }
  }

  /// Atualiza o tipo de privacidade e dispara a carga de cavalos se necessário.
  void _onPrivacyChanged(ExerciseType nextPrivacy) {
    setState(() {
      _privacy = nextPrivacy;
      _isPrivacyMenuOpen = false;
      if (nextPrivacy == ExerciseType.specific) {
        _syncSelectedHorseWithAvailable();
      }
    });
    if (nextPrivacy == ExerciseType.specific &&
        !_hasLoadedHorses &&
        !_isLoadingHorses) {
      _loadLinkedHorses();
    }
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  void _toggleEditing(_ExerciseEditFieldId field) {
    if (_editingFields.contains(field)) {
      setState(() => _editingFields.remove(field));
      _focusFor(field).unfocus();
      return;
    }

    setState(() => _editingFields.add(field));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusFor(field).requestFocus();
    });
  }

  FocusNode _focusFor(_ExerciseEditFieldId field) {
    return switch (field) {
      _ExerciseEditFieldId.name => _nameFocus,
      _ExerciseEditFieldId.description => _descriptionFocus,
      _ExerciseEditFieldId.duration => _durationFocus,
    };
  }

  String? _validateName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Preencha este campo.';
    if (trimmed.length < 3 || trimmed.length > 80) {
      return 'O nome deve ter entre 3 e 80 caracteres.';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Preencha este campo.';
    if (trimmed.length > 1000) {
      return 'A descrição deve ter no máximo 1000 caracteres.';
    }
    return null;
  }

  String? _validateDuration(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Preencha este campo.';
    final minutes = int.tryParse(trimmed);
    if (minutes == null || minutes < 1 || minutes > 240) {
      return 'Informe uma duração válida entre 1 e 240 minutos.';
    }
    return null;
  }

  // --- Orientações (mesmo modal do cadastro) ----------------------------------

  Future<void> _addGuideline() async {
    if (_guidelines.length >= 30) {
      _showError('Limite máximo de 30 orientações atingido.');
      return;
    }

    final guideline = await showAddExerciseGuidelineDialog(context);
    if (!mounted || guideline == null || guideline.trim().isEmpty) return;

    final normalized = guideline.trim();
    if (_guidelines.any(
      (existing) => existing.toLowerCase() == normalized.toLowerCase(),
    )) {
      _showError('Essa orientação já foi adicionada.');
      return;
    }

    setState(() => _guidelines.add(normalized));
  }

  void _removeGuideline(int index) {
    setState(() => _guidelines.removeAt(index));
  }

  // --- Materiais necessários (mesmo modal do cadastro) ------------------------

  Future<void> _addMaterial() async {
    if (_materials.length >= 30) {
      _showError('Limite máximo de 30 materiais atingido.');
      return;
    }

    final material = await showAddExerciseMaterialDialog(context);
    if (!mounted || material == null) return;

    final normalizedName = material.name.trim().toLowerCase();
    if (_materials.any(
      (existing) => existing.name.trim().toLowerCase() == normalizedName,
    )) {
      _showError('Esse material já foi adicionado.');
      return;
    }

    setState(() => _materials.add(material));
  }

  void _removeMaterial(int index) {
    setState(() => _materials.removeAt(index));
  }

  // --- Mídias auxiliares (mesmo seletor nativo e regras do cadastro) ----------

  ExerciseMediaType? _classifyMediaFile(XFile file) {
    final parts = file.name.toLowerCase().split('.');
    if (parts.length < 2) return null;
    final extension = parts.last;
    if (_supportedImageExtensions.contains(extension)) {
      return ExerciseMediaType.image;
    }
    if (_supportedVideoExtensions.contains(extension)) {
      return ExerciseMediaType.video;
    }
    return null;
  }

  Future<void> _pickMediaFiles() async {
    if (_isPickingMedia) return;
    setState(() => _isPickingMedia = true);

    try {
      final files = await widget.filePicker();
      if (!mounted || files.isEmpty) return;

      var imageCount =
          _existingMedia.where((m) => m.type == ExerciseMediaType.image).length +
          _addedMedia.where((m) => m.type == ExerciseMediaType.image).length;
      var videoCount =
          _existingMedia.where((m) => m.type == ExerciseMediaType.video).length +
          _addedMedia.where((m) => m.type == ExerciseMediaType.video).length;

      final validEntries = <(XFile, ExerciseMediaType, int)>[];

      for (final file in files) {
        final mediaType = _classifyMediaFile(file);
        if (mediaType == null) {
          _showError(
            'Formato não suportado. Utilize imagens JPG/PNG ou vídeos MP4.',
          );
          continue;
        }

        final size = await (widget.fileSizeLoader?.call(file) ?? file.length());

        if (mediaType == ExerciseMediaType.image) {
          if (imageCount >= _maxImages) {
            _showError('Limite máximo de $_maxImages imagens atingido.');
            continue;
          }
          if (size > _maxImageBytes) {
            _showError('A foto ${file.name} excede o limite máximo de 5 MB.');
            continue;
          }
          imageCount++;
        } else {
          if (videoCount >= _maxVideos) {
            _showError('Limite máximo de $_maxVideos vídeos atingido.');
            continue;
          }
          if (size > _maxVideoBytes) {
            _showError('O vídeo ${file.name} excede o limite máximo de 50 MB.');
            continue;
          }
          videoCount++;
        }

        validEntries.add((file, mediaType, size));
      }

      if (validEntries.isEmpty || !mounted) return;

      final newItems = [
        for (final entry in validEntries)
          ExerciseMedia(
            name: entry.$1.name,
            path: entry.$1.path,
            type: entry.$2,
            sizeInBytes: entry.$3,
            mimeType: entry.$1.mimeType,
            readBytes: entry.$1.readAsBytes,
          ),
      ];

      setState(() => _addedMedia.addAll(newItems));
    } on Object {
      if (!mounted) return;
      _showError('Não foi possível acessar os arquivos selecionados.');
    } finally {
      if (mounted) setState(() => _isPickingMedia = false);
    }
  }

  void _removeExistingMedia(int index) {
    setState(() {
      final removed = _existingMedia.removeAt(index);
      if (removed.path.trim().isNotEmpty) {
        _removedMediaPaths.add(removed.path.trim());
      }
    });
  }

  void _removeAddedMedia(int index) {
    setState(() => _addedMedia.removeAt(index));
  }

  // --- Validação e salvamento -------------------------------------------------

  void _save() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    // Validação de obrigatoriedade do cavalo quando o exercício é específico
    if (_privacy == ExerciseType.specific) {
      if (_isLoadingHorses) {
        _showError('Aguarde o carregamento dos cavalos vinculados.');
        return;
      }
      if (_availableHorses.isEmpty) {
        _showError(
          'Você precisa ter pelo menos um cavalo vinculado para salvar um exercício específico.',
        );
        return;
      }
      if (_selectedHorse == null || _selectedHorse!.id.trim().isEmpty) {
        _showError(
          'Selecione um cavalo vinculado para salvar o exercício específico.',
        );
        return;
      }
    }

    final update = ExerciseUpdate(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      defaultDurationMinutes: int.parse(_durationController.text.trim()),
      guidelines: List.unmodifiable(_guidelines),
      materials: List.unmodifiable(_materials),
      privacy: _privacy,
      horse: _privacy == ExerciseType.specific ? _selectedHorse : null,
      removedMediaPaths: List.unmodifiable(_removedMediaPaths),
      addedMedia: List.unmodifiable(_addedMedia),
    );

    // Evita requisições redundantes se nenhuma informação foi alterada
    if (!update.hasAnyChanges(widget.exercise)) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.blueSpruce,
        icon: Icons.info_outline_rounded,
        message: 'Nenhuma alteração realizada.',
      );
      Navigator.of(context).pop(null);
      return;
    }

    final onSaved = widget.onSaved;
    if (onSaved != null) {
      onSaved(update);
      return;
    }
    Navigator.of(context).pop(update);
  }

  void _showError(String message) {
    AppSnackBar.show(
      context,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline_rounded,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 18, 28, 36),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 54,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AuthHeader(onBack: _goBack),
                    const SizedBox(height: 36),
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Editar exercício',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Altere e adicione o que desejar,\n'
                              'mas não esqueça de salvar.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 21,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Seletor de Privacidade (Genérico / Específico)
                            _buildPrivacySection(textTheme),
                            // Seletor condicional de cavalo quando for específico
                            if (_privacy == ExerciseType.specific) ...[
                              const SizedBox(height: 20),
                              _buildHorseSection(textTheme),
                            ],
                            const SizedBox(height: 28),
                            // Formulário de campos textuais/numéricos editáveis inline
                            _buildForm(),
                            const SizedBox(height: 30),
                            // Lista de Orientações com link de adição
                            _buildGuidelinesSection(textTheme),
                            const SizedBox(height: 28),
                            // Lista de Materiais com link de adição
                            _buildMaterialsSection(textTheme),
                            const SizedBox(height: 28),
                            // Lista de Mídias (existentes e novas) com link de adição
                            _buildMediaSection(textTheme),
                            const SizedBox(height: 40),
                            // Botão de salvar alterações com rótulo descritivo
                            AuthNextButton(
                              buttonKey: const Key('save-exercise-edit-button'),
                              label: 'Salvar alterações',
                              showArrow: false,
                              onPressed: _save,
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

  Widget _buildPrivacySection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Privacidade',
          style: textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        AppDropdownField<ExerciseType>(
          style: AppDropdownStyle.rounded,
          dropdownKey: const Key('exercise-edit-privacy-dropdown'),
          value: _privacy,
          options: const [ExerciseType.generic, ExerciseType.specific],
          labelFor: (type) => type.label,
          isOpen: _isPrivacyMenuOpen,
          onTap: () => setState(() => _isPrivacyMenuOpen = true),
          onChanged: _onPrivacyChanged,
        ),
      ],
    );
  }

  Widget _buildHorseSection(TextTheme textTheme) {
    final available = _availableHorses;

    return Column(
      key: const Key('exercise-edit-horse-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cavalo selecionado',
          style: textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (_isLoadingHorses)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: CircularProgressIndicator(
                key: Key('exercise-edit-horses-loading'),
              ),
            ),
          )
        else if (_hasHorsesLoadError && available.isEmpty)
          Column(
            children: [
              const Text(
                'Não foi possível carregar os cavalos vinculados.',
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: _loadLinkedHorses,
                child: const Text('Tentar novamente'),
              ),
            ],
          )
        else if (available.isEmpty)
          Container(
            key: const Key('exercise-edit-no-horses-message'),
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE9E9E9),
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            child: Text(
              'Nenhum cavalo vinculado disponível. Vincule-se a um animal para definir o exercício como específico.',
              style: textTheme.bodyLarge?.copyWith(color: AppColors.error),
            ),
          )
        else
          AppDropdownField<TrainerLinkedHorse>(
            style: AppDropdownStyle.rounded,
            dropdownKey: const Key('exercise-edit-horse-dropdown'),
            label: 'Selecione um cavalo',
            value: _selectedHorse,
            options: available,
            labelFor: (horse) => horse.name,
            isOpen: _isHorseMenuOpen,
            onTap: () => setState(() => _isHorseMenuOpen = true),
            onChanged: (horse) => setState(() {
              _selectedHorse = horse;
              _isHorseMenuOpen = false;
            }),
          ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          EditableReviewField(
            fieldKey: const Key('exercise-edit-name-field'),
            label: 'Nome',
            controller: _nameController,
            focusNode: _nameFocus,
            isEditing: _editingFields.contains(_ExerciseEditFieldId.name),
            validator: _validateName,
            textInputAction: TextInputAction.next,
            onToggleEditing: () => _toggleEditing(_ExerciseEditFieldId.name),
          ),
          const SizedBox(height: 22),
          EditableReviewField(
            fieldKey: const Key('exercise-edit-description-field'),
            label: 'Descrição',
            controller: _descriptionController,
            focusNode: _descriptionFocus,
            isEditing: _editingFields.contains(
              _ExerciseEditFieldId.description,
            ),
            minLines: 1,
            maxLines: 4,
            validator: _validateDescription,
            textInputAction: TextInputAction.done,
            onToggleEditing: () =>
                _toggleEditing(_ExerciseEditFieldId.description),
          ),
          const SizedBox(height: 22),
          EditableReviewField(
            fieldKey: const Key('exercise-edit-duration-field'),
            label: 'Tempo',
            controller: _durationController,
            focusNode: _durationFocus,
            isEditing: _editingFields.contains(_ExerciseEditFieldId.duration),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validateDuration,
            textInputAction: TextInputAction.done,
            onToggleEditing: () =>
                _toggleEditing(_ExerciseEditFieldId.duration),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionAddLink({
    required Key buttonKey,
    required VoidCallback? onPressed,
    bool isLoading = false,
    required TextTheme textTheme,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: buttonKey,
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.seaGreen,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: isLoading
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_rounded, size: 22),
        label: Text(
          'Adicionar',
          style: textTheme.titleLarge?.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.w500,
            color: AppColors.seaGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelinesSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Orientações',
          style: textTheme.titleLarge?.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _buildSectionAddLink(
          buttonKey: const Key('exercise-edit-add-guideline-button'),
          onPressed: _addGuideline,
          textTheme: textTheme,
        ),
        const SizedBox(height: 12),
        if (_guidelines.isEmpty)
          Text(
            'Nenhuma orientação adicionada.',
            key: const Key('exercise-edit-empty-guidelines'),
            style: textTheme.bodyLarge?.copyWith(color: AppColors.grey),
          )
        else
          for (var index = 0; index < _guidelines.length; index++) ...[
            AppRemovableItemTile(
              key: ValueKey('exercise-edit-guideline-$index'),
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: AppColors.seaGreen,
              label: _guidelines[index],
              minHeight: 72,
              maxLines: null,
              removeKey: ValueKey('remove-exercise-edit-guideline-$index'),
              onRemove: () => _removeGuideline(index),
            ),
            if (index < _guidelines.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _buildMaterialsSection(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Materiais necessários',
          style: textTheme.titleLarge?.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _buildSectionAddLink(
          buttonKey: const Key('exercise-edit-add-material-button'),
          onPressed: _addMaterial,
          textTheme: textTheme,
        ),
        const SizedBox(height: 12),
        if (_materials.isEmpty)
          Text(
            'Nenhum material adicionado.',
            key: const Key('exercise-edit-empty-materials'),
            style: textTheme.bodyLarge?.copyWith(color: AppColors.grey),
          )
        else
          for (var index = 0; index < _materials.length; index++) ...[
            AppRemovableItemTile(
              key: ValueKey('exercise-edit-material-$index'),
              icon: Icons.handyman_outlined,
              iconColor: AppColors.seaGreen,
              label: _materials[index].displayLabel,
              removeKey: ValueKey('remove-exercise-edit-material-$index'),
              onRemove: () => _removeMaterial(index),
            ),
            if (index < _materials.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _buildMediaSection(TextTheme textTheme) {
    final hasAnyMedia = _existingMedia.isNotEmpty || _addedMedia.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mídias auxiliares',
          style: textTheme.titleLarge?.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _buildSectionAddLink(
          buttonKey: const Key('exercise-edit-add-media-button'),
          onPressed: _pickMediaFiles,
          isLoading: _isPickingMedia,
          textTheme: textTheme,
        ),
        const SizedBox(height: 12),
        if (!hasAnyMedia)
          Text(
            'Nenhuma mídia adicionada.',
            key: const Key('exercise-edit-empty-media'),
            style: textTheme.bodyLarge?.copyWith(color: AppColors.grey),
          )
        else ...[
          for (var index = 0; index < _existingMedia.length; index++) ...[
            AppRemovableItemTile(
              key: ValueKey('exercise-edit-existing-media-$index'),
              icon: _existingMedia[index].type == ExerciseMediaType.video
                  ? Icons.movie_outlined
                  : Icons.image_outlined,
              iconColor: AppColors.seaGreen,
              label: _existingMedia[index].fileName,
              removeKey: ValueKey('remove-exercise-edit-existing-media-$index'),
              onRemove: () => _removeExistingMedia(index),
            ),
            if (index < _existingMedia.length - 1 || _addedMedia.isNotEmpty)
              const SizedBox(height: 12),
          ],
          for (var index = 0; index < _addedMedia.length; index++) ...[
            AppRemovableItemTile(
              key: ValueKey('exercise-edit-added-media-$index'),
              icon: _addedMedia[index].type == ExerciseMediaType.video
                  ? Icons.movie_outlined
                  : Icons.image_outlined,
              iconColor: AppColors.seaGreen,
              label: _addedMedia[index].name,
              removeKey: ValueKey('remove-exercise-edit-added-media-$index'),
              onRemove: () => _removeAddedMedia(index),
            ),
            if (index < _addedMedia.length - 1) const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

enum _ExerciseEditFieldId { name, description, duration }
