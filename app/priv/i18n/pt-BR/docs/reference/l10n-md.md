%{
  title: "L10N.md",
  summary: "Referência para configurações de tradução de repositório e contexto.",
  category: "referência",
  order: 1
}
---
`L10N.md` informa quais arquivos traduzir para o Glossia, onde pertencem os arquivos traduzidos, quais idiomas visalhar e qual contexto deve guiar o resultado. Um repositório pode ter um arquivo raiz e arquivos escopados adicionais em subdiretórios.

## Estrutura

Cada arquivo tem duas partes:

1. [YAML não é markup language](https://yaml.org/) frontmatter entre `---` markers.
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

As credenciais do provedor devem estar nas configurações da conta, nunca em`L10N.md`. O valor opcional `model` é um identificador de modelo de conta.

## Campos de frontmatter

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `source_language` | string | não | Local de origem para este escopo. Padrão é `en`. |
| `model` | string | não | Identificador de modelo de conta. O Glossia usa o padrão da conta quando omitido e relata um erro quando um identificador explícito não existe. |
| `sources` | mapa ou lista | para uma regra de nível superior | Padrões de arquivos de origem. Valores de mapa podem definir modelos de saída. |
| `targets` | mapa ou lista | quando as origens são configuradas | Códigos de local de destino. Um mapa pode associar um código de local ao nome de um idioma. |
| `output` | string | quando nenhum mapeamento de origem ou `target_path` fornece um destino | Modelo do arquivo de saída. |
| `target_path` | string | quando nenhum mapeamento de origem ou `output` fornece um destino | Modelo do diretório base para arquivos traduzidos. |
| `translate` | lista | não | Várias regras de tradução, cada uma com suas próprias origens e substituições opcionais. |
| `exclude` | lista | não | Padrões de arquivo a ignorar. |
| `preserve` | lista | não | Tipos de conteúdo que devem permanecer inalterados, como espaços reservados ou identificadores de recursos uniformes. |
| `frontmatter` | string | não | `preserve` por padrão, ou `translate`. |
| `prompt` | string | não | Orientações adicionais para este escopo ou regra. |
| `validation` | lista | para extensões de arquivo sem adaptador embutido | Um comando de validação seguido de seus argumentos. O comando recebe o candidato em seu caminho real de destino e deve retornar um status não zero quando o arquivo for inválido. |
| `check_cmd` | string | não | Um comando de verificação disponível ao fluxo de tradução. |
| `check_cmds` | mapa | não | Comandos de verificação nomeados disponíveis ao fluxo de tradução. |
| `retries` | inteiro | não | Número de tentativas de retomada após uma verificação falha. Padrão é `2`. |
| `locale` | string | não | Local anexado a um arquivo de contexto específico para o local. |

Campos desconhecidos do frontmatter são ignorados.

## Formatos de arquivo

O Glossia possui tratamento embutido para Markdown, JavaScript Object Notation, YAML não é markup language, objeto portátil e arquivos de texto puro. Outras extensões de arquivo falham no planejamento a menos que o `L10N.md` declare um `validation` comando. Isso evita silenciosamente tratar um formato estruturado proprietário como texto sem restrições.

O comando de validação é executado após o candidato ter sido escrito temporariamente em seu caminho real de destino. Ele pode invocar o parser nativo, compilador ou comando de construction do repositório. O Glossia restaura o destino anterior após cada tentativa de validação e apenas escreve o candidato aceito posteriormente.

## Mapeamentos de origem

A forma mais clara mapeia cada padrão de origem para um modelo de saída:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Uma lista de origem também é válida, mas precisa de `output` ou `target_path` para definir o destino:

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
| `{locale}` ou `{lang}` | Código de idioma de destino. |
| `{relpath}` | Caminho da fonte relativo ao padrão correspondente. |
| `{basename}` | Nome do arquivo de fonte sem a extensão. |
| `{ext}` | Extensão do arquivo de fonte sem o ponto inicial. |

## Regras múltiplas

Use `translate` quando diferentes grupos de conteúdo precisam de destinos ou verificações diferentes:

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

Os valores das regras substituem os valores herdados do arquivo envolvente.

## Contexto escopado

O Glossia lê os arquivos `L10N.md` da raiz do repositório em direção ao arquivo de origem:

- As configurações pai fornecem padrões.
- Um arquivo mais profundo sobrescreve os campos para o seu diretório.
- O contexto de Markdown é acumulado do pai para o filho.
- Orientações específicas do idioma e um manipulador de modelo específico do idioma podem viver em `L10N/<locale>.md`.

Isso permite que um repositório mantenha orientações de voz amplas na raiz, ao mesmo tempo que coloca orientações específicas de área do produto ou de idioma perto do conteúdo que afeta.