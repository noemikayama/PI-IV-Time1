// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
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
} from "./repositories/exerciseRepository";
export {registerExercise} from "./handlers/registerExercise";
export {
  createExerciseMediaUpload,
} from "./handlers/createExerciseMediaUpload";
export {confirmExerciseMedia} from "./handlers/confirmExerciseMedia";
export {removeExerciseMedia} from "./handlers/removeExerciseMedia";
