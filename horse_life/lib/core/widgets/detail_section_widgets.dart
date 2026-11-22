// RESPONSÁVEL: Enzo Olivato Pazian - 25001654
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Detalhamento da documentação e comentários explicativos para
// facilitar a leitura, padronização e manutenção dos widgets compartilhados.
//
// Data: 22/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Criação dos componentes compartilhados para telas de visualização
// de detalhes (linhas informativas, estado vazio de seção, erro de carga,
// indicadores de carrossel e blocos informativos com ícone).
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:horse_life/app/theme/app_colors.dart';

/// Linha informativa padronizada com rótulo em negrito e valor descritivo.
///
/// Utilizada primordialmente na seção "Dados do ..." (Planos, Treinamentos e
/// Exercícios) para formatar pares chave-valor (ex.: "Título: ...", "Duração
/// estimada: ...", "Privacidade: ...") mantendo a tipografia em 17sp e a cor
/// neutra escura do tema institucional.
class DetailInfoLine extends StatelessWidget {
  const DetailInfoLine(
    this.label,
    this.value, {
    this.fontSize = 17,
    this.bottomPadding = 6,
    super.key,
  });

  /// Rótulo exibido com peso tipográfico w700 (negrito), seguido de dois pontos.
  final String label;

  /// Valor descritivo exibido com peso normal e quebra automática de linha.
  final String value;

  /// Tamanho da fonte em pixels lógicos (padrão 17sp conforme protótipo Figma).
  final double fontSize;

  /// Espaçamento inferior entre linhas subsequentes de dados.
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: fontSize,
      color: AppColors.text,
      height: 1.35,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: baseStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value, style: baseStyle),
          ],
        ),
      ),
    );
  }
}

/// Bloco de estado vazio reutilizado dentro de seções recolhíveis das telas de
/// visualização quando não há registros cadastrados para a categoria.
///
/// Possui fundo cinza claro arredondado ([AppColors.whiteSmoke] com raio 20),
/// ícone temático à esquerda (ex.: [Icons.block_outlined]) e textos de título
/// e descrição convidativos, orientando o usuário sobre a ausência de itens
/// (ex.: "Nenhuma mídia adicionada", "Nenhum material cadastrado").
class DetailEmptyStateCard extends StatelessWidget {
  const DetailEmptyStateCard({
    required this.title,
    required this.message,
    this.icon = Icons.block_outlined,
    this.cardKey,
    super.key,
  });

  /// Título em destaque do estado vazio (ex.: "Nenhum").
  final String title;

  /// Mensagem explicativa ou orientadora exibida logo abaixo do título.
  final String message;

  /// Ícone indicativo renderizado no topo esquerdo do card.
  final IconData icon;

  /// Chave opcional de rastreamento para testes de widget.
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: cardKey,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28, color: AppColors.text),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.text,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado visual exibido caso ocorra falha ao carregar os dados de detalhe
/// na inicialização da tela ou após perda de conexão.
///
/// Oferece um botão "Tentar novamente" que aciona a rotina [onRetry] para
/// reexecutar o Future do repositório remoto.
class DetailLoadError extends StatelessWidget {
  const DetailLoadError({
    required this.message,
    required this.onRetry,
    super.key,
  });

  /// Mensagem amigável de erro informada pelo repositório ou adapter.
  final String message;

  /// Callback acionado quando o usuário solicita nova tentativa de carregamento.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila centralizada de indicadores animados para paginação de carrosséis
/// horizontais (como o carrossel de exercícios e o carrossel de mídias).
///
/// O indicador ativo ganha largura expandida (24px vs 10px) e opacidade total,
/// proporcionando feedback tátil e visual ao deslizar entre os slides.
class DetailCarouselDots extends StatelessWidget {
  const DetailCarouselDots({
    required this.count,
    required this.currentIndex,
    this.onDotTap,
    this.keyPrefix = 'carousel-dot',
    super.key,
  });

  /// Quantidade total de páginas no carrossel.
  final int count;

  /// Índice da página atualmente visível (0-based).
  final int currentIndex;

  /// Callback disparado quando o usuário clica diretamente sobre uma das bolinhas.
  final ValueChanged<int>? onDotTap;

  /// Prefixo identificador para busca nos testes de widget.
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isSelected = index == currentIndex;
        return InkWell(
          key: Key('$keyPrefix-$index'),
          onTap: onDotTap == null ? null : () => onDotTap!(index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isSelected ? 24 : 10,
              height: 10,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.grey
                    : AppColors.grey.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Bloco visual reutilizável com ícone à esquerda e conteúdo textual à direita.
///
/// Utilizado para renderizar itens de listas em caixas cinzas arredondadas,
/// tais como orientações de execução (ícone de chat) e materiais necessários
/// (ícone de ferramentas com quantidade em destaque).
class DetailIconTextTile extends StatelessWidget {
  const DetailIconTextTile({
    required this.icon,
    this.text,
    this.child,
    this.tileKey,
    super.key,
  }) : assert(
         text != null || child != null,
         'Informe text ou child para DetailIconTextTile.',
       );

  /// Ícone indicativo renderizado à esquerda do card.
  final IconData icon;

  /// Conteúdo textual simples renderizado caso [child] não seja fornecido.
  final String? text;

  /// Widget customizado renderizado no corpo do tile (útil para formatações ricas com TextSpan).
  final Widget? child;

  /// Chave identificadora opcional para testes automatizados.
  final Key? tileKey;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontSize: 17,
      color: AppColors.text,
      height: 1.32,
    );

    return Container(
      key: tileKey,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.whiteSmoke,
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.text, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: child ?? Text(text!, style: textStyle),
          ),
        ],
      ),
    );
  }
}
