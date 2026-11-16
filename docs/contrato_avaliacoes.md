# Contrato das callables de avaliações

Callables na região `southamerica-east1`. Datas sempre em `AAAA-MM-DD`
(fuso de São Paulo) e `_id` sempre como string hexadecimal. A conta de quem
chama precisa estar ativa (`permission-denied` caso contrário).

## createHorseEvaluation

Exige login de **treinador** vinculado ao cavalo (RF06001). Para um cavalo que
o treinador não acompanha, retorna `not-found`. A avaliação não pode ser
editada depois de criada: o app deve avisar o treinador antes de enviar
(RF06005).

```json
{
  "cavaloId": "66e1a0c2f1b2c3d4e5f60050",
  "data": "2026-09-05",
  "condicionamentoFisicoObservado": "Fôlego regular após 20 minutos de trabalho",
  "limitacoes": "Evitar terreno duro",
  "dificuldades": "Perde ritmo após a segunda linha de obstáculos",
  "modalidadeIds": ["66e1a0c2f1b2c3d4e5f6a001"],
  "observacoes": ["Boa disposição, reage bem a comandos de perna"]
}
```

| Campo | Regra |
| --- | --- |
| `cavaloId` | Obrigatório. Cavalo ativo acompanhado pelo treinador. |
| `data` | Obrigatória. Não pode ser futura nem anterior ao nascimento do cavalo. |
| `condicionamentoFisicoObservado` | Obrigatório. 1 a 2000 caracteres. |
| `limitacoes`, `dificuldades` | Opcionais. Até 2000 caracteres; vazio equivale a não informar. |
| `modalidadeIds` | Opcional. Até 20 `_id` vindos de `getModalities`; podem diferir da modalidade do cavalo. |
| `observacoes` | Opcional. Até 30 itens de até 500 caracteres, sem item vazio. |

Resposta: a avaliação criada, com `id`, `codigo`, `cavalo`, `treinador`,
`modalidades` (como `{ id, codigo, nome }`), os textos (`limitacoes` e
`dificuldades` vêm `null` quando não informados) e `criadoEm`.

A avaliação é gravada em `avaliacoes` e o resumo `{ _id, codigo, data,
treinador }` é inserido em `cavalos.avaliacoes`, em ordem decrescente de data,
na mesma transação.

## Histórico de avaliações

Não há callable própria: o histórico vem em `avaliacoes` do
[getHorseProfile](contrato_cavalos.md#gethorseprofile), junto com o restante
do perfil, e o botão "Nova avaliação" aparece quando
`permissoes.criarAvaliacao` é `true` (só para o treinador). Depois de criar uma
avaliação, chame `getHorseProfile` de novo para atualizar a aba.
