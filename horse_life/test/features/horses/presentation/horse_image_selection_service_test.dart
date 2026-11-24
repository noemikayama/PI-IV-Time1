// RESPONSÁVEL: Noemi Kayama - 25004140
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 15/11/2026
// Autor: Noemi Kayama - RA 25004140
// Alteração: Criação e documentação dos cenários de permissão, seleção,
// normalização, limites e falhas das imagens escolhidas.
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horse_life/features/horses/presentation/services/horse_image_selection_service.dart';

void main() {
  test('solicita permissão antes de abrir a galeria', () async {
    final events = <String>[];
    final service = HorseImageSelectionService(
      requestPermission: () async {
        events.add('permissão');
        return HorseImageLibraryAccess.granted;
      },
      pickImages: () async {
        events.add('galeria');
        return [];
      },
    );

    final result = await service.select(currentCount: 0);

    expect(events, ['permissão', 'galeria']);
    expect(result.access, HorseImageLibraryAccess.granted);
  });

  test('não abre a galeria quando a permissão é negada', () async {
    var openedGallery = false;
    final service = HorseImageSelectionService(
      requestPermission: () async => HorseImageLibraryAccess.denied,
      pickImages: () async {
        openedGallery = true;
        return [];
      },
    );

    final result = await service.select(currentCount: 0);

    expect(openedGallery, isFalse);
    expect(result.access, HorseImageLibraryAccess.denied);
    expect(result.accepted, isEmpty);
  });

  test(
    'abre a galeria sem crash quando o plugin de permissão não responde',
    () async {
      var openedGallery = false;
      final service = HorseImageSelectionService(
        requestPermission: () async => throw MissingPluginException(
          'No implementation found for method requestPermissions',
        ),
        pickImages: () async {
          openedGallery = true;
          return [];
        },
      );

      final result = await service.select(currentCount: 0);

      expect(openedGallery, isTrue);
      expect(result.access, HorseImageLibraryAccess.granted);
    },
  );

  test(
    'converte formato retornado pela galeria para PNG aceito no upload',
    () async {
      final pngBytes = Uint8List.fromList(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      );
      final service = HorseImageSelectionService(
        requestPermission: () async => HorseImageLibraryAccess.granted,
        pickImages: () async => [
          XFile.fromData(
            pngBytes,
            path: 'foto.heic',
            name: 'foto.heic',
            mimeType: 'image/heic',
          ),
        ],
      );

      final result = await service.select(currentCount: 0);

      expect(result.rejected, 0);
      expect(result.accepted, hasLength(1));
      expect(result.accepted.single.name, 'foto.png');
    },
  );

  test('normaliza imagem acima do limite antes de rejeitar', () async {
    final pngBytes = Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
    );
    final service = HorseImageSelectionService(
      requestPermission: () async => HorseImageLibraryAccess.granted,
      pickImages: () async => [
        XFile.fromData(
          pngBytes,
          path: 'foto-grande.jpg',
          name: 'foto-grande.jpg',
          mimeType: 'image/jpeg',
          length: HorseImageSelectionService.maxImageBytes + 1,
        ),
      ],
    );

    final result = await service.select(currentCount: 0);

    expect(result.rejected, 0);
    expect(result.accepted.single.name, 'foto-grande.png');
  });
}
