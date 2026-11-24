// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da edição do perfil profissional com nome, recuperação de
// senha, anexos, regiões e persistência sequencial pelo backend existente.
// -----------------------------------------------------------------------------

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/add_trainer_certifications_dialog.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/service_area_dialogs.dart';
import 'package:horse_life/features/authentication/application/states/trainer_document.dart';
import 'package:horse_life/features/authentication/application/states/trainer_service_area.dart';
import 'package:horse_life/features/authentication/data/repositories/brazilian_locations_repository.dart';
import 'package:horse_life/features/authentication/data/repositories/password_reset_repository.dart';
import 'package:horse_life/features/authentication/data/repositories/registration_repository.dart';
import 'package:horse_life/features/authentication/presentation/screens/trainer_experience_screen.dart';
import 'package:horse_life/features/profile/data/models/trainer_profile_data.dart';
import 'package:horse_life/features/profile/data/repositories/trainer_profile_repository.dart';

typedef TrainerProfileUpdateHandler =
    Future<void> Function(TrainerProfileUpdate update);
typedef TrainerEditDocumentUploader =
    Future<void> Function(TrainerDocument document);
typedef TrainerPasswordResetRequester = Future<String> Function(String email);

/// Edita somente os campos suportados pelas callables existentes.
///
/// As remoções e os dados textuais são enviados primeiro. Novos PDFs só são
/// enviados depois da confirmação de `updateTrainerProfile`, preservando os
/// índices de arquivos administrados pelo backend.
class TrainerEditProfileScreen extends StatefulWidget {
  const TrainerEditProfileScreen({
    required this.profile,
    required this.updateProfile,
    required this.uploadExperience,
    required this.uploadCertification,
    required this.requestPasswordReset,
    this.experienceFilePicker = pickTrainerExperienceDocument,
    this.experienceFileSizeLoader,
    this.certificationsFilePicker = pickTrainerProfileCertificationDocuments,
    this.certificationsFileSizeLoader,
    this.locationsRepository =
        const CountryStateCityBrazilianLocationsRepository(),
    super.key,
  });

  final TrainerProfileData profile;
  final TrainerProfileUpdateHandler updateProfile;
  final TrainerEditDocumentUploader uploadExperience;
  final TrainerEditDocumentUploader uploadCertification;
  final TrainerPasswordResetRequester requestPasswordReset;
  final Future<XFile?> Function() experienceFilePicker;
  final Future<int> Function(XFile file)? experienceFileSizeLoader;
  final TrainerProfileCertificationsFilePicker certificationsFilePicker;
  final TrainerProfileFileSizeLoader? certificationsFileSizeLoader;
  final BrazilianLocationsRepository locationsRepository;

  @override
  State<TrainerEditProfileScreen> createState() =>
      _TrainerEditProfileScreenState();
}

class _TrainerEditProfileScreenState extends State<TrainerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final List<TrainerExperienceDocument> _certifications;
  late final List<TrainerProfileServiceRegion> _regions;
  final List<TrainerDocument> _newCertifications = [];
  final List<TrainerProfileServiceRegion> _newRegions = [];
  final Set<String> _removedCertificationPaths = {};
  final Set<String> _removedRegionIds = {};
  TrainerDocument? _newExperience;
  bool _removeExperience = false;
  bool _isSaving = false;
  bool _isRequestingPassword = false;

  @override
  void initState() {
    super.initState();
    final parts = _splitName(widget.profile.name);
    _firstNameController = TextEditingController(text: parts.$1);
    _lastNameController = TextEditingController(text: parts.$2);
    _certifications = List.of(widget.profile.certifications);
    _regions = List.of(widget.profile.serviceRegionEntries);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  (String, String) _splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return (parts.firstOrNull ?? '', '');
    return (parts.first, parts.skip(1).join(' '));
  }

  Future<TrainerDocument?> _toDocument(XFile file) async {
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      _showError('Selecione um arquivo no formato PDF.');
      return null;
    }
    final size =
        await (widget.experienceFileSizeLoader?.call(file) ?? file.length());
    if (!TrainerDocumentLimits.acceptsSize(size)) {
      _showError('Selecione um PDF de até 10 MB.');
      return null;
    }
    return TrainerDocument(
      name: file.name,
      path: file.path,
      sizeInBytes: size,
      mimeType: file.mimeType,
      readBytes: file.readAsBytes,
    );
  }

  Future<void> _pickExperience() async {
    try {
      final file = await widget.experienceFilePicker();
      if (file == null || !mounted) return;
      final document = await _toDocument(file);
      if (document != null && mounted) {
        setState(() => _newExperience = document);
      }
    } on Object {
      if (mounted) {
        _showError('Não foi possível acessar o arquivo selecionado.');
      }
    }
  }

  Future<void> _addCertifications() {
    final remainingExisting = _certifications.where(
      (document) => !_removedCertificationPaths.contains(document.path),
    );
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddTrainerCertificationsDialog(
        existingCertificationCount:
            remainingExisting.length + _newCertifications.length,
        filePicker: widget.certificationsFilePicker,
        fileSizeLoader: widget.certificationsFileSizeLoader,
        onSave: (documents) async {
          if (mounted) setState(() => _newCertifications.addAll(documents));
        },
      ),
    );
  }

  Future<void> _addRegion() async {
    final type = await showDialog<TrainerServiceAreaType>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const ServiceAreaTypeDialog(),
    );
    if (!mounted || type == null) return;
    final area = await showDialog<TrainerServiceArea>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ServiceAreaSelectionDialog(
        type: type,
        locationsRepository: widget.locationsRepository,
      ),
    );
    if (!mounted || area == null) return;

    final additions = trainerProfileRegionsFromArea(area);
    final activeIds = {
      for (final region in _regions)
        if (!_removedRegionIds.contains(region.identifier)) region.identifier,
      for (final region in _newRegions) region.identifier,
    };
    if (additions.any((region) => activeIds.contains(region.identifier))) {
      _showError('Essa região de atendimento já foi adicionada.');
      return;
    }
    if (activeIds.length + additions.length > 30) {
      _showError('Você pode cadastrar no máximo 30 regiões.');
      return;
    }
    setState(() => _newRegions.addAll(additions));
  }

  Future<void> _requestPasswordReset() async {
    if (_isRequestingPassword) return;
    setState(() => _isRequestingPassword = true);
    try {
      final message = await widget.requestPasswordReset(widget.profile.email);
      if (mounted) _showSuccess(message);
    } on PasswordResetFailure catch (error) {
      if (mounted) _showError(error.message);
    } on Object {
      if (mounted) {
        _showError('Não foi possível solicitar a alteração de senha.');
      }
    } finally {
      if (mounted) setState(() => _isRequestingPassword = false);
    }
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final currentName = widget.profile.name.trim().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final newName = '$firstName $lastName'.trim();
    final nameChanged = newName != currentName;
    final experiencePath = widget.profile.experience?.path ?? '';
    final update = TrainerProfileUpdate(
      firstName: nameChanged ? firstName : null,
      lastName: nameChanged ? lastName : null,
      serviceRegionsToAdd: List.unmodifiable(_newRegions),
      serviceRegionsToRemove: _regions
          .where((region) => _removedRegionIds.contains(region.identifier))
          .toList(growable: false),
      experiencePathToRemove:
          _removeExperience &&
              _newExperience == null &&
              experiencePath.isNotEmpty
          ? experiencePath
          : null,
      certificationPathsToRemove: _removedCertificationPaths
          .where((path) => path.isNotEmpty)
          .toList(growable: false),
    );
    if (update.isEmpty &&
        _newExperience == null &&
        _newCertifications.isEmpty) {
      _showSuccess('Nenhuma alteração para salvar.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.updateProfile(update);
      if (_newExperience != null) {
        await widget.uploadExperience(_newExperience!);
      }
      for (final document in _newCertifications) {
        await widget.uploadCertification(document);
      }
      if (!mounted) return;
      _showSuccess('Perfil atualizado com sucesso.');
      Navigator.of(context).pop(true);
    } on RegistrationFailure catch (error) {
      if (!mounted) return;
      _showError(error.message);
      // A callable pode ter concluído antes de uma perda de conexão. Voltar
      // força uma nova leitura e impede o reenvio inseguro das diferenças.
      Navigator.of(context).pop(true);
    } on Object {
      if (!mounted) return;
      _showError('Não foi possível salvar todas as alterações.');
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) => AppSnackBar.show(
    context,
    backgroundColor: AppColors.error,
    icon: Icons.error_outline_rounded,
    message: message,
  );

  void _showSuccess(String message) => AppSnackBar.show(
    context,
    backgroundColor: AppColors.success,
    icon: Icons.check_circle_outline_rounded,
    message: message,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentExperience = _newExperience != null
        ? _newExperience!.name
        : (!_removeExperience ? widget.profile.experience?.fileName : null);
    final visibleCertifications = _certifications.where(
      (document) => !_removedCertificationPaths.contains(document.path),
    );
    final visibleRegions = _regions.where(
      (region) => !_removedRegionIds.contains(region.identifier),
    );

    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 48),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          key: const Key('close-trainer-edit-profile'),
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.of(context).pop(false),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.seaGreen,
                            size: 32,
                          ),
                        ),
                        Image.asset(
                          'assets/Logo_HorseLife.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Editar perfil',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Corrija suas informações como\npreferir.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 34),
                    _EditableNameField(
                      fieldKey: const Key('trainer-edit-first-name'),
                      label: 'Primeiro nome',
                      controller: _firstNameController,
                    ),
                    const SizedBox(height: 22),
                    _EditableNameField(
                      fieldKey: const Key('trainer-edit-last-name'),
                      label: 'Sobrenome',
                      controller: _lastNameController,
                    ),
                    const SizedBox(height: 22),
                    Text('E-mail', style: _sectionLabel(theme)),
                    TextFormField(
                      key: const Key('trainer-edit-email'),
                      initialValue: widget.profile.email,
                      readOnly: true,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.grey,
                      ),
                      decoration: const InputDecoration(
                        suffixIcon: Tooltip(
                          message: 'O e-mail não pode ser alterado por aqui.',
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.seaGreen,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      key: const Key('trainer-edit-password'),
                      onPressed: _isRequestingPassword
                          ? null
                          : _requestPasswordReset,
                      icon: _isRequestingPassword
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.key_rounded),
                      label: const Text('Alterar senha'),
                      style: _outlinedActionStyle(theme),
                    ),
                    const SizedBox(height: 34),
                    _EditSection(
                      title: 'Experiência',
                      addButtonKey: const Key('trainer-edit-add-experience'),
                      onAdd: currentExperience == null ? _pickExperience : null,
                      child: currentExperience == null
                          ? null
                          : _EditItemTile(
                              itemKey: const Key('trainer-edit-experience'),
                              icon: Icons.picture_as_pdf_outlined,
                              label: currentExperience,
                              onDelete: () => setState(() {
                                if (_newExperience != null) {
                                  _newExperience = null;
                                } else {
                                  _removeExperience = true;
                                }
                              }),
                            ),
                    ),
                    const SizedBox(height: 28),
                    _EditSection(
                      title: 'Certificados',
                      addButtonKey: const Key(
                        'trainer-edit-add-certifications',
                      ),
                      onAdd: _addCertifications,
                      children: [
                        for (final document in visibleCertifications)
                          _EditItemTile(
                            itemKey: ValueKey(
                              'trainer-edit-certification-${document.fileName}',
                            ),
                            icon: Icons.picture_as_pdf_outlined,
                            label: document.fileName,
                            onDelete: () => setState(
                              () =>
                                  _removedCertificationPaths.add(document.path),
                            ),
                          ),
                        for (
                          var index = 0;
                          index < _newCertifications.length;
                          index++
                        )
                          _EditItemTile(
                            itemKey: ValueKey(
                              'trainer-edit-new-certification-$index',
                            ),
                            icon: Icons.picture_as_pdf_outlined,
                            label: _newCertifications[index].name,
                            onDelete: () => setState(
                              () => _newCertifications.removeAt(index),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _EditSection(
                      title: 'Regiões de atendimento',
                      addButtonKey: const Key('trainer-edit-add-region'),
                      onAdd: _addRegion,
                      children: [
                        for (final region in visibleRegions)
                          _EditItemTile(
                            itemKey: ValueKey(
                              'trainer-edit-region-${region.identifier}',
                            ),
                            icon: Icons.location_on_rounded,
                            label: region.label,
                            onDelete: () => setState(
                              () => _removedRegionIds.add(region.identifier),
                            ),
                          ),
                        for (var index = 0; index < _newRegions.length; index++)
                          _EditItemTile(
                            itemKey: ValueKey('trainer-edit-new-region-$index'),
                            icon: Icons.location_on_rounded,
                            label: _newRegions[index].label,
                            onDelete: () =>
                                setState(() => _newRegions.removeAt(index)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text('Situação profissional', style: _sectionLabel(theme)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: const Key('trainer-edit-professional-status'),
                      initialValue: widget.profile.professionalStatus,
                      items: [
                        DropdownMenuItem(
                          value: widget.profile.professionalStatus,
                          child: Text(widget.profile.professionalStatus),
                        ),
                      ],
                      onChanged: null,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.alabasterGray.withValues(
                          alpha: .45,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A situação profissional é somente informativa.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                    const SizedBox(height: 42),
                    OutlinedButton(
                      key: const Key('save-trainer-profile-changes'),
                      onPressed: _isSaving ? null : _save,
                      style: _outlinedActionStyle(theme).copyWith(
                        minimumSize: const WidgetStatePropertyAll(
                          Size.fromHeight(64),
                        ),
                        shape: const WidgetStatePropertyAll(StadiumBorder()),
                      ),
                      child: _isSaving
                          ? const SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Salvar alterações'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle? _sectionLabel(ThemeData theme) =>
      theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);

  ButtonStyle _outlinedActionStyle(ThemeData theme) => OutlinedButton.styleFrom(
    foregroundColor: AppColors.seaGreen,
    side: const BorderSide(color: AppColors.seaGreen, width: 2),
    minimumSize: const Size.fromHeight(54),
    textStyle: theme.textTheme.labelLarge,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class _EditableNameField extends StatelessWidget {
  const _EditableNameField({
    required this.fieldKey,
    required this.label,
    required this.controller,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.seaGreen,
          ),
        ),
        TextFormField(
          key: fieldKey,
          controller: controller,
          textCapitalization: TextCapitalization.words,
          style: theme.textTheme.headlineSmall,
          decoration: const InputDecoration(
            suffixIcon: Icon(Icons.edit_rounded, color: AppColors.seaGreen),
          ),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Preencha este campo.'
              : null,
        ),
      ],
    );
  }
}

class _EditSection extends StatelessWidget {
  const _EditSection({
    required this.title,
    required this.onAdd,
    this.addButtonKey,
    this.child,
    this.children = const [],
  });

  final String title;
  final VoidCallback? onAdd;
  final Key? addButtonKey;
  final Widget? child;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final items = [?child, ...children];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (onAdd != null)
          TextButton(
            key: addButtonKey,
            onPressed: onAdd,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: const Text('+ Adicionar'),
          ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...items.expand((item) => [item, const SizedBox(height: 12)]),
        ],
      ],
    );
  }
}

class _EditItemTile extends StatelessWidget {
  const _EditItemTile({
    required this.itemKey,
    required this.icon,
    required this.label,
    required this.onDelete,
  });

  final Key itemKey;
  final IconData icon;
  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: itemKey,
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: AppColors.alabasterGray.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blueSpruce, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Remover',
            icon: const Icon(Icons.delete_rounded, color: AppColors.error),
          ),
        ],
      ),
    );
  }
}
