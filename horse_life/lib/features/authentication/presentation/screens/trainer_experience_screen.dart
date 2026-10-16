// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da quarta etapa do treinador para anexar um único
// documento PDF de experiência profissional, com exibição e remoção do arquivo,
// atualização do estado exclusivo do treinador e navegação para certificações.
// -----------------------------------------------------------------------------

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_snack_bar.dart';
import '../../application/controllers/registration_controller.dart';
import '../../application/states/trainer_document.dart';
import '../../application/states/registration_draft.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_next_button.dart';
import '../widgets/registration_progress_indicator.dart';
import 'trainer_certifications_screen.dart';

typedef TrainerExperienceCallback =
    void Function(TrainerRegistrationDraft registration);
typedef TrainerExperienceFilePicker = Future<XFile?> Function();

const _documentTypeGroup = XTypeGroup(
  label: 'Documento PDF',
  extensions: ['pdf'],
  mimeTypes: ['application/pdf'],
  uniformTypeIdentifiers: ['com.adobe.pdf'],
);

// Abre o seletor nativo, que concede acesso somente ao documento escolhido.
Future<XFile?> pickTrainerExperienceDocument() {
  return openFile(acceptedTypeGroups: const [_documentTypeGroup]);
}

// Quarta etapa do treinador; o documento é opcional e limitado a uma unidade.
class TrainerExperienceScreen extends StatefulWidget {
  const TrainerExperienceScreen({
    required this.registration,
    this.filePicker = pickTrainerExperienceDocument,
    this.registrationController,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainerRegistrationDraft registration;
  final TrainerExperienceFilePicker filePicker;
  final RegistrationController? registrationController;
  final TrainerExperienceCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<TrainerExperienceScreen> createState() =>
      _TrainerExperienceScreenState();
}

class _TrainerExperienceScreenState extends State<TrainerExperienceScreen> {
  TrainerDocument? _selectedDocument;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _selectedDocument = widget.registration.trainerExperienceDocument;
  }

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  // Cada nova escolha substitui a anterior, garantindo o limite de um arquivo.
  Future<void> _pickDocument() async {
    if (_isPicking) return;
    setState(() => _isPicking = true);

    try {
      final file = await widget.filePicker();
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

      final document = TrainerDocument(
        name: file.name,
        path: file.path,
        sizeInBytes: await file.length(),
        mimeType: file.mimeType,
      );

      if (!mounted) return;
      setState(() => _selectedDocument = document);
    } on Object {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Não foi possível acessar o arquivo selecionado.',
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // Retorna o componente ao estado inicial sem documento selecionado.
  void _removeDocument() {
    setState(() => _selectedDocument = null);
  }

  // O anexo é opcional, conforme previsto no fluxo de cadastro.
  void _continue() {
    final selectedDocument = _selectedDocument;
    final updatedRegistration = widget.registration
        .withTrainerExperienceDocument(selectedDocument);

    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedRegistration);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => TrainerCertificationsScreen(
          registration: updatedRegistration,
          registrationController: widget.registrationController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selectedDocument = _selectedDocument;

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
                              currentStep: 4,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Experiências\nprofissionais',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                height: 0.98,
                              ),
                            ),
                            const SizedBox(height: 36),
                            Text(
                              'Anexe um documento contendo\n'
                              'suas experiências profissionais.\n'
                              'Você pode preencher isso mais\n'
                              'tarde, se preferir.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 46),
                            _buildDocumentField(context, selectedDocument),
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-trainer-experience',
                              ),
                              onPressed: _isPicking ? null : _continue,
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

  Widget _buildDocumentField(
    BuildContext context,
    TrainerDocument? selectedDocument,
  ) {
    final textStyle = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontSize: 20);
    const borderRadius = BorderRadius.all(Radius.circular(18));

    if (selectedDocument == null) {
      return Semantics(
        button: true,
        label: 'Adicionar um arquivo',
        child: Material(
          color: const Color(0xFFE9E9E9),
          borderRadius: borderRadius,
          child: InkWell(
            key: const Key('pick-trainer-experience-file'),
            onTap: _isPicking ? null : _pickDocument,
            borderRadius: borderRadius,
            child: SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Adicionar arquivo',
                        key: const Key('trainer-experience-file-name'),
                        style: textStyle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_isPicking)
                      const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    else
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

    return Container(
      key: const Key('selected-trainer-experience-file'),
      height: 64,
      padding: const EdgeInsets.only(left: 22, right: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFE9E9E9),
        borderRadius: borderRadius,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            key: Key('trainer-experience-pdf-icon'),
            color: AppColors.blueSpruce,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              selectedDocument.name,
              key: const Key('trainer-experience-file-name'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
          IconButton(
            key: const Key('remove-trainer-experience-file'),
            onPressed: _removeDocument,
            tooltip: 'Remover arquivo',
            icon: const Icon(
              Icons.delete_rounded,
              color: AppColors.error,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
