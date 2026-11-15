# Contrato das callables de cavalos

Callables na região `southamerica-east1`. Datas sempre em `AAAA-MM-DD`
(fuso de São Paulo) e `_id` sempre como string hexadecimal.

## registerHorse

Exige login de **responsável**. Só cadastra quem é proprietário: se
`responsabilidades` não contiver `PROPRIETARIO`, retorna `permission-denied`.

```json
{
  "codigo": "123123456789012",
  "responsabilidades": ["PROPRIETARIO", "ATLETA"],
  "nome": "Trovão",
  "dataNascimento": "2016-04-10",
  "raca": "Brasileiro de Hipismo",
  "pelagem": "Tordilho",
  "sexo": "MACHO",
  "modalidadeId": "66e1a0c2f1b2c3d4e5f6a001",
  "limitacoesFisicas": ["Sensibilidade no casco posterior esquerdo"],
  "observacoesSaude": ["Vacinas em dia"],
  "historicoLesoes": [
    {
      "data": "2025-03-12",
      "descricao": "Distensão leve",
      "prescricao": "Repouso de 3 semanas"
    }
  ]
}
```

| Campo | Regra |
| --- | --- |
| `codigo` | Microchip: exatamente 15 dígitos, único (`already-exists` se repetido). |
| `responsabilidades` | `["PROPRIETARIO"]` ou `["PROPRIETARIO", "ATLETA"]`. |
| `nome` | 2 a 80 caracteres. |
| `dataNascimento` | Data válida, não futura, até 50 anos atrás. |
| `raca`, `pelagem` | 1 a 60 caracteres (aceita `SRD` / `SPD`). |
| `sexo` | `MACHO` ou `FEMEA`. |
| `modalidadeId` | Opcional. `_id` vindo de `getModalities`. |
| `limitacoesFisicas`, `observacoesSaude` | Opcionais. Até 30 itens, sem item vazio. |
| `historicoLesoes` | Opcional. `data` e `descricao` obrigatórias; `prescricao` opcional. A data não pode ser futura nem anterior ao nascimento. |

Resposta: `{ "id": "...", "codigo": "123123456789012", "nome": "Trovão" }`.

O cavalo é criado com `imagens: []`. As imagens são enviadas depois, com o
`id` devolvido aqui (ver [Imagens](#imagens)).

## updateHorse

Exige login de **responsável** e só pode ser chamada pelo proprietário. Envie
`id` e apenas os campos que mudaram: um campo ausente não é alterado. As listas
(`limitacoesFisicas`, `observacoesSaude` e `historicoLesoes`) substituem a
lista inteira, e `"modalidadeId": null` remove a modalidade. `codigo` e
`responsabilidades` não podem ser editados.

```json
{ "id": "66e1a0c2f1b2c3d4e5f60050", "nome": "Trovão II", "modalidadeId": null }
```

Resposta: o cavalo atualizado, no mesmo formato de `getHorse`.

## updateHorseLinks e removeHorseLink

As callables de vínculos estão implementadas na branch `developer`.
`updateHorseLinks` vincula ou substitui atleta e treinador pelos campos
`emailAtleta` e `emailTreinador`; campo ausente mantém o vínculo atual.
`removeHorseLink` recebe `vinculo: "ATLETA"` ou `vinculo: "TREINADOR"` e
remove um tipo por chamada. Ambas devolvem o perfil atualizado no formato de
`getHorseProfile`.

A troca ou remoção de treinador é recusada quando ele é autor do plano ativo.
As functions sincronizam, na mesma transação, as listas resumidas em
`responsaveis.cavalos`, `treinadores.cavalos` e `treinadores.clientes`.

## getHorse

Exige login. Responde ao proprietário, ao atleta e aos treinadores do cavalo.
Para qualquer outra pessoa, retorna `not-found`.

```json
{ "id": "66e1a0c2f1b2c3d4e5f60050" }
```

A resposta traz os campos do documento, mais:

- `idade: { "anos": 10, "meses": 6 }`, calculada a cada consulta;
- `responsabilidades` de quem consulta (lista vazia para o treinador), útil
  para mostrar ou esconder a edição.

Relacionamentos vêm como `{ id, codigo, nome }`. `modalidade`, `atleta` e
`planoAtual` vêm como `null` quando não existem.

`imagens` vem como lista de `{ "caminho": "...", "url": "..." }`, na ordem de
envio. A `url` é assinada e vale 15 minutos; o `caminho` identifica a imagem
para removê-la. `updateHorse` responde no mesmo formato.

## Imagens

Exigem login de **responsável** e só podem ser chamadas pelo proprietário
(`permission-denied` para os demais). O fluxo é o mesmo dos PDFs do treinador:
o app envia os bytes direto ao Storage por uma URL assinada.

Para cada imagem, o app:

1. chama `createHorseImageUpload` com `id` e `contentType`;
2. recebe `caminho`, `uploadUrl` e os headers obrigatórios;
3. envia os bytes por `PUT` para `uploadUrl`, com esses headers, em até 10
   minutos;
4. chama `confirmHorseImage` com `id` e `caminho`.

Envie as imagens uma de cada vez: o backend escolhe o próximo índice livre a
partir das imagens já confirmadas.

| Regra | Valor |
| --- | --- |
| Formatos | `image/jpeg` ou `image/png` (o conteúdo é conferido). |
| Tamanho | Até 5 MB. |
| Quantidade | Até 10 por cavalo. |
| Caminho | `/fotos/cavalos/<id>/imagem_<n>.jpg` (ou `.png`). |

### createHorseImageUpload

```json
{ "id": "66e1a0c2f1b2c3d4e5f60050", "contentType": "image/jpeg" }
```

Resposta:

```json
{
  "caminho": "/fotos/cavalos/66e1a0c2f1b2c3d4e5f60050/imagem_1.jpg",
  "uploadUrl": "https://storage.googleapis.com/...",
  "headers": {
    "Content-Type": "image/jpeg",
    "x-goog-content-length-range": "0,5242880"
  }
}
```

Com 10 imagens confirmadas, retorna `invalid-argument`.

### confirmHorseImage

```json
{
  "id": "66e1a0c2f1b2c3d4e5f60050",
  "caminho": "/fotos/cavalos/66e1a0c2f1b2c3d4e5f60050/imagem_1.jpg"
}
```

Resposta: `{ "caminho": "...", "url": "..." }`. Retorna `not-found` se o
arquivo não foi enviado. Se o arquivo não for uma imagem válida, ele é apagado
e a resposta é `invalid-argument`.

### removeHorseImage

Mesmo corpo de `confirmHorseImage`. Apaga a imagem do cavalo e do Storage e
responde `{ "removido": true }`, ou `not-found` se ela não estiver no cavalo.
