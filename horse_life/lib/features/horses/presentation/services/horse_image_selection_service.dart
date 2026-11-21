// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Documentação dos segmentos de permissão, seleção, normalização e
// validação das imagens escolhidas para cadastro ou edição.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Seleção e limites de imagens separados da tela.
// -----------------------------------------------------------------------------

import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart' show ImagePicker;
import 'package:permission_handler/permission_handler.dart';

/// Resultado possível da solicitação de acesso à biblioteca do aparelho.
enum HorseImageLibraryAccess { granted, denied, permanentlyDenied }

typedef HorseImageLibraryPermissionRequest =
    Future<HorseImageLibraryAccess> Function();
typedef HorseGalleryPicker = Future<List<XFile>> Function();

/// Arquivos aceitos, quantidade rejeitada e situação da permissão solicitada.
class HorseImageSelectionResult {
  const HorseImageSelectionResult({
    required this.accepted,
    required this.rejected,
    this.access = HorseImageLibraryAccess.granted,
  });

  final List<XFile> accepted;
  final int rejected;
  final HorseImageLibraryAccess access;
}

/// Solicita acesso à fototeca e abre a galeria nativa do aparelho.
class HorseImageSelectionService {
  const HorseImageSelectionService({
    HorseImageLibraryPermissionRequest? requestPermission,
    HorseGalleryPicker? pickImages,
  }) : _requestPermission = requestPermission,
       _pickImages = pickImages;

  final HorseImageLibraryPermissionRequest? _requestPermission;
  final HorseGalleryPicker? _pickImages;

  static const maxImages = 10;
  static const maxImageBytes = 5 * 1024 * 1024;

  // --- Permissão, seleção e aplicação dos limites ---------------------------
  // O fluxo aceita até dez imagens, prioriza JPEG/PNG válidos e tenta
  // normalizar outros formatos antes de contabilizá-los como rejeitados.

  Future<HorseImageSelectionResult> select({required int currentCount}) async {
    HorseImageLibraryAccess access;
    try {
      access = await (_requestPermission ?? _requestLibraryPermission)();
    } on MissingPluginException {
      // Um runner iniciado antes da inclusão do permission_handler não possui
      // o canal nativo até ser recompilado. O seletor do sistema continua
      // seguro: ele concede acesso somente às imagens escolhidas pelo usuário.
      access = HorseImageLibraryAccess.granted;
    }
    if (access != HorseImageLibraryAccess.granted) {
      return HorseImageSelectionResult(
        accepted: const [],
        rejected: 0,
        access: access,
      );
    }

    final selected = await (_pickImages ?? _pickFromGallery)();
    final accepted = <XFile>[];
    var rejected = 0;
    for (final file in selected) {
      if (currentCount + accepted.length >= maxImages) {
        rejected++;
        continue;
      }
      final name = file.name.toLowerCase();
      final supported =
          name.endsWith('.png') ||
          name.endsWith('.jpg') ||
          name.endsWith('.jpeg');
      final length = await file.length();
      if (supported && length <= maxImageBytes) {
        accepted.add(file);
        continue;
      }

      final normalized = await _normalizeForUpload(file);
      if (normalized == null) {
        rejected++;
        continue;
      }
      accepted.add(normalized);
    }
    return HorseImageSelectionResult(accepted: accepted, rejected: rejected);
  }

  /// Converte HEIC/HEIF e outros formatos decodificáveis para PNG. Imagens
  /// acima de 5 MB são reduzidas progressivamente antes do envio.
  Future<XFile?> _normalizeForUpload(XFile file) async {
    try {
      final source = await file.readAsBytes();
      int? targetWidth;
      for (var attempt = 0; attempt < 8; attempt++) {
        final codec = await ui.instantiateImageCodec(
          source,
          targetWidth: targetWidth,
        );
        ui.FrameInfo? frame;
        ByteData? data;
        var width = 0;
        try {
          frame = await codec.getNextFrame();
          width = frame.image.width;
          data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
        } finally {
          frame?.image.dispose();
          codec.dispose();
        }
        if (data == null) return null;

        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        if (bytes.length <= maxImageBytes) {
          final stem = file.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
          final normalizedName = '${stem.isEmpty ? 'foto-cavalo' : stem}.png';
          return XFile.fromData(
            bytes,
            path: normalizedName,
            name: normalizedName,
            mimeType: 'image/png',
          );
        }

        final nextWidth = (width * 0.75).floor();
        if (nextWidth < 320 || nextWidth >= width) return null;
        targetWidth = nextWidth;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  // --- Integrações nativas e fallbacks --------------------------------------
  // O seletor alternativo mantém runners antigos funcionais; a permissão é
  // consultada somente nas plataformas móveis que expõem essa capacidade.

  Future<List<XFile>> _pickFromGallery() async {
    try {
      return await ImagePicker().pickMultiImage(requestFullMetadata: false);
    } on MissingPluginException {
      // Mantém compatibilidade com um runner antigo até a próxima compilação
      // nativa. file_selector já fazia parte do app e abre somente imagens.
      const imagesGroup = XTypeGroup(
        label: 'Imagens JPEG ou PNG',
        extensions: ['jpg', 'jpeg', 'png'],
      );
      return openFiles(acceptedTypeGroups: [imagesGroup]);
    }
  }

  Future<HorseImageLibraryAccess> _requestLibraryPermission() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      return HorseImageLibraryAccess.granted;
    }

    final photos = await Permission.photos.request();
    if (photos.isGranted || photos.isLimited) {
      return HorseImageLibraryAccess.granted;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final storage = await Permission.storage.request();
      if (storage.isGranted || storage.isLimited) {
        return HorseImageLibraryAccess.granted;
      }
      if (photos.isPermanentlyDenied || storage.isPermanentlyDenied) {
        return HorseImageLibraryAccess.permanentlyDenied;
      }
    } else if (photos.isPermanentlyDenied) {
      return HorseImageLibraryAccess.permanentlyDenied;
    }

    return HorseImageLibraryAccess.denied;
  }
}
