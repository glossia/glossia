%{
  title: "Glossário",
  summary:
    "Referência para o campo glossário em L10N.md e em cada arquivo de sobrescrição de idioma.",
  category: "referência",
  section: "translation",
  order: 2
}
---

Um glossário de repositório está dividido em dois arquivos. O Glossia o funde com o glossário da conta para cada arquivo que traduz. Veja [Glossary](/docs/explanation/glossary) para como os dois se combinam.

| Arquivo | `glossary` contém | Exemplo |
|---|---|---|
| `L10N.md` | Uma lista de **termos**, o mesmo para cada idioma. | `- source: commit` |
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
| `definition` | booleano | não | Orientação breve que o modelo lê para decidir se uma correspondência é realmente esse conceito. |
| `case_sensitive` | booleano | não | Quando `true`, o termo só coincide com o caso exato conforme escrito. Padrão: `false`. Use para nomes e acrônimos como `API` ou `SDK`. |
| `id` | string | não | Identificador estável. Derivado de `source` quando omitido (`Version Control` torna-se `version-control`, `C++` torna-se `cplusplus`). Defina para que traduções sejam indexadas por id, para renomear `source` sem perder a identidade do termo, ou para sobrescrever um termo de um `L10N.md` pai. |

Termos não carregam traduções. Um termo com um campo `targets` é rejeitado: traduções pertencem aos arquivos de idioma.

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

Cada chave é o `id` ou o `source` de um termo, e cada valor é a tradução aprovada para aquele idioma.

- Uma chave que não corresponde a nenhum termo em `L10N.md` declara um termo apenas para este idioma.
- Um termo sem tradução em um idioma recorre ao glossário da conta para esse idioma.
- Para manter um nome sem tradução, mapeie-o a si mesmo, por exemplo `Glossia: Glossia`.

## Arquivos aninhados

Cada arquivo é traduzido com o glossário da cadeia de diretórios:

- Um `L10N.md` aninhado adiciona termos aos que herda. Um termo com o mesmo `id`, ou o mesmo `source` quando nenhum `id` está definido, substitui o herdado para essa subárvore.
- Um `L10N/<locale>.md` aninhado adiciona traduções às que herda, e sua tradução ganha para um termo declarado por ambos.

## Validação

Se um glossário for inválido, o Glossia traduz os arquivos afetados apenas com o glossário da conta, para que um erro de digitação nunca bloqueie traduções. Causas comuns:

- **.`source`Falta** Cada termo precisa de um não vazio.
- **.`id`Duplicado** Cada termo deve resolver-se em um identificador único, seja definido explicitamente ou derivado de `source`.
- **Traduções em L10N.md.** Um termo com `targets`. Mova as traduções para `L10N/<locale>.md`.
- **Tradução vazia.** Um termo mapeado a uma string vazia. Deixe a entrada de fora em vez disso.
- **Formas ou tipos errados.** `glossary` deve ser uma lista em `L10N.md` e um mapa em `L10N/<locale>.md`. Traduções, `id`, e `definition` devem ser strings; `case_sensitive` deve ser `true` ou `false`.

## O que o Glossia registra

Cada arquivo traduzido registra as entradas do glossário que o moldaram:

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

- `applied` lista as entradas que coincidem com o arquivo. As entradas do repositório aparecem como `repo:<id>`, as da conta como `account:<id>`.
- `shadowed` lista as entradas da conta que uma entrada do repositório substituiu neste arquivo.

Editando um termo ou uma tradução apenas retraduz os arquivos que o utilizam.

## Veja também

- [Definir um glossário](/docs/how-to/define-a-glossary): guia passo a passo.
- [Glossário](/docs/explanation/glossary): como os glossários do repositório e da conta se combinam.
- [L10N.md referência](/docs/reference/l10n-md): os outros campos frontmatter.
