%{
  title: "Glossário",
  summary:
    "Referência para o campo glossário em L10N.md e no arquivo de sobrescrita de cada idioma.",
  category: "referência",
  section: "translation",
  order: 2
}
---
Um glossário de repositório está dividido em dois arquivos. O Glossia o mescla com o glossário da conta para cada arquivo que traduz. Veja [Glossário](/docs/explanation/glossary) sobre como os dois se combinam.

| Arquivo | `glossary` Contém | Exemplo |
|---|---|---|
| `L10N.md` | Uma lista de **termos**, o mesmo para todos os idiomas. | `- source: commit` |
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
| `definition` | string | não | Orientação breve que o modelo lê para decidir se uma correspondência é realmente este conceito. |
| `case_sensitive` | boolean | não | Quando `true`o termo corresponde apenas no caso exato escrito. Por padrão `false`. Use para nomes e acrônimos como `API` ou `SDK`. |
| `id` | string | não | Identificador estável. Derivado de `source` quando omitido (`Version Control` torna-se `version-control`, `C++` torna-se `cplusplus`) Defina as traduções da chave por id, para renomear `source` sem perder a identidade do termo, ou para substituir um termo de um pai `L10N.md`. |

Os termos não transportam traduções. Um termo com um `targets` campo é rejeitado: as traduções pertencem aos arquivos de idioma.

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

Cada chave é de um termo `id` ou sua `source`, e cada valor é a tradução aprovada para aquele idioma.

- Uma chave que não corresponde a nenhum termo no `L10N.md` declara um termo para este idioma apenas.
- Um termo sem tradução em um idioma recorre ao glossário da conta para aquele idioma.
- Para manter um nome sem tradução, mapeie-o para si mesmo, por exemplo `Glossia: Glossia`.

## Arquivos aninhados

Cada arquivo é traduzido com o glossário da sua cadeia de diretórios:

- Um arquivo aninhado `L10N.md` adiciona termos aos que herda. Um termo com o mesmo `id`, ou o mesmo `source` quando nenhum `id` está definido, substitui o herdado para aquela subárvore.
- Um aninhado `L10N/<locale>.md` adiciona traduções às que herda, e sua tradução prevalece para um termo que ambos declaram.

## Validação

Se um glossário for inválido, o Glossia traduz os arquivos afetados apenas com o glossário da conta, então um erro de digitação nunca bloqueia traduções. Causas comuns:

- **Ausente `source`.** Todo termo precisa de um valor não vazio.
- **Duplicidade `id`.** Todo termo deve resolver em um identificador único, seja definido explicitamente ou derivado de `source`.
- **Traduções em L10N.md.** Um termo com `targets`. Mova as traduções para `L10N/<locale>.md`.
- **Tradução vazia.** Um termo mapeado para uma string vazia. Remova-o em vez disso.
- **Formas ou tipos incorretos.** `glossary` deve ser uma lista em `L10N.md` e um mapa em `L10N/<locale>.md`. Traduções, `id`, e `definition` devem ser strings; `case_sensitive` deve ser `true` ou `false`.

## O que o Glossia registra

O arquivo de bloqueio de cada arquivo traduzido registra as entradas do glossário que o moldaram:

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

- `applied` lista as entradas que correspondem ao arquivo. As entradas do repositório aparecem como `repo:<id>`, as entradas da conta como `account:<id>`.
- `shadowed` lista as entradas de conta que uma entrada de repositório substituiu para este arquivo.

Editar um termo ou uma tradução retraduz apenas os arquivos que o utilizam.

## Veja também

- [Definir um glossário](/docs/how-to/define-a-glossary): guia passo a passo.
- [Glossário](/docs/explanation/glossary): como os glossários do repositório e da conta se combinam.
- [referência L10N.md](/docs/reference/l10n-md)os outros campos frontmatter.