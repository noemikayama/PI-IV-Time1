// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Seleção e limites de imagens separados da tela.
// -----------------------------------------------------------------------------

import 'package:file_selector/file_selector.dart';

class HorseImageSelectionResult {
  const HorseImageSelectionResult({
    required this.accepted,
    required this.rejected,
  });

  final List<XFile> accepted;
  final int rejected;
}

/// As imagens são escolhidas no aparelho e enviadas somente no registro.
class HorseImageSelectionService {
  const HorseImageSelectionService();

  static const maxImages = 10;
  static const maxImageBytes = 5 * 1024 * 1024;

  Future<HorseImageSelectionResult> select({required int currentCount}) async {
    const imagesGroup = XTypeGroup(
      label: 'Imagens JPEG ou PNG',
      extensions: ['jpg', 'jpeg', 'png'],
    );
    final selected = await openFiles(acceptedTypeGroups: [imagesGroup]);
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
      if (!supported || await file.length() > maxImageBytes) {
        rejected++;
        continue;
      }
      accepted.add(file);
    }
    return HorseImageSelectionResult(accepted: accepted, rejected: rejected);
  }
}
