// RESPONSÁVEL: Gabriela Sichiroli Ferrari - RA 25013763
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
// Data: 14/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Alinhamento dos subtítulos de limitações físicas e lesões à prototipação.
//
// Data: 13/11/2026
// Autor: Enzo Olivato Pazian - RA: 25001654
// Alteração: Suporte à exibição condicional da barra de progresso nas 12 etapas
// posteriores à seleção preliminar de relacionamento e ajuste de texto.
//
// Data: 10/11/2026
// Autor: Gabriela Sichiroli Ferrari - RA 25013763
// Alteração: Etapas e textos do cadastro separados da tela principal.
// -----------------------------------------------------------------------------

/// Ordem do cadastro. Cada valor corresponde a uma etapa visual independente.
enum HorseRegistrationStep {
  relationship,
  name,
  microchip,
  birthDate,
  breed,
  coat,
  sex,
  images,
  modality,
  limitations,
  health,
  injuries,
  review;

  bool get isLast => this == HorseRegistrationStep.review;

  /// A seleção preliminar de relacionamento não exibe barra de progresso.
  bool get showsProgress => this != HorseRegistrationStep.relationship;

  /// Índice base 1 para o indicador de progresso de 12 etapas.
  int get progressStep => index;

  HorseRegistrationStep get next => HorseRegistrationStep.values[index + 1];

  HorseRegistrationStep get previous => HorseRegistrationStep.values[index - 1];

  String get title => switch (this) {
    relationship => 'Relação com o cavalo',
    name => 'Nome do animal',
    microchip => 'Microchip do cavalo',
    birthDate => 'Data de nascimento',
    breed => 'Raça',
    coat => 'Pelagem',
    sex => 'Sexo',
    images => 'Imagens',
    modality => 'Modalidade de treinos',
    limitations => 'Limitações físicas',
    health => 'Observações de saúde',
    injuries => 'Histórico de lesões',
    review => 'Revise os dados',
  };

  String get subtitle => switch (this) {
    relationship =>
      'Antes dos próximos passos, precisamos saber qual seu nível de relacionamento com o animal.',
    name => 'Informe qual é o nome do seu companheiro equino.',
    microchip => 'Informe o número do microchip do seu animal.',
    birthDate =>
      'Informe quando seu cavalo nasceu para calcularmos sua idade.',
    breed => 'Selecione qual é a raça do seu animal.',
    coat => 'Selecione qual é a coloração da pelagem do seu cavalo.',
    sex => 'Selecione qual é o sexo do seu animal.',
    images =>
      'Anexe uma ou mais imagens do seu companheiro de treinos. Você pode preencher isso mais tarde, se preferir.',
    modality => 'Selecione qual modalidade de esporte seu cavalo pratica.',
    limitations =>
      'Informe se seu animal possui uma ou mais lesões que possa impossibilitá-lo de realizar algum tipo de exercício. Você pode preencher isso mais tarde, se preferir.',
    health =>
      'Informe uma ou mais observações de saúde que possam ser úteis para a avaliação do profissional que prescreverá os treinos. Você pode preencher isso mais tarde, se preferir.',
    injuries =>
      'Adicione um histórico das lesões que seu animal já sofreu, indicando a data, a lesão e qual foi a prescrição dada com base nela. Você pode preencher isso mais tarde, se preferir.',
    review =>
      'Confira se todas as informações estão corretas antes de continuar.',
  };
}
