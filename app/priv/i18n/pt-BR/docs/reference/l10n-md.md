%{
  title: "L10N.md",
  summary: "Referência para configurações de tradução do repositório e contexto.",
  category: "referência",
  order: 1
}
---
`L10N.md` diz ao Glossia quais arquivos traduzir, onde ficarão os arquivos traduzidos, quais idiomas alvejar e qual contexto deve guiar o resultado. Um repositório pode ter um arquivo raiz e arquivos adicionais com escopo em subdiretórios.

## Estrutura

Cada arquivo tem duas partes:

1. [Idioma YAML Não é Linguagem de Marca](https://yaml.org/) frontmatter entre `---` marcadores.
2. Markdown abaixo do frontmatter com contexto de produto, público, voz ou domínio.

<!-- end list -->

```yaml
---
source_language: en
model: translation-default
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
validation:
  - ./scripts/validate-docs.sh
  - --strict
frontmatter: preserve
preserve:
  - placeholders
  - urls
---

Write for software developers. Keep product names and code samples unchanged.
```

As credenciais do provedor devem estar nas configurações da conta, nunca em`L10N.md`. O valor opcional `model` é um identificador de modelo de conta.

## Campos do frontmatter

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `source_language` | string | no | Idioma de origem para este escopo. O padrão é `en`. |
| `model` | string | no | Identificador de modelo de conta. O Glossia usa o padrão da conta se omitido e relata um erro se um identificador explícito não existir. |
| `sources` | mapa ou lista | para uma regra de nível superior | Padrões de arquivo de origem. Os valores do mapa podem definir modelos de saída. |
| `targets` | mapa ou lista | quando as fontes estiverem configuradas | Códigos do idioma de destino. Um mapa pode associar um código de idioma a um nome de idioma. |
| `output` | string | quando não houver mapeamento de fonte ou `target_path` fornece um destino | Modelo de arquivo de saída. |
| `target_path` | string | quando não houver mapeamento de fonte ou `output` fornece um destino | Modelo do diretório base para arquivos traduzidos. |
| `translate` | lista | no | Múltiplas regras de tradução, cada uma com suas próprias fontes e sobreposições opcionais. |
| `exclude` | lista | no | Padrões de arquivos para ignorar. |
| `preserve` | lista | no | Tipos de conteúdo que devem permanecer inalterados, como espaços reservados ou recursos uniformes localizadores. |
| `frontmatter` | string | no | `preserve` por padrão ou `translate`. |
| `prompt` | string | no | Orientações adicionais para este escopo ou regra. |
| `validation` | lista | para extensões de arquivo sem um adaptador embutido | Um comando de validação seguido de seus argumentos. O comando recebe o candidato em seu caminho de destino real e deve retornar um status não zero se o arquivo for inválido. |
| `check_cmd` | string | no | Um comando de verificação disponível para o fluxo de trabalho de tradução. |
| `check_cmds` | mapa | no | Comandos de verificação nomeados disponíveis para o fluxo de trabalho de tradução. |
| `retries` | inteiro | no | Número de tentativas de reexcecuição após uma verificação falha. O padrão é `2`. |
| `locale` | string | no | Local associado a um arquivo de contexto com especificidade de idioma. |

Campos desconhecidos do frontmatter são ignorados.

## Formatos de arquivo

O Glossia possui tratamento nativo para arquivos Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portáteis objeto e texto plano. Outras extensões falham no planejamento, a menos que a `L10N.md` declarada `validation` comando. Isso evita tratar silenciosamente um formato estruturado proprietário como texto sem restrições.

O comando de validação é executado após o candidato ter sido escrito temporariamente em seu caminho de destino real. Ele pode invocar o analisador nativo, compilador ou comando de construção do repositório. O Glossia restaura o destino anterior após cada tentativa de validação e apenas escreve o candidato aceito após isso.

## Mapeamentos de origem

A forma mais clara mapeia cada padrão de origem para um modelo de saída:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Uma lista de origem também é válida, mas precisa `output` ou `target_path` para definir o destino:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Idiomas de destino

Uma lista usa cada código de local como seu identificador de idioma

```yaml
targets:
  - es
  - ja
```

Um mapa pode adicionar um nome de idioma legível

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variáveis de saída

| Variável | Valor |
|---|---|
 | `{locale}` ou `{lang}` | Código do idioma de destino. |
 | `{relpath}` | Caminho da origem relativo ao padrão correspondente. |
 | `{basename}` | Nome do arquivo de origem sem a extensão. |
 | `{ext}` | Extensão do arquivo de origem sem o ponto inicial. |

## Regras múltiplas

Use `translate` quando grupos de conteúdo diferentes precisam de destinos ou verificações diferentes:

```yaml
---
source_language: en
targets:
  - es
translate:
  - sources:
      - "docs/**/*.md"
    output: "docs/i18n/{locale}/{relpath}"
  - source: "messages/*.json"
    output: "messages/{locale}/{basename}.{ext}"
---
```

Os valores da regra sobreescrevem valores herdados do arquivo surrounding.

## Contexto escopado

O Glossia lê `L10N.md` arquivos a partir da raiz do repositório até o arquivo de origem:

- Configurações do pai fornecem padrões.
- Um arquivo mais profundo sobescreve campos para o diretório dele.
- O contexto do Markdown é acumulado do pai para o filho.
- Orientações específicas do idioma e um manipulador específico do idioma podem residir em `L10N/<locale>.md`.

Isso permite que um repositório mantenha orientações de voz amplas na raiz, enquanto coloca orientações específicas de área do produto ou de idioma próximas ao conteúdo que afeta.