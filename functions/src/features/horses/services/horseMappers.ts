// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 22/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Conversão do documento do cavalo para o formato do app.
// -----------------------------------------------------------------------------

import type {
  HorseDocument,
  HorseResponsibility,
  HorseView,
} from "../types";
import {calculateHorseAge} from "./horseAge";

const toRefView = (ref: {_id: unknown; codigo: number; nome: string}) => ({
  id: String(ref._id),
  codigo: ref.codigo,
  nome: ref.nome,
});

/** Responsabilidades do usuário sobre o cavalo.
 * @param {HorseDocument} horse Documento do cavalo.
 * @param {string} uid UID do usuário.
 * @return {HorseResponsibility[]} PROPRIETARIO e/ou ATLETA.
 */
export function responsibilitiesOf(
  horse: HorseDocument,
  uid: string
): HorseResponsibility[] {
  const result: HorseResponsibility[] = [];
  if (horse.proprietario._id === uid) result.push("PROPRIETARIO");
  if (horse.atleta?._id === uid) result.push("ATLETA");
  return result;
}

/** Converte o documento para o app: ObjectId e Date viram string e a idade
 * é calculada no momento da consulta.
 * @param {HorseDocument} horse Documento do cavalo.
 * @param {string} uid UID de quem consulta.
 * @return {HorseView} Cavalo no formato do app.
 */
export function toHorseView(horse: HorseDocument, uid: string): HorseView {
  return {
    id: horse._id.toHexString(),
    codigo: horse.codigo,
    nome: horse.nome,
    dataNascimento: horse.dataNascimento,
    idade: calculateHorseAge(horse.dataNascimento),
    raca: horse.raca,
    pelagem: horse.pelagem,
    sexo: horse.sexo,
    // Por enquanto, os caminhos; com o envio de imagens, URLs assinadas.
    imagens: horse.imagens,
    modalidade: horse.modalidade ? toRefView(horse.modalidade) : null,
    limitacoesFisicas: horse.limitacoesFisicas,
    observacoesSaude: horse.observacoesSaude,
    historicoLesoes: horse.historicoLesoes,
    situacaoCadastral: horse.situacaoCadastral,
    proprietario: toRefView(horse.proprietario),
    atleta: horse.atleta ? toRefView(horse.atleta) : null,
    treinadores: horse.treinadores.map(toRefView),
    planoAtual: horse.planoAtual ? {
      id: String(horse.planoAtual._id),
      codigo: horse.planoAtual.codigo,
      titulo: horse.planoAtual.titulo,
    } : null,
    avaliacoes: horse.avaliacoes.map((avaliacao) => ({
      id: String(avaliacao._id),
      codigo: avaliacao.codigo,
      data: avaliacao.data,
      treinador: toRefView(avaliacao.treinador),
    })),
    responsabilidades: responsibilitiesOf(horse, uid),
    criadoEm: horse.criadoEm.toISOString(),
    atualizadoEm: horse.atualizadoEm.toISOString(),
  };
}
