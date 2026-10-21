// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 20/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Aplicação dos limites de 10 certificações e 10 MB por PDF,
// preservando a leitura dos arquivos para o envio após a criação da conta.
//
// Data: 15/10/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação da quinta etapa do treinador para adicionar, listar e
// remover qualquer quantidade de certificações profissionais em PDF, com
// navegação para a etapa de regiões de atendimento.
// -----------------------------------------------------------------------------

import 'dart:math' as math;

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
import 'service_areas_screen.dart';

typedef TrainerCertificationsCallback =
    void Function(TrainerRegistrationDraft registration);
// Permite substituir o seletor nativo por uma implementação controlada em testes.
typedef TrainerCertificationsFilePicker = Future<List<XFile>> Function();

// Filtro multiplataforma que restringe o seletor a documentos PDF.
const _certificationTypeGroup = XTypeGroup(
  label: 'Documentos PDF',
  extensions: ['pdf'],
  mimeTypes: ['application/pdf'],
  uniformTypeIdentifiers: ['com.adobe.pdf'],
);

// Permite selecionar vários PDFs de uma vez.
Future<List<XFile>> pickTrainerCertificationDocuments() {
  return openFiles(acceptedTypeGroups: const [_certificationTypeGroup]);
}

// Quinta etapa do treinador; as certificações são opcionais e limitadas.
class TrainerCertificationsScreen extends StatefulWidget {
  const TrainerCertificationsScreen({
    required this.registration,
    this.filePicker = pickTrainerCertificationDocuments,
    this.registrationController,
    this.onContinue,
    this.onBack,
    super.key,
  });

  final TrainerRegistrationDraft registration;
  final TrainerCertificationsFilePicker filePicker;
  final RegistrationController? registrationController;
  final TrainerCertificationsCallback? onContinue;
  final VoidCallback? onBack;

  @override
  State<TrainerCertificationsScreen> createState() =>
      _TrainerCertificationsScreenState();
}

class _TrainerCertificationsScreenState
    extends State<TrainerCertificationsScreen> {
  // A lista mostra até três documentos antes de passar a usar rolagem interna.
  static const _documentHeight = 64.0;
  static const _documentSpacing = 12.0;
  static const _maximumVisibleDocuments = 3;

  // Coleção editável inicializada a partir dos documentos já presentes no draft.
  final ScrollController _documentsScrollController = ScrollController();
  late final List<TrainerDocument> _documents;
  // Bloqueia seleções concorrentes enquanto o diálogo nativo está aberto.
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _documents = List.of(widget.registration.trainerCertificationDocuments);
  }

  @override
  void dispose() {
    _documentsScrollController.dispose();
    super.dispose();
  }

  // Retorno injetável com fallback para a pilha de navegação.
  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
      return;
    }
    Navigator.maybePop(context);
  }

  // Filtra PDFs, lê seus metadados e acrescenta todos os resultados válidos.
  Future<void> _pickDocuments() async {
    if (_isPicking) return;
    final availableSlots =
        TrainerDocumentLimits.maximumCertifications - _documents.length;
    if (availableSlots <= 0) {
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Você pode adicionar no máximo 10 certificações.',
      );
      return;
    }
    setState(() => _isPicking = true);

    try {
      final files = await widget.filePicker();
      if (!mounted || files.isEmpty) return;

      // A extensão é revalidada porque plataformas podem ignorar o filtro nativo.
      final validFiles = files
          .where((file) => file.name.toLowerCase().endsWith('.pdf'))
          .take(availableSlots)
          .toList(growable: false);

      if (files.any((file) => !file.name.toLowerCase().endsWith('.pdf'))) {
        AppSnackBar.show(
          context,
          backgroundColor: AppColors.error,
          icon: Icons.error_outline_rounded,
          message: 'Somente arquivos no formato PDF foram adicionados.',
        );
      }
      if (files.length > availableSlots) {
        AppSnackBar.show(
          context,
          backgroundColor: AppColors.error,
          icon: Icons.error_outline_rounded,
          message: 'Somente 10 certificações podem ser adicionadas.',
        );
      }

      // Os metadados independentes são carregados em paralelo.
      final newDocuments = await Future.wait([
        for (final file in validFiles) _createCertificationDocument(file),
      ]);

      final acceptedDocuments = newDocuments
          .where(
            (document) =>
                TrainerDocumentLimits.acceptsSize(document.sizeInBytes),
          )
          .toList(growable: false);
      if (acceptedDocuments.length != newDocuments.length && mounted) {
        AppSnackBar.show(
          context,
          backgroundColor: AppColors.error,
          icon: Icons.error_outline_rounded,
          message: 'Somente PDFs de até 10 MB foram adicionados.',
        );
      }

      if (!mounted || acceptedDocuments.isEmpty) return;
      setState(() => _documents.addAll(acceptedDocuments));
    } on Object {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        backgroundColor: AppColors.error,
        icon: Icons.error_outline_rounded,
        message: 'Não foi possível acessar os arquivos selecionados.',
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // Converte o arquivo externo no valor persistido pelo estado de cadastro.
  Future<TrainerDocument> _createCertificationDocument(XFile file) async {
    return TrainerDocument(
      name: file.name,
      path: file.path,
      sizeInBytes: await file.length(),
      mimeType: file.mimeType,
      readBytes: file.readAsBytes,
    );
  }

  // Exclui apenas o item escolhido, preservando a ordem dos demais.
  void _removeDocument(int index) {
    setState(() => _documents.removeAt(index));
  }

  // Congela a coleção atual no draft e abre a seleção de áreas de atendimento.
  void _continue() {
    final updatedRegistration = widget.registration
        .withTrainerCertificationDocuments(_documents);
    final onContinue = widget.onContinue;
    if (onContinue != null) {
      onContinue(updatedRegistration);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ServiceAreasScreen(
          registration: updatedRegistration,
          registrationController: widget.registrationController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Layout da quinta etapa, com anexos opcionais e avanço sempre disponível.
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
                              currentStep: 5,
                            ),
                            const SizedBox(height: 52),
                            Text(
                              'Certificações\nprofissionais',
                              textAlign: TextAlign.center,
                              style: textTheme.displaySmall?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                height: 0.98,
                              ),
                            ),
                            const SizedBox(height: 36),
                            Text(
                              'Anexe um ou mais documentos\n'
                              'contendo suas certificações\n'
                              'profissionais.\n'
                              'Você pode preencher isso mais\n'
                              'tarde, se preferir.',
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: 22,
                                height: 1.18,
                              ),
                            ),
                            const SizedBox(height: 46),
                            _buildAddButton(context),
                            if (_documents.isNotEmpty) ...[
                              const SizedBox(height: 20),
                              _buildDocumentsList(context),
                            ],
                            const SizedBox(height: 50),
                            AuthNextButton(
                              buttonKey: const Key(
                                'continue-trainer-certifications',
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

  // Alterna entre o ícone de adição e o progresso da leitura dos arquivos.
  Widget _buildAddButton(BuildContext context) {
    const borderRadius = BorderRadius.all(Radius.circular(18));
    final textStyle = Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontSize: 20);

    return Semantics(
      button: true,
      label: 'Adicionar arquivos PDF',
      child: Material(
        color: const Color(0xFFE9E9E9),
        borderRadius: borderRadius,
        child: InkWell(
          key: const Key('pick-trainer-certification-files'),
          onTap: _isPicking ? null : _pickDocuments,
          borderRadius: borderRadius,
          child: SizedBox(
            height: _documentHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Expanded(child: Text('Adicionar arquivo', style: textStyle)),
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

  // Calcula a altura por item e ativa a barra ao ultrapassar o limite visual.
  Widget _buildDocumentsList(BuildContext context) {
    final visibleCount = math.min(_documents.length, _maximumVisibleDocuments);
    final listHeight =
        visibleCount * _documentHeight + (visibleCount - 1) * _documentSpacing;
    final isScrollable = _documents.length > _maximumVisibleDocuments;

    return SizedBox(
      key: const Key('trainer-certifications-list'),
      height: listHeight,
      child: Scrollbar(
        controller: _documentsScrollController,
        thumbVisibility: isScrollable,
        child: ListView.separated(
          controller: _documentsScrollController,
          primary: false,
          padding: EdgeInsets.only(right: isScrollable ? 14 : 0),
          itemCount: _documents.length,
          separatorBuilder: (_, _) => const SizedBox(height: _documentSpacing),
          itemBuilder: (context, index) {
            return _CertificationDocumentTile(
              key: ValueKey('trainer-certification-$index'),
              document: _documents[index],
              onRemove: () => _removeDocument(index),
            );
          },
        ),
      ),
    );
  }
}

// Apresenta o nome do PDF e uma ação individual de remoção.
class _CertificationDocumentTile extends StatelessWidget {
  const _CertificationDocumentTile({
    required this.document,
    required this.onRemove,
    super.key,
  });

  final TrainerDocument document;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _TrainerCertificationsScreenState._documentHeight,
      padding: const EdgeInsets.only(left: 22, right: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFE9E9E9),
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            color: AppColors.blueSpruce,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              document.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontSize: 20),
            ),
          ),
          IconButton(
            key: Key('remove-trainer-certification-${document.name}'),
            onPressed: onRemove,
            tooltip: 'Remover ${document.name}',
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
