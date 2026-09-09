%{
  title: "L10N.md",
  summary: "Referência para configurações de tradução do repositório e contexto.",
  category: "referência",
  order: 1
}
---
`L10N.md` diz ao Glossia quais arquivos traduzir, onde ficariam os arquivos traduzidos, quais idiomas almejar e qual contexto deve guiar o resultado. Um repositório pode ter um arquivo na raiz e arquivos adicionais com escopo em subdiretórios.

## Estrutura

Cada arquivo tem duas partes:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre os marcadores `---`.
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

As credenciais do provedor pertencem às configurações da conta, nunca no `L10N.md`. O valor opcional `model` é um manipulador de modelo de conta.

## Campos do frontmatter

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `source_language` | string | não | Idioma de origem para este escopo. Padrão é `en`. |
| `model` | string | não | Manipulador de modelo de conta. O Glossia usa o padrão da conta quando omitido e relata um erro quando um manipulador explícito não existe. |
| `sources` | mapa ou lista | para uma regra de nível superior | Padrões de arquivos de origem. Os valores do mapa podem definir modelos de saída. |
| `targets` | mapa ou lista | quando as fontes são configuradas | Códigos de idiomas de destino. Um mapa pode associar um código de idioma a um nome de idioma. |
| `output` | string | quando não há mapeamento de origem ou quando um `target_path` fornece um destino | Modelo de arquivo de saída. |
| `target_path` | string | quando não há mapeamento de origem ou quando `output` fornece um destino | Modelo de diretório base para arquivos traduzidos. |
| `translate` | lista | não | Múltiplas regras de tradução, cada uma com suas próprias fontes e sobreposições opcionais. |
| `exclude` | lista | não | Padrões de arquivos para pular. |
| `preserve` | lista | não | Tipos de conteúdo que devem permanecer inalterados, como marcadores ou localizadores de recurso uniforme. |
| `frontmatter` | string | não | `preserve` por padrão, ou `translate`. |
| `prompt` | string | não | Orientação adicional para este escopo ou regra. |
| `validation` | lista | para extensões de arquivo sem adaptador embutido | Um comando de validação seguido de seus argumentos. O comando recebe o candidato em seu caminho real de destino e deve retornar um status diferente de zero quando o arquivo é inválido. |
| `check_cmd` | string | não | Um comando de verificação disponível para o fluxo de trabalho de tradução. |
| `check_cmds` | mapa | não | Comandos de verificação nomeados disponíveis para o fluxo de trabalho de tradução. |
| `retries` | inteiro | não | Número de tentativas de reprocessamento após uma verificação falha. Padrão é `2`. |
| `locale` | string | não | Locale anexado a um arquivo de contexto específico de locale. |

Campos desconhecidos do frontmatter são ignorados.

## Formatos de arquivo

O Glossia possui tratamento embutido para Markdown, JSON, YAML Ain't Markup Language, objetos portáteis e arquivos de texto simples. Outras extensões de arquivos falham no planejamento caso o `L10N.md` aplicável não declare um comando `validation`. Isso evita silenciosamente tratar um formato estruturado proprietário como texto não restrito.

O comando de validação ocorre após o candidato ter sido escrito temporariamente para seu caminho real de destino. Ele pode invocar o parser nativo do repositório, o compilador ou o comando de construção. O Glossia restaura o destino anterior após cada tentativa de validação e escreve apenas o candidato aceito posteriormente.

## Mapeamentos de fonte

A forma mais clara mapeia cada padrão de fonte a um modelo de saída:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Uma lista de fontes também é válida, mas precisa de `output` ou `target_path` para definir o destino:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Idiomas de destino

Uma lista usa cada código do locale como identificador de idioma:

```yaml
targets:
  - es
  - ja
```

Um mapa pode adicionar um nome legível de idioma:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variáveis de saída

| Variável | Valor |
|---|---|
| `{locale}` ou `{lang}` | Código do locale de destino. |
| `{relpath}` | Caminho da fonte relativo ao padrão correspondente. |
| `{basename}` | Nome do arquivo fabricante sem sua extensão. |
| `{ext}` | Extensão do arquivo fonte sem o ponto inicial. |

## Regras múltiplas

Use `translate` quando grupos diferentes de conteúdo precisarem de destinos ou verificações diferentes:

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

Os valores da regra substituem valores herdados do arquivo circundante.

## Contexto escopado

O Glossia lê arquivos `L10N.md` da raiz do repositório em direção ao arquivo fonte:

- Configurações do pai fornecem valores padrão.
- Um arquivo mais profundo anula campos para seu diretório.
- O contexto Markdown é acumulado do pai para o filho.
- Orientações específicas do locale e um manipulador específico do locale podem residir em `L10N/<locale>.md`.

Isso permite que um repositório mantenha orientações gerais de voz na raiz enquanto posiciona orientações específicas de área de produto ou idioma próximas ao conteúdo que afeta.