// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 19/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Testes dos callables que consultam o servidor Java de microchip
// (validateMicrochip, registerHorse e updateHorse), com um servidor falso
// (porta 0) no lugar do Java.
// -----------------------------------------------------------------------------

import assert from "node:assert/strict";
import {createServer} from "node:net";
import type {AddressInfo} from "node:net";
import {test} from "node:test";
import type {TestContext} from "node:test";
import {HttpsError} from "firebase-functions/v2/https";
import type {CallableRequest} from "firebase-functions/v2/https";
import {registerHorse} from "./registerHorse";
import {updateHorse} from "./updateHorse";
import {validateMicrochip} from "./validateMicrochip";

const HOST = "127.0.0.1";
const VALID_REPLY =
  "{\"valido\":true,\"microchip\":\"076987654321017\"," +
  "\"codigoPais\":\"076\",\"nomePais\":\"Brasil\"}\n";
const INVALID_REPLY =
  "{\"valido\":false,\"microchip\":\"076987654321018\",\"erro\":{" +
  "\"codigo\":\"DIGITO_VERIFICADOR_INVALIDO\"," +
  "\"mensagem\":\"Os dígitos verificadores não conferem.\"}}\n";
const HORSE_ID = "66e1a0c2f1b2c3d4e5f60050";
const REGISTRATION = {
  codigo: "076987654321018",
  responsabilidades: ["PROPRIETARIO"],
  nome: "Trovão",
  dataNascimento: "2016-04-10",
  raca: "Brasileiro de Hipismo",
  pelagem: "Tordilho",
  sexo: "MACHO",
  modalidadeId: "66e1a0c2f1b2c3d4e5f6a001",
};

type FakeJava = {
  connections: number;
  requests: string[];
};

/** Troca variáveis de ambiente durante o teste e as restaura no fim.
 * @param {TestContext} t Contexto do teste.
 * @param {Object} values Valores a aplicar.
 */
function setEnv(t: TestContext, values: Record<string, string>): void {
  const previous = Object.keys(values).map((key) => [key, process.env[key]]);
  Object.assign(process.env, values);
  t.after(() => {
    for (const [key, value] of previous) {
      if (value === undefined) delete process.env[key as string];
      else process.env[key as string] = value;
    }
  });
}

/** Sobe, na porta 0, um servidor que faz o papel do Java: guarda a linha
 * recebida em cada conexão e responde sempre a mesma linha. Aponta
 * MICROCHIP_HOST e MICROCHIP_PORTA para ele e deixa MONGODB_URI vazio, para
 * que nenhum teste chegue a um banco de verdade.
 * @param {TestContext} t Contexto do teste.
 * @param {string} reply Linha de resposta, com o '\n'.
 * @return {Promise<FakeJava>} Conexões e linhas recebidas.
 */
async function startFakeJava(
  t: TestContext,
  reply: string
): Promise<FakeJava> {
  const fake: FakeJava = {connections: 0, requests: []};
  const server = createServer((socket) => {
    fake.connections++;
    let buffer = "";
    socket.setEncoding("utf8");
    socket.on("data", (chunk: string) => {
      buffer += chunk;
      const end = buffer.indexOf("\n");
      if (end < 0) return;
      fake.requests.push(buffer.slice(0, end));
      socket.end(reply);
    });
  });
  t.after(() => new Promise<void>((resolve) => server.close(() => resolve())));
  await new Promise<void>((resolve) => server.listen(0, HOST, resolve));
  const {port} = server.address() as AddressInfo;
  setEnv(t, {
    MICROCHIP_HOST: HOST,
    MICROCHIP_PORTA: String(port),
    MONGODB_URI: "",
  });
  return fake;
}

/** Monta a requisição que o SDK entrega ao handler de um callable.
 * @param {unknown} data Corpo enviado pelo app.
 * @param {string} role Claim 'role' do token de quem chama.
 * @return {CallableRequest} Requisição autenticada.
 */
function callableRequest(data: unknown, role = "guardian"): CallableRequest {
  return {
    data,
    auth: {uid: "uid-responsavel", token: {role}, rawToken: "token"},
    rawRequest: {},
    acceptsStreaming: false,
  } as unknown as CallableRequest;
}

/** Confere que a chamada rejeita com um HttpsError do código informado.
 * @param {Promise<unknown>} promise Chamada ao callable.
 * @param {string} code Código esperado.
 * @param {string} message Mensagem esperada.
 */
async function assertHttpsError(
  promise: Promise<unknown>,
  code: string,
  message: string
): Promise<void> {
  await assert.rejects(promise, (error: unknown) => {
    assert.ok(error instanceof HttpsError, `não é HttpsError: ${error}`);
    assert.equal(error.code, code);
    assert.equal(error.message, message);
    return true;
  });
}

test("validateMicrochip asks Java for the parsed code and answers valido",
  async (t) => {
    const fake = await startFakeJava(t, VALID_REPLY);

    const result = await validateMicrochip.run(
      callableRequest({codigo: " 076987654321017 "})
    );

    assert.deepEqual(result, {valido: true});
    assert.deepEqual(fake.requests, [
      "{\"comando\":\"VALIDAR_MICROCHIP\",\"microchip\":\"076987654321017\"}",
    ]);
  });

test("validateMicrochip passes the Java message as invalid-argument",
  async (t) => {
    await startFakeJava(t, INVALID_REPLY);

    await assertHttpsError(
      validateMicrochip.run(callableRequest({codigo: "076987654321018"})),
      "invalid-argument",
      "Os dígitos verificadores não conferem."
    );
  });

test("validateMicrochip refuses a malformed code without asking Java",
  async (t) => {
    const fake = await startFakeJava(t, VALID_REPLY);

    await assertHttpsError(
      validateMicrochip.run(callableRequest({codigo: "07698765432101"})),
      "invalid-argument",
      "O microchip deve ter exatamente 15 dígitos numéricos."
    );

    assert.equal(fake.connections, 0);
  });

test("validateMicrochip is only for guardians", async (t) => {
  const fake = await startFakeJava(t, VALID_REPLY);

  await assertHttpsError(
    validateMicrochip.run(
      callableRequest({codigo: "076987654321017"}, "trainer")
    ),
    "permission-denied",
    "Acesso não permitido para este perfil."
  );

  assert.equal(fake.connections, 0);
});

test("registerHorse refuses a microchip that Java rejects", async (t) => {
  const fake = await startFakeJava(t, INVALID_REPLY);

  await assertHttpsError(
    registerHorse.run(callableRequest(REGISTRATION)),
    "invalid-argument",
    "Os dígitos verificadores não conferem."
  );

  assert.deepEqual(fake.requests, [
    "{\"comando\":\"VALIDAR_MICROCHIP\",\"microchip\":\"076987654321018\"}",
  ]);
});

test("updateHorse asks Java when the microchip changes", async (t) => {
  const fake = await startFakeJava(t, INVALID_REPLY);

  await assertHttpsError(
    updateHorse.run(
      callableRequest({id: HORSE_ID, codigo: "076987654321018"})
    ),
    "invalid-argument",
    "Os dígitos verificadores não conferem."
  );

  assert.deepEqual(fake.requests, [
    "{\"comando\":\"VALIDAR_MICROCHIP\",\"microchip\":\"076987654321018\"}",
  ]);
});

test("updateHorse does not ask Java when the microchip is not sent",
  async (t) => {
    const fake = await startFakeJava(t, INVALID_REPLY);

    // Sem microchip, a edição segue para o service, que falha por não haver
    // MongoDB nos testes; aqui só importa que o Java não foi consultado.
    await updateHorse
      .run(callableRequest({id: HORSE_ID, nome: "Trovão II"}))
      .catch(() => undefined);

    assert.equal(fake.connections, 0);
  });
