// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 21/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Exportação dos materiais e das mídias atuais para o treino
// agendado (loadExerciseExtras e tipos).
//
// Data: 20/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Exportação dos detalhes e da edição do exercício.
//
// Data: 20/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação das consultas usadas pela edição e pelos detalhes
// do treinamento.
//
// Data: 18/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportações usadas pela feature de planos.
//
// Data: 14/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação da galeria, do tempo total dos exercícios
// selecionados e da carga dos exercícios do treinador e da validação da
// seleção, usadas pelo cadastro de treinamentos.
//
// Data: 10/11/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Exportação do cadastro de exercícios e do envio, da confirmação
// e da remoção de mídias.
//
// Data: 16/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Renomeação da nomenclatura para trainer.
//
// Data: 15/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Interface pública da feature de exercícios.
// -----------------------------------------------------------------------------

export {
  countActiveExercisesByTrainer,
  findExerciseKinds,
  findForeignSpecificExerciseIds,
  findTrainerExercisesByCodes,
} from "./repositories/exerciseRepository";
export {registerExercise} from "./handlers/registerExercise";
export {
  createExerciseMediaUpload,
} from "./handlers/createExerciseMediaUpload";
export {confirmExerciseMedia} from "./handlers/confirmExerciseMedia";
export {removeExerciseMedia} from "./handlers/removeExerciseMedia";
export {listExerciseGallery} from "./handlers/listExerciseGallery";
export {sumExerciseDurations} from "./handlers/sumExerciseDurations";
export {getExercise} from "./handlers/getExercise";
export {updateExercise} from "./handlers/updateExercise";
export {loadTrainerExercises} from "./services/trainerExercises";
export {loadExerciseExtras} from "./services/exerciseExtras";
export {
  MAX_SELECTED_EXERCISES,
  parseBusca,
  parseExerciseIds,
  parseObjectId,
} from "./validations/validateExerciseSelection";
export type {
  ExerciseDocument,
  ExerciseExtras,
  ExerciseKindSource,
  ExerciseMaterial,
  ExerciseMediaView,
} from "./types";
