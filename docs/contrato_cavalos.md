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

Imagens ainda não são enviadas. O cavalo é criado com `imagens: []`. O envio
seguirá o mesmo fluxo de URL assinada dos anexos do treinador.

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
