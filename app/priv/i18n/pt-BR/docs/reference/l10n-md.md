%{
  title: "L10N.md",
  summary: "Referência para configurações de tradução do repositório e contexto.",
  category: "reference",
  order: 1
}
---
`L10N.md` instrui o Glossia a quais arquivos traduzir, onde os arquivos traduzidos pertencem, quais idiomas alvejar e qual contexto deve guiar o resultado. Um repositório pode ter um arquivo raiz e arquivos adicionais escopados em subdiretórios.

## Estrutura

Cada arquivo tem duas partes:

1. [YAML não é linguagem de marcação](https://yaml.org/) frontmatter entre `---` marcadores.
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

As credenciais do provedor pertencem às configurações da conta, nunca em `L10N.md`. `model` valor é um identificador de modelo de conta.

## Campos do frontmatter

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
 | `source_language` | string | no | Origem deste escopo. Padrão é `en`. |
| `model` | string | no | Identificador de modelo de conta. O Glossia usa o padrão da conta quando omitido e reporta erro quando um identificador explícito não existe. |
| `sources` | mapa ou lista | para uma regra de nível superior | Modelos de arquivos das originais. Valores do mapa podem definir modelos de saída. |
| `targets` | mapa ou lista | quando as originais são configuradas | Códigos de idiomas de destino. Um mapa pode associar um código de idioma a um nome de idioma. |
| `output` | string | quando sem mapeamento de origem ou `target_path` fornecer um destino | Modelo de arquivo de saída. |
| `target_path` | string | quando sem mapeamento de origem ou `output` fornecer um destino | Modelo de diretório base para arquivos traduzidos. |
| `translate` | lista | no | Múltiplas regras de tradução, cada uma com suas próprias originais e substituições opcionais. |
| `exclude` | lista | no | Modelos de arquivos a pular. |
| `preserve` | lista | no | Tipos de conteúdo que devem permanecer inalterados, como marcadores ou identificadores de localização de recursos uniformes. |
| `frontmatter` | string | no | `preserve` por padrão, ou `translate`. |
| `prompt` | string | no | Guia adicional para este escopo ou regra. |
| `validation` | lista | para extensões de arquivo sem adaptador embutido | Um comando de validação seguido de seus argumentos. O comando recebe o candidato em seu caminho de destino real e deve retornar um status não zero quando o arquivo é inválido. |
| `check_cmd` | string | no | Um comando de verificação disponível para o fluxo de tradução. |
| `check_cmds` | mapa | no | Comandos de verificação nomeados disponíveis para o fluxo de tradução. |
| `retries` | inteiro | no | Número de tentativas de reexecução após uma verificação falha. Padrão é `2`. |
| `locale` | string | no | Localidade anexada a um arquivo de contexto específico de localidade. |

Campos de frontmatter desconhecidos são ignorados.

## Formatos de arquivo

O Glossia possui tratamento embutido para Markdown, JavaScript Object Notation, YAML, objeto portátil e arquivos de texto simples. Outras extensões de arquivo falham no planejamento a menos que o `L10N.md` declare `validation` comando. Isso evita silenciosamente tratar um formato estruturado proprietário como texto não restrito.

O comando de validação executa após o candidato ter sido escrito temporariamente para seu caminho de destino real. Ele pode invocar o analisador, compilador ou comando de build nativo do repositório. O Glossia restaura o alvo anterior após cada tentativa de validação e escreve apenas o candidato aceito posteriormente.

## Mapeamentos de origem

A forma mais clara mapeia cada padrão de origem para um modelo de saída:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Uma lista de origem também é válida, mas ela precisa `output` ou `target_path` para definir o destino:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Idiomas-alvo

Uma lista usa cada código de localidade como identificador de idioma:

```yaml
targets:
  - es
  - ja
```

Um mapeamento pode adicionar um nome de idioma legível:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variáveis de saída

| Variável | Valor |
|---|---|
| `{locale}` ou `{lang}` | Código de localidade de destino. |
| `{relpath}` | Caminho da fonte relativo ao padrão correspondido. |
| `{basename}` | Nome do arquivo de fonte sem extensão. |
| `{ext}` | Extensão do arquivo de origem sem o ponto inicial. |

## Múltiplas regras

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

Os valores das regras substituem os valores herdados do arquivo circundante.

## Escopo do contexto

O Glossia lê os arquivos `L10N.md` desde a raiz do repositório até o arquivo de origem:

- As configurações do nível pai fornecem o padrão.
- Um arquivo mais profundo substitui os campos do seu diretório.
- O contexto de Markdown é acumulado do pai para o filho.
- As orientações específicas de localidade e um manipulador de modelo específico de localidade podem residir em `L10N/<locale>.md`.

Isso permite que um repositório mantenha orientações de tom amplo na raiz, posicionando ao mesmo tempo orientações específicas de área de produto ou de idioma próximas ao conteúdo que afeta.