// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos blocos de estado, campos editáveis, imagens,
// listas complementares, validação e persistência da edição.
//
// Data: 13/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da edição completa do cavalo com widgets compartilhados,
// microchip somente leitura e persistência por updateHorse.
// Alteração: Reutilização dos modais de inclusão de limitação, observação de
// saúde e lesão compartilhados com a tela principal do perfil.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_dropdown_field.dart';
import 'package:horse_life/core/widgets/editable_review_field.dart';
import 'package:horse_life/core/widgets/inline_add_button.dart';
import 'package:horse_life/features/horses/data/models/horse_profile_data.dart';
import 'package:horse_life/features/horses/data/repositories/horse_profile_repository.dart';
import 'package:horse_life/features/horses/presentation/services/horse_image_selection_service.dart';
import 'package:horse_life/features/horses/presentation/widgets/horse_injury_dialog.dart';
import 'package:horse_life/features/horses/presentation/widgets/horse_registration_calendar.dart';
import 'package:horse_life/features/horses/presentation/widgets/horse_registration_entry_tile.dart';
import 'package:horse_life/features/horses/presentation/widgets/horse_registration_pictogram.dart';
import 'package:horse_life/features/horses/presentation/widgets/horse_text_entry_dialog.dart';
import 'package:material_symbols_icons/symbols.dart';

enum _HorseTextField { name, breed, coat }

/// Formulário completo de edição do cavalo.
///
/// Mantém uma cópia local do perfil, controla imagens e listas auxiliares e,
/// ao salvar, devolve somente as diferenças aceitas por `updateHorse`.
class HorseProfileEditScreen extends StatefulWidget {
  const HorseProfileEditScreen({
    required this.horse,
    required this.repository,
    this.imageSelectionService = const HorseImageSelectionService(),
    super.key,
  });

  final HorseProfileData horse;
  final HorseProfileRepository repository;
  final HorseImageSelectionService imageSelectionService;

  @override
  State<HorseProfileEditScreen> createState() => _HorseProfileEditScreenState();
}

class _HorseProfileEditScreenState extends State<HorseProfileEditScreen> {
  // --- Estado editável e recursos do formulário -----------------------------
  final _formKey = GlobalKey<FormState>();
  late HorseProfileData _horse;
  late final TextEditingController _name;
  late final TextEditingController _microchip;
  late final TextEditingController _breed;
  late final TextEditingController _coat;
  late final Map<_HorseTextField, FocusNode> _focusNodes;
  final Set<_HorseTextField> _editing = {};
  late DateTime _birthDate;
  late String _sex;
  late String? _modalityId;
  late List<String> _limitations;
  late List<String> _healthNotes;
  late List<HorseInjuryRecord> _injuries;
  late Future<List<HorseProfileModality>> _modalities;
  bool _changingImages = false;

  // --- Inicialização e descarte ---------------------------------------------
  // Os valores remotos são copiados para permitir edição sem mutar o modelo
  // original; controllers e focos pertencentes à tela são liberados ao sair.

  @override
  void initState() {
    super.initState();
    _horse = widget.horse;
    _name = TextEditingController(text: _horse.name);
    _microchip = TextEditingController(text: _horse.microchip);
    _breed = TextEditingController(text: _horse.breed);
    _coat = TextEditingController(text: _horse.coat);
    _focusNodes = {
      for (final field in _HorseTextField.values) field: FocusNode(),
    };
    _birthDate = _horse.birthDate;
    _sex = _horse.sex;
    _modalityId = _horse.modality?.id;
    _limitations = List.of(_horse.physicalLimitations);
    _healthNotes = List.of(_horse.healthNotes);
    _injuries = List.of(_horse.injuries);
    _modalities = widget.repository.getModalities();
  }

  @override
  void dispose() {
    _name.dispose();
    _microchip.dispose();
    _breed.dispose();
    _coat.dispose();
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // --- Campos básicos e validação -------------------------------------------

  void _toggleEditing(_HorseTextField field) {
    setState(() {
      if (_editing.remove(field)) {
        _focusNodes[field]!.unfocus();
      } else {
        _editing.add(field);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _focusNodes[field]?.requestFocus(),
        );
      }
    });
  }

  String? _validateText(String? value, String label, int maxLength) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label é obrigatório.';
    if (text.length > maxLength) return 'Use no máximo $maxLength caracteres.';
    return null;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final selected = await showHorseRegistrationCalendar(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(now.year - 50, now.month, now.day),
      lastDate: now,
      title: 'Data de nascimento',
    );
    if (selected != null && mounted) setState(() => _birthDate = selected);
  }

  // --- Limitações, observações e lesões -------------------------------------
  // Os modais compartilhados aplicam os limites do contrato antes de incluir
  // novos itens nas cópias mantidas pelo formulário.

  Future<void> _addTextItem({
    required String title,
    required List<String> target,
  }) async {
    if (target.length >= 30) {
      _showMessage('São permitidos até 30 registros nesta seção.');
      return;
    }
    final value = await showHorseTextEntryDialog(context, title: title);
    if (mounted && value != null && value.isNotEmpty) {
      setState(() => target.add(value));
    }
  }

  Future<void> _addInjury() async {
    if (_injuries.length >= 50) {
      _showMessage('São permitidas até 50 lesões.');
      return;
    }
    final injury = await showHorseInjuryDialog(
      context: context,
      birthDate: _birthDate,
    );
    if (!mounted || injury == null) return;
    setState(() {
      _injuries.add(
        HorseInjuryRecord(
          date: injury.date,
          description: injury.description,
          prescription: injury.prescription,
        ),
      );
      _injuries.sort((a, b) => b.date.compareTo(a.date));
    });
  }

  // --- Inclusão e remoção de imagens ----------------------------------------
  // A seleção valida permissão e formato; o repositório executa o pipeline
  // remoto e devolve um novo perfil para atualizar a galeria local.

  Future<void> _addImages() async {
    final selection = await widget.imageSelectionService.select(
      currentCount: _horse.images.length,
    );
    if (!mounted) return;
    if (selection.access != HorseImageLibraryAccess.granted) {
      _showMessage(
        selection.access == HorseImageLibraryAccess.permanentlyDenied
            ? 'O acesso à galeria está bloqueado. Ative a permissão nas configurações do aparelho.'
            : 'Permita o acesso à galeria para adicionar imagens.',
      );
      return;
    }
    if (selection.rejected > 0) {
      _showMessage(
        '${selection.rejected} imagem(ns) não puderam ser adicionadas.',
      );
    }
    if (selection.accepted.isEmpty) return;
    setState(() => _changingImages = true);
    try {
      final uploads = <HorseProfileImageUpload>[];
      for (final file in selection.accepted) {
        uploads.add(
          HorseProfileImageUpload(
            fileName: file.name,
            bytes: await file.readAsBytes(),
          ),
        );
      }
      final result = await widget.repository.addHorseImages(
        _horse.id,
        images: uploads,
      );
      if (mounted) {
        setState(() => _horse = result.horse);
        if (result.failed > 0) {
          _showMessage(
            '${result.uploaded} imagem(ns) enviada(s); '
            '${result.failed} não puderam ser enviadas.',
          );
        }
      }
    } on HorseImageUploadFailure catch (error) {
      debugPrint('$error');
      if (mounted) _showMessage(error.userMessage);
    } catch (error, stackTrace) {
      debugPrint('Falha inesperada ao adicionar imagem: $error\n$stackTrace');
      if (mounted) _showMessage('Não foi possível adicionar a imagem.');
    } finally {
      if (mounted) setState(() => _changingImages = false);
    }
  }

  Future<void> _removeImage(HorseProfileImage image) async {
    setState(() => _changingImages = true);
    try {
      final updated = await widget.repository.removeHorseImage(
        _horse.id,
        image.path,
      );
      if (mounted) setState(() => _horse = updated);
    } catch (_) {
      if (mounted) _showMessage('Não foi possível remover a imagem.');
    } finally {
      if (mounted) setState(() => _changingImages = false);
    }
  }

  // --- Feedback e consolidação das alterações -------------------------------

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Campos iguais aos originais viram `null`, evitando reenvio desnecessário e
  // preservando dados legados que não foram alterados nesta edição.
  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final name = _name.text.trim();
    final breed = _breed.text.trim();
    final coat = _coat.text.trim();
    Navigator.of(context).pop(
      HorseProfileUpdate(
        name: name == widget.horse.name ? null : name,
        birthDate: _birthDate == widget.horse.birthDate ? null : _birthDate,
        breed: breed == widget.horse.breed ? null : breed,
        coat: coat == widget.horse.coat ? null : coat,
        sex: _sex == widget.horse.sex ? null : _sex,
        modalityId: _modalityId,
        shouldUpdateModality: _modalityId != widget.horse.modality?.id,
        physicalLimitations: horseProfileListChanges(
          widget.horse.physicalLimitations,
          _limitations,
        ),
        healthNotes: horseProfileListChanges(
          widget.horse.healthNotes,
          _healthNotes,
        ),
        injuries: horseProfileListChanges(widget.horse.injuries, _injuries),
      ),
    );
  }

  // --- Composição da tela e de suas seções ----------------------------------

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.whiteSmoke,
    appBar: AppBar(
      toolbarHeight: 82,
      backgroundColor: AppColors.whiteSmoke,
      leading: IconButton(
        tooltip: 'Voltar',
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.seaGreen),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Image.asset(
            'assets/Logo_somente_simbolo.png',
            width: 52,
            height: 52,
          ),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 44),
            children: [
              Text(
                'Editar cavalo',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 22),
              Text(
                'Altere e adicione o que desejar,\nmas não esqueça de salvar.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 36),
              _editableField(
                field: _HorseTextField.name,
                label: 'Nome',
                controller: _name,
                maxLength: 80,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('horse-edit-microchip-field'),
                controller: _microchip,
                readOnly: true,
                enableInteractiveSelection: true,
                decoration: const InputDecoration(
                  labelText: 'Microchip',
                  suffixIcon: Icon(Icons.lock_outline, color: AppColors.grey),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                key: const Key('horse-edit-birth-date-field'),
                onTap: _pickBirthDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data de nascimento',
                    suffixIcon: Icon(Symbols.event, color: AppColors.seaGreen),
                  ),
                  child: Text(_formatDate(_birthDate)),
                ),
              ),
              const SizedBox(height: 16),
              _editableField(
                field: _HorseTextField.breed,
                label: 'Raça',
                controller: _breed,
                maxLength: 60,
              ),
              const SizedBox(height: 16),
              _editableField(
                field: _HorseTextField.coat,
                label: 'Pelagem',
                controller: _coat,
                maxLength: 60,
              ),
              const SizedBox(height: 16),
              AppDropdownField<String>(
                dropdownKey: const Key('horse-edit-sex-field'),
                label: 'Sexo',
                value: _sex,
                options: const ['MACHO', 'FEMEA'],
                labelFor: (value) => value == 'FEMEA' ? 'Fêmea' : 'Macho',
                onChanged: (value) => setState(() => _sex = value),
              ),
              const SizedBox(height: 16),
              _modalityField(),
              const SizedBox(height: 38),
              Text(
                'Informações adicionadas',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              _imagesSection(),
              _textSection(
                title: 'Limitações físicas',
                items: _limitations,
                addButtonKey: const Key('add-horse-edit-limitation-button'),
                icon: const Icon(
                  Symbols.do_not_touch,
                  color: AppColors.blueSpruce,
                ),
                onAdd: () => _addTextItem(
                  title: 'Adicionar limitação',
                  target: _limitations,
                ),
              ),
              _textSection(
                title: 'Observações de saúde',
                items: _healthNotes,
                addButtonKey: const Key('add-horse-edit-health-note-button'),
                icon: const HorseRegistrationPictogram(
                  kind: HorsePictogram.health,
                ),
                onAdd: () => _addTextItem(
                  title: 'Adicionar observação',
                  target: _healthNotes,
                ),
              ),
              _injuriesSection(),
              const SizedBox(height: 28),
              OutlinedButton(
                key: const Key('save-horse-profile-button'),
                onPressed: _changingImages ? null : _save,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  foregroundColor: AppColors.seaGreen,
                  side: const BorderSide(color: AppColors.seaGreen, width: 2),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Salvar alterações'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _editableField({
    required _HorseTextField field,
    required String label,
    required TextEditingController controller,
    required int maxLength,
  }) => EditableReviewField(
    fieldKey: ValueKey('horse-edit-${field.name}-field'),
    label: label,
    controller: controller,
    focusNode: _focusNodes[field]!,
    isEditing: _editing.contains(field),
    onToggleEditing: () => _toggleEditing(field),
    validator: (value) => _validateText(value, label, maxLength),
    textInputAction: TextInputAction.done,
  );

  Widget _modalityField() => FutureBuilder<List<HorseProfileModality>>(
    future: _modalities,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Row(
          children: [
            const Expanded(
              child: Text('Não foi possível carregar modalidades.'),
            ),
            TextButton(
              onPressed: () => setState(
                () => _modalities = widget.repository.getModalities(),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final modalities = snapshot.data!;
      final ids = ['', ...modalities.map((item) => item.id)];
      if (_modalityId != null && !ids.contains(_modalityId)) {
        ids.add(_modalityId!);
      }
      return AppDropdownField<String>(
        dropdownKey: const Key('horse-edit-modality-field'),
        label: 'Modalidade',
        value: _modalityId ?? '',
        options: ids,
        labelFor: (id) {
          if (id.isEmpty) return 'Sem modalidade';
          for (final modality in modalities) {
            if (modality.id == id) return modality.name;
          }
          return _horse.modality?.name ?? 'Modalidade atual';
        },
        onChanged: (id) => setState(() => _modalityId = id.isEmpty ? null : id),
      );
    },
  );

  Widget _imagesSection() => _EditSection(
    title: 'Imagens',
    onAdd: _changingImages ? null : _addImages,
    addButtonKey: const Key('add-horse-edit-image-button'),
    children: [
      if (_changingImages)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: LinearProgressIndicator(),
        ),
      if (_horse.images.isEmpty) const Text('Nenhuma imagem adicionada.'),
      for (final image in _horse.images)
        HorseRegistrationEntryTile(
          image.path.split('/').last,
          const Icon(Symbols.image, color: AppColors.blueSpruce),
          () => _removeImage(image),
        ),
    ],
  );

  Widget _textSection({
    required String title,
    required List<String> items,
    required Key addButtonKey,
    required Widget icon,
    required VoidCallback onAdd,
  }) => _EditSection(
    title: title,
    onAdd: onAdd,
    addButtonKey: addButtonKey,
    children: [
      if (items.isEmpty) const Text('Nenhum registro.'),
      for (final item in List<String>.of(items))
        HorseRegistrationEntryTile(
          item,
          icon,
          () => setState(() => items.remove(item)),
        ),
    ],
  );

  Widget _injuriesSection() => _EditSection(
    title: 'Histórico de lesões',
    onAdd: _addInjury,
    addButtonKey: const Key('add-horse-edit-injury-button'),
    children: [
      if (_injuries.isEmpty) const Text('Nenhuma lesão registrada.'),
      for (final injury in List<HorseInjuryRecord>.of(_injuries))
        HorseRegistrationEntryTile(
          '${_formatDate(injury.date)}\n${injury.description}'
          '${injury.prescription == null || injury.prescription!.isEmpty ? '' : '\n${injury.prescription}'}',
          const HorseRegistrationPictogram(kind: HorsePictogram.injury),
          () => setState(() => _injuries.remove(injury)),
        ),
    ],
  );
}

/// Agrupa título, conteúdo, ação de inclusão e espaçamento de cada seção.
class _EditSection extends StatelessWidget {
  const _EditSection({
    required this.title,
    required this.children,
    required this.onAdd,
    this.addButtonKey,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onAdd;
  final Key? addButtonKey;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (onAdd != null) ...[
          const SizedBox(height: 6),
          InlineAddButton(key: addButtonKey, onPressed: onAdd!),
        ],
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
