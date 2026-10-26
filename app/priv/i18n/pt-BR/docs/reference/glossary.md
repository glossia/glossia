%{
  title: "Glossário",
  summary:
    "Referência para o campo de glossário no L10N.md e no arquivo de sobrescrita de cada idioma.",
  category: "referência",
  section: "translation",
  order: 2
}
---

Um glossário de repositório é dividido em dois arquivos. A Glossia o une ao glossário da conta para cada arquivo que traduz. Veja [Glossário](/docs/explanation/glossary) para ver como os dois são combinados.

| Arquivo | `glossary` mantém | Exemplo |
|---|---|---|
| `L10N.md` | Uma lista de **termos**, a mesma para cada idioma. | `- source: commit` |
| `L10N/<locale>.md` | Um mapeamento de termo para sua **tradução** nesse idioma. | `commit: commit` |

## Termos em L10N.md

```yaml
---
glossary:
  - source: commit
    definition: The version-control action of recording changes.
  - source: API
    case_sensitive: true
  - id: vcs-branch
    source: branch
    definition: A line of development in version control.
---
```

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `source` | string | sim | O termo conforme aparece no texto de origem. |
| `definition` | string | não | Orientação curta que o modelo lê para decidir se uma correspondência é realmente esse conceito. |
| `case_sensitive` | booleano | não | Quando `true`, o termo apenas corresponde ao caso exato escrito. O padrão é `false`. Use-o para nomes e siglas como `API` ou `SDK`. |
| `id` | string | não | Identificador estável. Derivado de `source` quando omitido (`Version Control` torna-se `version-control`, `C++` torna-se `cplusplus`). Defina-o para traduções principais por id, para renomear `source` sem perder a identidade do termo, ou para substituir um termo de um pai `L10N.md`. |

Termos não carregam traduções. Um termo com um campo `targets` é rejeitado: as traduções pertencem aos arquivos de idioma.

## Traduções em L10N/<locale>.md

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  API: API
  vcs-branch: rama
  pull request: pull request
---
```

Cada chave é o `id` do termo ou seu `source`, e cada valor é a tradução aprovada para esse idioma.

- Uma chave que não corresponde a nenhum termo em `L10N.md` declara um termo apenas para esse idioma.
- Um termo sem tradução em um idioma recorre ao glossário da conta para esse idioma.
- Para manter um nome sem tradução, mapeie-o a ele próprio, por exemplo `Glossia: Glossia`.

## Arquivos aninhados

Todo arquivo é traduzido com o glossário de sua cadeia de diretórios:

- Um `L10N.md` aninhado adiciona termos aos que ele herda. Um termo com o mesmo `id`, ou o mesmo `source` quando nenhum `id` está definido, substitui o herdado para aquela subárvore.
- Um `L10N/<locale>.md` aninhado adiciona traduções às que ele herda, e sua tradução vence para um termo que ambos declaram.

## Validação

Se um glossário for inválido, a Glossia traduz os arquivos afetados apenas com o glossário da conta, para que um erro de digitação nunca bloqueie traduções. Causas comuns:

- **Falta `source`.** Cada termo precisa de um valor não vazio.
- **Duplicata `id`.** Todo termo deve resolver em um identificador único, seja definido explicitamente ou derivado de `source`.
- **Traduções em L10N.md.** Um termo com `targets`. Mova as traduções para `L10N/<locale>.md`.
- **Tradução vazia.** Um termo mapeado para uma string vazia. Não o inclua.
- **Formas ou tipos incorretos.** `glossary` deve ser uma lista em `L10N.md` e um mapa em `L10N/<locale>.md`. Traduções, `id`, e `definition` devem ser strings; `case_sensitive` deve ser `true` ou `false`.

## O que a Glossia registra

O lockfile de cada arquivo traduzido registra as entradas do glossário que o moldaram:

```json
{
  "server_context": {
    "glossary": {
      "applied": ["repo:commit", "account:repository"],
      "shadowed": ["account:commit"]
    }
  }
}
```

- O `applied` lista as entradas que correspondem ao arquivo. As entradas do repositório aparecem como `repo:<id>`, as da conta como `account:<id>`.
- O `shadowed` lista as entradas de conta que uma entrada de repositório substituiu para este arquivo.

Editar um termo ou uma tradução apenas retraduz os arquivos que o utilizam.

## Veja também

- [Definir um glossário](/docs/how-to/define-a-glossary): guia passo a passo.
- [Glossário](/docs/explanation/glossary): como os glossários de repositório e conta são combinados.
- [L10N.md referência](/docs/reference/l10n-md): os outros campos de frontmatter.
