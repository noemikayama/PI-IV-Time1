// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 17/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Testes do cliente TCP do servidor Java de microchip, com um
// servidor falso (porta 0) no lugar do Java.
// -----------------------------------------------------------------------------

import assert from "node:assert/strict";
import {createServer} from "node:net";
import type {AddressInfo, Socket} from "node:net";
import {test} from "node:test";
import type {TestContext} from "node:test";
import {AppError} from "../../../shared/errors/AppError";
import {askMicrochipServer, assertValidMicrochip} from "./microchipServer";

const HOST = "127.0.0.1";
const EXPECTED_REQUEST =
  "{\"comando\":\"VALIDAR_MICROCHIP\",\"microchip\":\"076987654321017\"}";
const VALID_REPLY =
  "{\"valido\":true,\"microchip\":\"076987654321017\"," +
  "\"codigoPais\":\"076\",\"nomePais\":\"Brasil\"}\n";
const INVALID_REPLY =
  "{\"valido\":false,\"microchip\":\"076987654321018\",\"erro\":{" +
  "\"codigo\":\"DIGITO_VERIFICADOR_INVALIDO\"," +
  "\"mensagem\":\"Os dígitos verificadores não conferem.\"}}\n";
const PROTOCOL_ERROR_REPLY =
  "{\"valido\":false,\"erro\":{\"codigo\":\"ERRO_INTERNO\"," +
  "\"mensagem\":\"Erro interno no servidor.\"}}\n";

/** Sobe, na porta 0, um servidor TCP que faz o papel do Java e o fecha ao
 * fim do teste.
 * @param {TestContext} t Contexto do teste.
 * @param {Function} onConnection O que o servidor faz com cada conexão.
 * @return {Promise<number>} Porta escolhida pelo sistema operacional.
 */
async function startFakeJava(
  t: TestContext,
  onConnection: (socket: Socket) => void
): Promise<number> {
  const sockets = new Set<Socket>();
  const server = createServer((socket) => {
    sockets.add(socket);
    socket.on("close", () => sockets.delete(socket));
    onConnection(socket);
  });
  t.after(() => {
    sockets.forEach((socket) => socket.destroy());
    return new Promise<void>((resolve) => server.close(() => resolve()));
  });
  await new Promise<void>((resolve) => server.listen(0, HOST, resolve));
  return (server.address() as AddressInfo).port;
}

/** Lê a primeira linha enviada pelo cliente, sem o '\n'.
 * @param {Socket} socket Conexão aceita pelo servidor falso.
 * @return {Promise<string>} Linha recebida.
 */
function readLine(socket: Socket): Promise<string> {
  return new Promise((resolve) => {
    let buffer = "";
    socket.setEncoding("utf8");
    socket.on("data", (chunk: string) => {
      buffer += chunk;
      const end = buffer.indexOf("\n");
      if (end >= 0) resolve(buffer.slice(0, end));
    });
  });
}

/** Confere que a promise rejeita com um AppError do código informado.
 * @param {Promise<void>} promise Chamada ao servidor.
 * @param {string} code Código esperado.
 * @param {string} message Mensagem esperada, quando importa.
 */
async function assertAppError(
  promise: Promise<void>,
  code: string,
  message?: string
): Promise<void> {
  await assert.rejects(promise, (error: unknown) => {
    assert.ok(error instanceof AppError, `não é AppError: ${error}`);
    assert.equal(error.code, code);
    if (message !== undefined) assert.equal(error.message, message);
    return true;
  });
}

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

test("resolves when the server says valido", async (t) => {
  let received: string | undefined;
  const port = await startFakeJava(t, (socket) => {
    readLine(socket).then((line) => {
      received = line;
      socket.end(VALID_REPLY);
    });
  });

  await askMicrochipServer(HOST, port, "076987654321017");

  assert.equal(received, EXPECTED_REQUEST);
});

test("invalid-argument with the Java message", async (t) => {
  const port = await startFakeJava(t, (socket) => {
    readLine(socket).then(() => socket.end(INVALID_REPLY));
  });

  await assertAppError(
    askMicrochipServer(HOST, port, "076987654321018"),
    "invalid-argument",
    "Os dígitos verificadores não conferem."
  );
});

test("reads a reply split in two chunks", async (t) => {
  const half = Math.floor(VALID_REPLY.length / 2);
  const port = await startFakeJava(t, (socket) => {
    readLine(socket).then(() => {
      socket.write(VALID_REPLY.slice(0, half));
      setTimeout(() => socket.end(VALID_REPLY.slice(half)), 20);
    });
  });

  await askMicrochipServer(HOST, port, "076987654321017");
});

test("unavailable on a protocol error", async (t) => {
  const port = await startFakeJava(t, (socket) => {
    readLine(socket).then(() => socket.end(PROTOCOL_ERROR_REPLY));
  });

  await assertAppError(
    askMicrochipServer(HOST, port, "076987654321017"),
    "unavailable"
  );
});

test("unavailable when the server closes without a line", async (t) => {
  const port = await startFakeJava(t, (socket) => socket.end());
  const started = Date.now();

  await assertAppError(
    askMicrochipServer(HOST, port, "076987654321017", 10_000),
    "unavailable"
  );

  assert.ok(Date.now() - started < 1000, "esperou o prazo em vez do fim");
});

test("unavailable when the reply is not JSON", async (t) => {
  const port = await startFakeJava(t, (socket) => {
    readLine(socket).then(() => socket.end("oi\n"));
  });

  await assertAppError(
    askMicrochipServer(HOST, port, "076987654321017"),
    "unavailable"
  );
});

test("unavailable when nothing listens", async () => {
  const server = createServer();
  await new Promise<void>((resolve) => server.listen(0, HOST, resolve));
  const {port} = server.address() as AddressInfo;
  await new Promise<void>((resolve) => server.close(() => resolve()));

  await assertAppError(
    askMicrochipServer(HOST, port, "076987654321017"),
    "unavailable"
  );
});

test("unavailable on timeout", {timeout: 2000}, async (t) => {
  let markClientGone: () => void = () => undefined;
  const clientGone = new Promise<void>((resolve) => {
    markClientGone = resolve;
  });
  const port = await startFakeJava(t, (socket) => {
    socket.on("close", () => markClientGone());
    socket.resume();
  });
  const started = Date.now();

  await assertAppError(
    askMicrochipServer(HOST, port, "076987654321017", 200),
    "unavailable"
  );

  assert.ok(Date.now() - started < 1000, "passou do prazo");
  await clientGone;
});

test("unavailable when the reply trickles past the deadline", {
  timeout: 2000,
}, async (t) => {
  const port = await startFakeJava(t, (socket) => {
    readLine(socket).then(() => {
      const trickle = setInterval(() => socket.write(" "), 50);
      socket.on("close", () => clearInterval(trickle));
    });
  });
  const started = Date.now();

  await assertAppError(
    askMicrochipServer(HOST, port, "076987654321017", 300),
    "unavailable"
  );

  assert.ok(Date.now() - started < 1000, "o prazo não vale para a troca toda");
});

test("assertValidMicrochip skips Java when MICROCHIP_HOST is blank",
  async (t) => {
    const port = await startFakeJava(t, (socket) => {
      readLine(socket).then(() => socket.end(INVALID_REPLY));
    });
    setEnv(t, {MICROCHIP_HOST: "  ", MICROCHIP_PORTA: String(port)});

    await assertValidMicrochip("076987654321018");
  });

test("assertValidMicrochip asks MICROCHIP_HOST at MICROCHIP_PORTA",
  async (t) => {
    const port = await startFakeJava(t, (socket) => {
      readLine(socket).then(() => socket.end(INVALID_REPLY));
    });
    setEnv(t, {MICROCHIP_HOST: HOST, MICROCHIP_PORTA: String(port)});

    await assertAppError(
      assertValidMicrochip("076987654321018"),
      "invalid-argument",
      "Os dígitos verificadores não conferem."
    );
  });
