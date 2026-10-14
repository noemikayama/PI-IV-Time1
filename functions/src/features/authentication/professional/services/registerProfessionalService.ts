// RESPONSÁVEL: Miguel Afonso Castro de Almeida - 25016044
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 13/10/2026
// Autor: Miguel Afonso Castro de Almeida - 25016044
// Alteração: Cadastro do treinador no Firebase Auth e no MongoDB.
// ----------------------------------------------------------------------------- 

import {runInTransaction} from "../../../../shared/config/mongodb";
import {ROLES} from "../../../../shared/constants/roles";
import {createAuthAccount, deleteAuthAccount, reserveEmail} from "../../shared";
import {insertProfessional} from "../repositories/professionalRepository";
import type {
  ProfessionalRegistrationInput,
  ProfessionalRegistrationResult,
} from "../types";

export async function registerProfessionalService(
  input: ProfessionalRegistrationInput
): Promise<ProfessionalRegistrationResult> {
    // O UID do Firebase é o _id do treinador.
    const uid = await createAuthAccount(input, ROLES.professional);

    try {
        const now = new Date();

        const codigo = await runInTransaction(async (session) => {
        const generatedCode = await insertProfessional(
        {
            _id: uid,
            nome: input.nome,
            email: input.email,
            situacaoProfissional: "DISPONIVEL",
            modalidades: input.modalidades,
            experiencias: [],
            certificacoes: [],
            regioesAtendimento: input.regioesAtendimento,
            cavalos: [],
            clientes: [],
            criadoEm: now,
            atualizadoEm: now,
        },
        session
        );

        await reserveEmail(
        {
            _id: input.email,
            codigo: generatedCode,
            tipoConta: "TREINADOR",
            usuarioId: uid,
            criadoEm: now,
        },
        session
        );

        return generatedCode;
        });

        return {id: uid, codigo, email: input.email};
    } catch (error) {
        await deleteAuthAccount(uid);
        throw error;
    }
}
