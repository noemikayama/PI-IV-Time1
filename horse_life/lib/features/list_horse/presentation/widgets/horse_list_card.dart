// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 18/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Reorganização da camada de dados e atualização dos imports; padronização
// de autoria e histórico para revisão do PR.
//
// Data: 12/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Corrige o carregamento de URLs assinadas do Storage no Flutter Web (CORS),
// preserva fotos em BoxFit.cover e diferencia ausência de imagem de falha de
// carregamento sem expor tokens nos logs.
//
// Data: 12/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Exibe foto do backend e usa assets/black-head-horse.png já existente como
// ícone neutro quando não houver foto; aplica AppColors.
//
// Data: 07/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Card reutilizável de cavalo com variação por perfil e foto opcional.
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';
import '../../data/models/horse_list_item.dart';

class HorseListCard extends StatelessWidget {
  final HorseListItem horse;
  final HorseListProfile profile;
  final VoidCallback? onTap;

  const HorseListCard({
    super.key,
    required this.horse,
    required this.profile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isProfessional = profile == HorseListProfile.professional;

    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(13),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 125,
                height: 125,
                child: _HorsePhoto(horse: horse),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        horse.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge
                      ),
                      const SizedBox(height: 5),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.pearlAqua,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        child: Text(
                          isProfessional ? 'Treinador' : horse.relation,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _DetailLine(
                        label: isProfessional
                            ? 'Proprietário: '
                            : 'Treinador: ',
                        value: isProfessional
                            ? horse.ownerName
                            : horse.trainerName,
                      ),
                      const SizedBox(height: 3),
                      _DetailLine(label: 'Modalidade: ', value: horse.modality),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextSpan(text: value),
        ],
      ),
      style: const TextStyle(
        fontSize: 12.5,
        height: 1.12,
        color: Colors.black87,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Foto da primeira imagem confirmada no Firebase Storage.
///
/// No Chrome, URLs assinadas do Cloud Storage podem ser bloqueadas por CORS
/// quando carregadas como bytes pelo mecanismo de renderização do Flutter.
/// A estratégia HTML mostra a imagem diretamente no navegador sem criar
/// URLs alternativas ou precisar de imagens fictícias.
class _HorsePhoto extends StatelessWidget {
  final HorseListItem horse;

  const _HorsePhoto({required this.horse});

  @override
  Widget build(BuildContext context) {
    final url = horse.imageUrl?.trim();
    if (url == null || url.isEmpty) {
      // A Function devolveu foto: null: o cavalo ainda não tem imagem salva.
      return const _HorsePhotoPlaceholder(message: 'Sem foto cadastrada');
    }

    final uri = Uri.tryParse(url);
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      return const _HorsePhotoPlaceholder(message: 'Endereço da foto inválido');
    }

    return Image.network(
      url, // Preserva exatamente a URL assinada enviada pelo Firebase.
      key: ValueKey<String>(url),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      semanticLabel: 'Foto de ${horse.name}',
      // URLs do Storage são de outra origem em relação ao Flutter Web.
      // Em outros sistemas operacionais, esta opção não altera a renderização.
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: AppColors.alabasterGray,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        // Não registrar a URL assinada ou o erro completo nos logs, pois
        // ambos podem incluir parâmetros de acesso temporário ao Storage.
        debugPrint(
          'HorseLife/list_horse: falha ao carregar foto do cavalo '
          '(id: ${horse.id}, erro: ${error.runtimeType}).',
        );
        return const _HorsePhotoPlaceholder(message: 'Foto indisponível');
      },
    );
  }
}

/// A ilustração de fallback é o asset institucional, não uma foto simulada.
class _HorsePhotoPlaceholder extends StatelessWidget {
  final String message;

  const _HorsePhotoPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      child: ColoredBox(
        color: AppColors.alabasterGray,
        child: Center(
          child: Image.asset(
            'assets/black-head-horse.png',
            height: 42,
            width: 42,
            color: Colors.black87,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.pets_rounded, size: 36),
          ),
        ),
      ),
    );
  }
}
