// RESPONSÁVEL: Davi Alves Froza - 25016900
// -----------------------------------------------------------------------------
// HISTÓRICO DE ALTERAÇÕES
//
// Data: 17/11/2026
// Autor: Davi Alves Froza - 25016900
// Alteração: Cliente TCP do servidor Java de validação de microchip: uma
// linha JSON de ida e uma de volta por conexão.
// -----------------------------------------------------------------------------

import {createConnection} from "node:net";
import {logger} from "firebase-functions";
import {
  microchipHostParam,
  microchipPortParam,
} from "../../../shared/config/environment";
import {AppError} from "../../../shared/errors/AppError";

// Prazo da troca inteira (conectar, enviar e receber a linha). O servidor
// Java fecha conexões ociosas em 5 s; aqui o limite é menor e é total.
const DEFAULT_TIMEOUT_MS = 3000;

// Códigos de regra de negócio do Java: o microchip foi analisado e recusado.
// Os demais (ERRO_INTERNO, REQUISICAO_MALFORMADA, ...) são falhas de
// protocolo e não podem chegar ao usuário como "microchip inválido".
const VALIDATION_CODES: ReadonlySet<string> = new Set([
  "MICROCHIP_AUSENTE",
  "FORMATO_INVALIDO",
  "TAMANHO_INVALIDO",
  "SEQUENCIA_REPETIDA",
  "PAIS_INVALIDO",
  "DIGITO_VERIFICADOR_INVALIDO",
]);

const UNAVAILABLE_MESSAGE =
  "Não foi possível verificar o microchip agora. Tente novamente.";

type JavaReply = {
  valido?: unknown;
  erro?: {codigo?: unknown; mensagem?: unknown} | null;
};

/** Converte a linha recebida do Java em objeto.
 * @param {string} line Linha recebida, sem o '\n'.
 * @return {JavaReply|undefined} Resposta, ou undefined se não for JSON.
 */
function parseReply(line: string): JavaReply | undefined {
  try {
    const parsed: unknown = JSON.parse(line);
    return typeof parsed === "object" && parsed !== null ?
      parsed as JavaReply :
      undefined;
  } catch {
    return undefined;
  }
}

/** Pergunta ao servidor Java se o microchip é válido. Cada chamada abre uma
 * conexão, envia uma linha JSON e lê uma linha de resposta.
 * @param {string} host Endereço do servidor Java.
 * @param {number} port Porta do servidor Java.
 * @param {string} microchip Código do microchip (15 dígitos).
 * @param {number} timeoutMs Prazo da troca inteira, em milissegundos.
 * @return {Promise<void>} Resolve quando o Java responde "valido": true.
 */
export function askMicrochipServer(
  host: string,
  port: number,
  microchip: string,
  timeoutMs = DEFAULT_TIMEOUT_MS
): Promise<void> {
  return new Promise((resolve, reject) => {
    const socket = createConnection({host, port});
    let buffer = "";
    let settled = false;

    // Fecha a conexão e conclui a promise uma única vez: depois da
    // resposta, o 'end' e o 'close' do socket não mudam mais o resultado.
    const settle = (error?: AppError) => {
      if (settled) return;
      settled = true;
      clearTimeout(timer);
      socket.destroy();
      if (error) reject(error);
      else resolve();
    };
    const fail = (motivo: string) => {
      if (settled) return;
      logger.warn("Servidor de microchip indisponível", {motivo, microchip});
      settle(new AppError("unavailable", UNAVAILABLE_MESSAGE));
    };
    const timer = setTimeout(() => fail("prazo esgotado"), timeoutMs);

    socket.setEncoding("utf8");
    socket.on("data", (chunk: string) => {
      buffer += chunk;
      const end = buffer.indexOf("\n");
      if (end < 0) return;

      const reply = parseReply(buffer.slice(0, end));
      if (reply?.valido === true) return settle();
      const codigo = reply?.erro?.codigo;
      const mensagem = reply?.erro?.mensagem;
      if (
        typeof codigo === "string" &&
        VALIDATION_CODES.has(codigo) &&
        typeof mensagem === "string"
      ) {
        return settle(new AppError("invalid-argument", mensagem));
      }
      fail(reply ? `resposta com código ${codigo}` : "resposta não é JSON");
    });
    socket.on("error", (error) => fail(error.message));
    socket.on("end", () => fail("conexão encerrada sem resposta"));
    socket.on("close", () => fail("conexão encerrada sem resposta"));

    socket.write(
      JSON.stringify({comando: "VALIDAR_MICROCHIP", microchip}) + "\n"
    );
  });
}

/** Confere o microchip no servidor Java, quando ele está configurado. Com
 * MICROCHIP_HOST vazio (o padrão, como no deploy), o Java não é consultado
 * e vale só a validação de formato de validateHorse.
 * @param {string} microchip Código do microchip (15 dígitos).
 * @return {Promise<void>} Resolve quando o microchip é aceito.
 */
export async function assertValidMicrochip(microchip: string): Promise<void> {
  const host = microchipHostParam.value().trim();
  if (!host) return;
  await askMicrochipServer(host, microchipPortParam.value(), microchip);
}
