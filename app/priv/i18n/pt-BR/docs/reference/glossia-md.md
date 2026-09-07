%{
  title: "GLOSSIA.md",
  summary: "Referência para configurações de tradução do repositório e contexto.",
  category: "Referência",
  order: 1
}
---
`GLOSSIA.md` explica para o Glossia quais arquivos traduzir, aonde os arquivos traduzidos pertencem, quais idiomas almejar, e qual contexto deve guiar o resultado. Um repositório pode ter um arquivo raíz e arquivos adicionais com escopo em subdiretórios.

## Estrutura

Cada arquivo tem duas partes:

1. [Linguagem de Letra Não é Marking](https://yaml.org/) frontmatter entre `---` markers.
2. Markdown abaixo do frontmatter com contexto de produto, público-alvo, voz ou domínio.

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

Credenciais do provedor pertencem nas configurações de conta, nunca em `GLOSSIA.md`. O valor opcional `model` é uma handle de modelo da conta.

## Campos de frontmatter

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `source_language` | string | não | Local do idioma base para este escopo. Por padrão é `en`. |
| `model` | string | não | Handle de modelo da conta. O Glossia usa o padrão da conta se omitido e relata um erro se a handle explícita não existir. |
| `sources` | mapa ou lista | para uma regra de nível superior | Padrões de arquivos da fonte. Os valores do mapa podem definir templates de saída. |
| `targets` | mapa ou lista | quando as fontes são configuradas | Códigos de local do idioma de destino. Um mapa pode associar um código de locale a um nome de idioma. |
| `output` | string | quando não mapeamento de origem ou `target_path` fornece um destino | Template de arquivo de saída. |
| `target_path` | string | quando não mapeamento de origem ou `output` fornece um destino | Template de diretório base para arquivos traduzidos. |
| `translate` | lista | não | Múltiplas regras de tradução, cada uma com suas próprias fontes e superposições opcionais. |
| `exclude` | lista | não | Padrões de arquivos para pular. |
| `preserve` | lista | não | Tipos de conteúdo que devem permanecer inalterados, como place-holders ou uniform resource locators. |
| `frontmatter` | string | não | `preserve` por padrão, ou `translate`. |
| `prompt` | string | não | Orientações adicionais para este escopo ou regra. |
| `validation` | lista | para extensões de arquivo sem adaptador embutido | Um comando de validação seguido por seus argumentos. O comando recebe a candidata em seu caminho real de destino e deve retornar um status não zero quando o arquivo for inválido. |
| `check_cmd` | string | não | Um comando de verificação disponível ao fluxo de tradução. |
| `check_cmds` | mapa | não | Comandos de verificação nomeados disponíveis ao fluxo de tradução. |
| `retries` | inteiro | não | Número de tentativas de retorno após verificação falhada. Padrão `2`. |
| `locale` | string | não | Locale vinculado a um arquivo de contexto específico de locale. |

Campos de frontmatter desconhecidos são ignorados.

## Formatos de arquivo

O Glossia possui tratamento embutido para Markdown, Notação de Objeto JavaScript (JSON), Linguagem Ain't Markup (YAML), objeto portátil e arquivos de texto simples. Outras extensões de arquivo falham no planejamento a menos que o `GLOSSIA.md` declare `validation` comando. Isso evita silenciosamente tratar um formato estruturado proprietário como texto sem restrições.

O comando de validação roda após o candidato ter sido escrito temporariamente a seu caminho real de destino. Ele pode invocar o parser nativo do repositório, compilador ou comando de build. O Glossia restaura o destino anterior após cada tentativa de validação e escreve a candidata aceita apenas posteriormente.

## Mapeamentos de origem

A forma mais clara mapeia cada padrão de origem a um template de saída:

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

Uma lista usa cada código de idioma como identificador de idioma:

```yaml
targets:
  - es
  - ja
```

Um mapa pode adicionar um nome de idioma legível:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variáveis de saída

| Variável | Valor |
|---|---|
| `{locale}` ou `{lang}` | Código do idioma de destino. |
| `{relpath}` | Caminho fonte relativo em relação ao padrão combinado. |
| `{basename}` | Nome do arquivo fonte sem sua extensão. |
| `{ext}` | Extensão do arquivo fonte sem o ponto inicial. |

## Regras múltiplas

Use `translate` quando diferentes grupos de conteúdo precisarem de destinos ou verificações diferentes:

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

Os valores das regras sobrepõem os valores herdados do arquivo circundante.

## Contexto escopo

O Glossia lê os arquivos `GLOSSIA.md` da raiz do repositório até o arquivo fonte:

- Configurações de pai fornecem padrões.
- Um arquivo mais profundo sobrescreve campos para seu diretório.
- O contexto do Markdown é acumulado do pai para o filho.
- Orientações específicas de idioma e um gerenciador de modelo específico de idioma podem viver em `GLOSSIA/<locale>.md`.

Isso permite que um repositório mantenha orientações de voz amplas na raiz, enquanto coloca orientações específicas de área de produto ou de idioma próximas ao conteúdo que elas afetam.