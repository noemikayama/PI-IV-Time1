// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos fluxos de documentos, regiões, edição, cavalos
// e estados assíncronos do perfil profissional.
//
// Data: 10/11/2026 (perfil do cavalo)
// Autor: Noemi Kayama - RA 25004140
// Alteração: Abertura do perfil ao tocar no card sob tutoria.
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Adoção dos modais compartilhados para certificações e regiões e
// abertura dos documentos pelo PdfViewer; integração da tela de edição.
//
// Data: 09/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Inclusão das listagens de certificações e regiões de atendimento,
// com estados vazios e abertura individual dos documentos disponíveis.
//
// Data: 06/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da tela de perfil com carregamento remoto, identidade,
// experiência profissional, cavalos, estados de erro e encerramento de sessão.
// -----------------------------------------------------------------------------

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/core/widgets/gradient_button.dart';
import 'package:horse_life/core/widgets/service_area_dialogs.dart';
import 'package:horse_life/features/authentication/application/states/trainer_document.dart';
import 'package:horse_life/features/authentication/application/states/trainer_service_area.dart';
import 'package:horse_life/features/authentication/data/repositories/brazilian_locations_repository.dart';
import 'package:horse_life/features/authentication/data/repositories/registration_repository.dart';
import 'package:horse_life/features/authentication/presentation/screens/trainer_experience_screen.dart';
import 'package:horse_life/features/profile/data/models/trainer_profile_data.dart';
import 'package:horse_life/features/profile/presentation/screens/trainer_edit_profile_screen.dart';
import 'package:horse_life/features/profile/presentation/screens/trainer_experience_pdf_screen.dart';
import 'package:horse_life/core/widgets/add_trainer_certifications_dialog.dart';
import 'package:horse_life/features/profile/presentation/widgets/profile_horse_card.dart';
import 'package:horse_life/features/profile/presentation/widgets/profile_identity_header.dart';
import 'package:horse_life/features/profile/presentation/widgets/red_sign_out_button.dart';
import 'package:horse_life/features/profile/presentation/widgets/trainer_certifications_sheet.dart';
import 'package:horse_life/features/profile/presentation/widgets/trainer_service_regions_sheet.dart';

/// Carrega o retrato completo do treinador autenticado.
typedef TrainerProfileLoader = Future<TrainerProfileData> Function();

/// Seleciona o documento único de experiência profissional.
typedef TrainerProfileExperienceFilePicker = Future<XFile?> Function();

/// Lê tamanho de arquivo sem acoplar a tela ao sistema de arquivos real.
typedef TrainerExperienceFileSizeLoader = Future<int> Function(XFile file);

/// Envia um documento já validado pelo fluxo de perfil.
typedef TrainerExperienceUploader =
    Future<void> Function(TrainerDocument document);

/// Persiste uma nova abrangência de atendimento de forma incremental.
typedef TrainerServiceAreaAdder =
    Future<void> Function(TrainerServiceArea area);

/// Orquestra leitura e ações editáveis do perfil do treinador.
///
/// A tela contém somente estado de apresentação. Firebase, seleção de arquivos
/// e catálogo de localidades entram por callbacks para manter o fluxo testável.
class TrainerProfileScreen extends StatefulWidget {
  const TrainerProfileScreen({
    required this.loadTrainerProfile,
    required this.onLogout,
    this.onEditTrainerProfile,
    this.onViewExperience,
    this.onViewCertifications,
    this.onViewServiceRegions,
    this.onShowAllHorses,
    this.onSelectHorse,
    this.experienceDocumentBuilder,
    this.experienceFilePicker,
    this.experienceFileSizeLoader,
    this.uploadTrainerExperience,
    this.certificationsFilePicker,
    this.certificationsFileSizeLoader,
    this.uploadTrainerCertification,
    this.locationsRepository =
        const CountryStateCityBrazilianLocationsRepository(),
    this.addTrainerServiceArea,
    this.updateTrainerProfile,
    this.requestPasswordReset,
    super.key,
  });

  /// Fonte do perfil; a tela a executa novamente após cada alteração remota.
  final TrainerProfileLoader loadTrainerProfile;

  /// Finaliza a sessão atual usando a composição fornecida pela Home.
  final Future<void> Function() onLogout;

  /// Sobrescreve a futura edição geral quando fornecido pela composição.
  final VoidCallback? onEditTrainerProfile;

  /// Permite substituir a navegação padrão da experiência.
  final VoidCallback? onViewExperience;

  /// Permite substituir a abertura padrão das certificações.
  final VoidCallback? onViewCertifications;

  /// Permite substituir a abertura padrão das regiões.
  final VoidCallback? onViewServiceRegions;

  /// Ação da listagem completa de cavalos.
  final VoidCallback? onShowAllHorses;
  final ValueChanged<String>? onSelectHorse;

  /// Construtor alternativo usado para isolar o plugin PDF nos testes.
  final ExperienceDocumentBuilder? experienceDocumentBuilder;

  /// Seletor injetável do PDF único de experiência.
  final TrainerProfileExperienceFilePicker? experienceFilePicker;

  /// Leitor injetável de tamanho do PDF de experiência.
  final TrainerExperienceFileSizeLoader? experienceFileSizeLoader;

  /// Protocolo de upload da experiência já validada localmente.
  final TrainerExperienceUploader? uploadTrainerExperience;

  /// Seletor injetável de múltiplas certificações.
  final TrainerProfileCertificationsFilePicker? certificationsFilePicker;

  /// Leitor injetável dos tamanhos das certificações.
  final TrainerProfileFileSizeLoader? certificationsFileSizeLoader;

  /// Protocolo de upload executado sequencialmente para cada certificação.
  final TrainerExperienceUploader? uploadTrainerCertification;

  /// Catálogo compartilhado de estados e municípios brasileiros.
  final BrazilianLocationsRepository locationsRepository;

  /// Adiciona a região escolhida; ausente apenas em cenários isolados de teste.
  final TrainerServiceAreaAdder? addTrainerServiceArea;

  /// Salva as diferenças reunidas pela tela completa de edição.
  final TrainerProfileUpdateHandler? updateTrainerProfile;

  /// Solicita ao backend o e-mail de alteração de senha.
  final TrainerPasswordResetRequester? requestPasswordReset;

  @override
  State<TrainerProfileScreen> createState() => _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends State<TrainerProfileScreen> {
  late Future<TrainerProfileData> _profileFuture;
  bool _isAddingExperience = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.loadTrainerProfile();
  }

  @override
  void didUpdateWidget(covariant TrainerProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadTrainerProfile != widget.loadTrainerProfile) {
      _profileFuture = widget.loadTrainerProfile();
    }
  }

  void _retry() => setState(() {
    _profileFuture = widget.loadTrainerProfile();
  });

  VoidCallback _actionOrMessage(VoidCallback? action, String label) {
    return action ??
        () {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('$label estará disponível em breve.')),
            );
        };
  }

  // Experiência é um documento único. Se ausente, o mesmo gesto abre a
  // orientação de inclusão; se presente, navega ao leitor compartilhado.
  void _openExperience(TrainerProfileData profile) {
    final customAction = widget.onViewExperience;
    if (customAction != null) {
      customAction();
      return;
    }

    final document = profile.experience;
    if (document == null) {
      _showEmptyExperienceDialog();
      return;
    }
    _openDocument(document);
  }

  Future<void> _showEmptyExperienceDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nenhum arquivo anexado',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nenhum arquivo de experiência foi anexado. '
                'Adicione um para que os usuários possam vê-lo.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.text,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 28),
              GradientButton(
                key: const Key('add-empty-trainer-experience-button'),
                label: '+ Adicionar',
                onPressed: _isAddingExperience
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                        _pickAndUploadExperience();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadExperience() async {
    if (_isAddingExperience) return;

    try {
      final picker =
          widget.experienceFilePicker ?? pickTrainerExperienceDocument;
      final file = await picker();
      if (file == null || !mounted) return;

      if (!file.name.toLowerCase().endsWith('.pdf')) {
        AppSnackBar.show(
          context,
          backgroundColor: AppColors.error,
          icon: Icons.error_outline_rounded,
          message: 'Selecione um arquivo no formato PDF.',
        );
        return;
      }

      final sizeInBytes =
          await (widget.experienceFileSizeLoader?.call(file) ?? file.length());
      if (!TrainerDocumentLimits.acceptsSize(sizeInBytes)) {
        if (!mounted) return;
        AppSnackBar.show(
          context,
          backgroundColor: AppColors.error,
          icon: Icons.error_outline_rounded,
          message: 'Selecione um PDF de até 10 MB.',
        );
        return;
      }

      final uploader = widget.uploadTrainerExperience;
      if (uploader == null) {
        throw const RegistrationFailure(
          'Não foi possível iniciar o envio do documento.',
        );
      }

      setState(() => _isAddingExperience = true);
      await uploader(
        TrainerDocument(
          name: file.name,
          path: file.path,
          sizeInBytes: sizeInBytes,
          mimeType: file.mimeType,
          readBytes: file.readAsBytes,
        ),
      );
      if (!mounted) return;
      setState(() {
        _profileFuture = widget.loadTrainerProfile();
      });
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline_rounded,
        message: 'Experiência profissional adicionada.',
      );
    } on RegistrationFailure catch (error) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: error.message,
      );
    } on Object {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Não foi possível acessar ou enviar o arquivo selecionado.',
      );
    } finally {
      if (mounted) setState(() => _isAddingExperience = false);
    }
  }

  void _openDocument(TrainerExperienceDocument document) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TrainerExperiencePdfScreen(
          document: document,
          documentBuilder: widget.experienceDocumentBuilder,
        ),
      ),
    );
  }

  void _openCertifications(TrainerProfileData profile) {
    final customAction = widget.onViewCertifications;
    if (customAction != null) {
      customAction();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => TrainerCertificationsSheet(
        certifications: profile.certifications,
        onAdd: () {
          Navigator.of(sheetContext).pop();
          _openAddCertifications(profile);
        },
        onOpen: (document) {
          Navigator.of(sheetContext).pop();
          _openDocument(document);
        },
      ),
    );
  }

  Future<void> _openAddCertifications(TrainerProfileData profile) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddTrainerCertificationsDialog(
        existingCertificationCount: profile.certifications.length,
        filePicker:
            widget.certificationsFilePicker ??
            pickTrainerProfileCertificationDocuments,
        fileSizeLoader: widget.certificationsFileSizeLoader,
        onSave: _uploadCertifications,
      ),
    );
  }

  Future<void> _uploadCertifications(List<TrainerDocument> documents) async {
    final uploader = widget.uploadTrainerCertification;
    if (uploader == null) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Não foi possível iniciar o envio das certificações.',
      );
      return;
    }

    try {
      for (final document in documents) {
        await uploader(document);
      }
      if (!mounted) return;
      setState(() {
        _profileFuture = widget.loadTrainerProfile();
      });
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline_rounded,
        message: documents.length == 1
            ? 'Certificação adicionada.'
            : 'Certificações adicionadas.',
      );
    } on RegistrationFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _profileFuture = widget.loadTrainerProfile();
      });
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: error.message,
      );
    } on Object {
      if (!mounted) return;
      setState(() {
        _profileFuture = widget.loadTrainerProfile();
      });
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Não foi possível enviar todas as certificações.',
      );
    }
  }

  void _openServiceRegions(TrainerProfileData profile) {
    final customAction = widget.onViewServiceRegions;
    if (customAction != null) {
      customAction();
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrainerServiceRegionsSheet(
        regions: profile.serviceRegions,
        onAdd: () {
          Navigator.of(context).pop();
          _selectAndAddServiceArea();
        },
      ),
    );
  }

  Future<void> _selectAndAddServiceArea() async {
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

    final addArea = widget.addTrainerServiceArea;
    if (addArea == null) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Não foi possível adicionar a região.',
      );
      return;
    }

    try {
      await addArea(area);
      if (!mounted) return;
      setState(() {
        _profileFuture = widget.loadTrainerProfile();
      });
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.success,
        icon: Icons.check_circle_outline_rounded,
        message: 'Região de atendimento adicionada.',
      );
    } on RegistrationFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _profileFuture = widget.loadTrainerProfile();
      });
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: error.message,
      );
    } on Object {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Não foi possível adicionar a região.',
      );
    }
  }

  Future<void> _openEditProfile(TrainerProfileData profile) async {
    final customAction = widget.onEditTrainerProfile;
    if (customAction != null) {
      customAction();
      return;
    }
    final updater = widget.updateTrainerProfile;
    final experienceUploader = widget.uploadTrainerExperience;
    final certificationUploader = widget.uploadTrainerCertification;
    final passwordRequester = widget.requestPasswordReset;
    if (updater == null ||
        experienceUploader == null ||
        certificationUploader == null ||
        passwordRequester == null) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Não foi possível iniciar a edição do perfil.',
      );
      return;
    }

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => TrainerEditProfileScreen(
          profile: profile,
          updateProfile: updater,
          uploadExperience: experienceUploader,
          uploadCertification: certificationUploader,
          requestPasswordReset: passwordRequester,
          experienceFilePicker:
              widget.experienceFilePicker ?? pickTrainerExperienceDocument,
          experienceFileSizeLoader: widget.experienceFileSizeLoader,
          certificationsFilePicker:
              widget.certificationsFilePicker ??
              pickTrainerProfileCertificationDocuments,
          certificationsFileSizeLoader: widget.certificationsFileSizeLoader,
          locationsRepository: widget.locationsRepository,
        ),
      ),
    );
    if (changed == true && mounted) _retry();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TrainerProfileData>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _TrainerProfileError(onRetry: _retry);
        }
        return _TrainerProfileBody(
          profile: snapshot.data!,
          onLogout: widget.onLogout,
          onEditProfile: () => _openEditProfile(snapshot.data!),
          onViewExperience: () => _openExperience(snapshot.data!),
          onViewCertifications: () => _openCertifications(snapshot.data!),
          onViewServiceRegions: () => _openServiceRegions(snapshot.data!),
          onShowAllHorses: _actionOrMessage(
            widget.onShowAllHorses,
            'A lista de cavalos',
          ),
          onSelectHorse: widget.onSelectHorse,
        );
      },
    );
  }
}

class _TrainerProfileBody extends StatelessWidget {
  const _TrainerProfileBody({
    required this.profile,
    required this.onLogout,
    required this.onEditProfile,
    required this.onViewExperience,
    required this.onViewCertifications,
    required this.onViewServiceRegions,
    required this.onShowAllHorses,
    this.onSelectHorse,
  });

  final TrainerProfileData profile;
  final Future<void> Function() onLogout;
  final VoidCallback onEditProfile;
  final VoidCallback onViewExperience;
  final VoidCallback onViewCertifications;
  final VoidCallback onViewServiceRegions;
  final VoidCallback onShowAllHorses;
  final ValueChanged<String>? onSelectHorse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Perfil',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 28),
          ProfileIdentityHeader(
            name: profile.name,
            email: profile.email,
            status: profile.professionalStatus,
          ),
          const SizedBox(height: 28),
          _ProfileAction(
            icon: Icons.work_history_outlined,
            label: 'Ver experiência profissional',
            onTap: onViewExperience,
          ),
          _ProfileAction(
            icon: Icons.workspace_premium_outlined,
            label: 'Ver certificações',
            onTap: onViewCertifications,
          ),
          _ProfileAction(
            icon: Icons.location_on_outlined,
            label: 'Ver regiões de atendimento',
            onTap: onViewServiceRegions,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const Key('edit-trainer-profile-button'),
            onPressed: onEditProfile,
            icon: const Icon(Icons.edit_rounded),
            label: const Text('Editar perfil'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.seaGreen,
              side: const BorderSide(color: AppColors.seaGreen, width: 2),
              minimumSize: const Size.fromHeight(52),
              textStyle: theme.textTheme.labelLarge,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Cavalos sob tutoria',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onShowAllHorses,
                child: const Text('Mostrar tudo'),
              ),
            ],
          ),
          Text(
            'Total: ${profile.horses.length}',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 18),
          if (profile.horses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'Nenhum cavalo sob tutoria.',
                textAlign: TextAlign.center,
              ),
            )
          else
            SizedBox(
              height: 202,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: profile.horses.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final horse = profile.horses[index];
                  return ProfileHorseCard(
                    name: horse.name,
                    relationship: 'Treinador',
                    imageUrl: horse.imageUrl,
                    onTap: horse.id.isEmpty || onSelectHorse == null
                        ? null
                        : () => onSelectHorse!(horse.id),
                  );
                },
              ),
            ),
          const SizedBox(height: 36),
          RedSignOutButton(onLogout: onLogout),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: 54,
      leading: Icon(icon, color: AppColors.seaGreen, size: 34),
      title: Text(label, style: Theme.of(context).textTheme.titleLarge),
      onTap: onTap,
    );
  }
}

class _TrainerProfileError extends StatelessWidget {
  const _TrainerProfileError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.grey),
          const SizedBox(height: 12),
          const Text('Não foi possível carregar o perfil.'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
