// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 10/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação do modal compartilhado de certificações, com seleção
// múltipla de PDFs, validações, remoção local, rolagem e salvamento assíncrono.
// -----------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import 'package:horse_life/core/widgets/app_snack_bar.dart';
import 'package:horse_life/features/authentication/application/states/trainer_document.dart';

/// Abre o seletor nativo e devolve todos os arquivos escolhidos pelo treinador.
typedef TrainerProfileCertificationsFilePicker = Future<List<XFile>> Function();

/// Obtém o tamanho sem obrigar o widget a materializar o PDF em memória.
typedef TrainerProfileFileSizeLoader = Future<int> Function(XFile file);

/// Persiste, em ordem, a coleção validada quando o treinador toca em salvar.
typedef TrainerCertificationsSaver =
    Future<void> Function(List<TrainerDocument> documents);

const _certificationTypeGroup = XTypeGroup(
  label: 'Documentos PDF',
  extensions: ['pdf'],
  mimeTypes: ['application/pdf'],
  uniformTypeIdentifiers: ['com.adobe.pdf'],
);

/// Seletor padrão restrito a PDFs nas plataformas suportadas pelo file_selector.
Future<List<XFile>> pickTrainerProfileCertificationDocuments() {
  return openFiles(acceptedTypeGroups: const [_certificationTypeGroup]);
}

/// Modal reutilizável que mantém os arquivos localmente até a confirmação.
///
/// O backend só é acionado por [onSave]. Remover um item antes de salvar não
/// apaga nada remotamente; apenas altera a seleção pendente.
class AddTrainerCertificationsDialog extends StatefulWidget {
  const AddTrainerCertificationsDialog({
    required this.existingCertificationCount,
    required this.onSave,
    this.filePicker = pickTrainerProfileCertificationDocuments,
    this.fileSizeLoader,
    super.key,
  });

  /// Quantidade remota usada para calcular as vagas restantes até o limite 10.
  final int existingCertificationCount;

  /// Callback responsável pelo protocolo remoto de upload e confirmação.
  final TrainerCertificationsSaver onSave;

  /// Dependência injetável para permitir testes sem abrir o seletor do sistema.
  final TrainerProfileCertificationsFilePicker filePicker;

  /// Dependência opcional usada por testes e plataformas com metadados próprios.
  final TrainerProfileFileSizeLoader? fileSizeLoader;

  @override
  State<AddTrainerCertificationsDialog> createState() =>
      _AddTrainerCertificationsDialogState();
}

class _AddTrainerCertificationsDialogState
    extends State<AddTrainerCertificationsDialog> {
  static const _documentHeight = 68.0;
  static const _documentSpacing = 12.0;
  static const _maximumVisibleDocuments = 2;

  final _scrollController = ScrollController();
  final List<TrainerDocument> _documents = [];
  bool _isPicking = false;
  bool _isSaving = false;

  int get _availableSlots =>
      TrainerDocumentLimits.maximumCertifications -
      widget.existingCertificationCount -
      _documents.length;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDocuments() async {
    if (_isPicking || _isSaving) return;
    if (_availableSlots <= 0) {
      _showError('Você pode adicionar no máximo 10 certificações.');
      return;
    }

    setState(() => _isPicking = true);
    try {
      final files = await widget.filePicker();
      if (!mounted || files.isEmpty) return;

      final availableSlots = _availableSlots;
      final pdfFiles = files
          .where((file) => file.name.toLowerCase().endsWith('.pdf'))
          .take(availableSlots)
          .toList(growable: false);

      if (files.any((file) => !file.name.toLowerCase().endsWith('.pdf'))) {
        _showError('Somente arquivos no formato PDF foram adicionados.');
      } else if (files.length > availableSlots) {
        _showError('Você pode adicionar no máximo 10 certificações.');
      }

      final newDocuments = await Future.wait([
        for (final file in pdfFiles) _toDocument(file),
      ]);
      final accepted = newDocuments
          .where(
            (document) =>
                TrainerDocumentLimits.acceptsSize(document.sizeInBytes),
          )
          .toList(growable: false);

      if (accepted.length != newDocuments.length && mounted) {
        _showError('Somente PDFs de até 10 MB foram adicionados.');
      }
      if (!mounted || accepted.isEmpty) return;
      setState(() => _documents.addAll(accepted));
    } on Object {
      if (mounted) {
        _showError('Não foi possível acessar os arquivos selecionados.');
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  // Converte apenas metadados; os bytes continuam com leitura adiada para que
  // vários PDFs selecionados não sejam mantidos simultaneamente na memória.
  Future<TrainerDocument> _toDocument(XFile file) async {
    final size = await (widget.fileSizeLoader?.call(file) ?? file.length());
    return TrainerDocument(
      name: file.name,
      path: file.path,
      sizeInBytes: size,
      mimeType: file.mimeType,
      readBytes: file.readAsBytes,
    );
  }

  Future<void> _save() async {
    if (_documents.isEmpty || _isPicking || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(List.unmodifiable(_documents));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
    final theme = Theme.of(context);
    return Dialog(
      key: const Key('add-trainer-certifications-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 42),
                    child: Text(
                      'Adicionar\ncertificação',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      key: const Key('close-add-certifications-dialog'),
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      tooltip: 'Fechar',
                      icon: const Icon(Icons.close_rounded, size: 34),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _AddFileButton(
                isPicking: _isPicking,
                enabled: !_isSaving,
                onPressed: _pickDocuments,
              ),
              if (_documents.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildDocumentsList(),
              ],
              const SizedBox(height: 34),
              OutlinedButton(
                key: const Key('save-trainer-certifications'),
                onPressed: _documents.isEmpty || _isPicking || _isSaving
                    ? null
                    : _save,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.seaGreen,
                  disabledForegroundColor: AppColors.grey,
                  side: BorderSide(
                    color: _documents.isEmpty
                        ? AppColors.grey
                        : AppColors.seaGreen,
                    width: 2,
                  ),
                  minimumSize: const Size.fromHeight(60),
                  shape: const StadiumBorder(),
                  textStyle: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsList() {
    final visibleCount = math.min(_documents.length, _maximumVisibleDocuments);
    final height =
        visibleCount * _documentHeight + (visibleCount - 1) * _documentSpacing;
    final isScrollable = _documents.length > _maximumVisibleDocuments;

    return SizedBox(
      key: const Key('new-trainer-certifications-list'),
      height: height,
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: isScrollable,
        child: ListView.separated(
          controller: _scrollController,
          primary: false,
          padding: EdgeInsets.only(right: isScrollable ? 14 : 0),
          itemCount: _documents.length,
          separatorBuilder: (_, _) => const SizedBox(height: _documentSpacing),
          itemBuilder: (context, index) => _CertificationTile(
            key: ValueKey('new-trainer-certification-$index'),
            document: _documents[index],
            onRemove: _isSaving
                ? null
                : () => setState(() => _documents.removeAt(index)),
          ),
        ),
      ),
    );
  }
}

class _AddFileButton extends StatelessWidget {
  const _AddFileButton({
    required this.isPicking,
    required this.enabled,
    required this.onPressed,
  });

  final bool isPicking;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE9E9E9),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const Key('pick-profile-certification-files'),
        onTap: enabled && !isPicking ? onPressed : null,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: _AddTrainerCertificationsDialogState._documentHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Adicionar arquivo',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (isPicking)
                  const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else
                  const Icon(Icons.add_rounded, size: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CertificationTile extends StatelessWidget {
  const _CertificationTile({
    required this.document,
    required this.onRemove,
    super.key,
  });

  final TrainerDocument document;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _AddTrainerCertificationsDialogState._documentHeight,
      padding: const EdgeInsets.only(left: 18, right: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9E9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            color: AppColors.blueSpruce,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              document.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton(
            key: Key('remove-new-trainer-certification-${document.name}'),
            onPressed: onRemove,
            tooltip: 'Remover ${document.name}',
            icon: const Icon(
              Icons.delete_rounded,
              color: AppColors.error,
              size: 29,
            ),
          ),
        ],
      ),
    );
  }
}
