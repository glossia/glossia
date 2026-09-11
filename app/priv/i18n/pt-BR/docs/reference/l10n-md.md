%{
  title: "L10N.md",
  summary: "Referência para configurações de tradução do repositório e contexto.",
  category: "referência",
  order: 1
}
---
`L10N.md` informa à Glossia quais arquivos traduzir, onde os arquivos traduzidos devem ser armazenados, quais idiomas de destino e que contexto deve orientar o resultado. Um repositório pode ter um arquivo da raiz e arquivos adicionais escopados em subdiretórios.

## Estrutura

Cada arquivo possui duas partes:

1. [YAML não é uma Linguagem de Marcação](https://yaml.org/) frontmatter entre `---` marcadores.
2. Markdown abaixo do frontmatter com contexto de produto, audiência, voz ou domínio.

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

As credenciais do provedor pertencem nas configurações de conta, nunca em `L10N.md`. O opcional `model` valor é o identificador do modelo de conta.

## Campos do frontmatter

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `source_language` | string | não | Idioma de origem deste escopo. O padrão `en`. |
| `model` | string | não | Identificador do modelo de conta. O Glossia usa o padrão da conta quando omitido e relata um erro quando um identificador explícito não existe. |
| `sources` | map ou lista | para uma regra de nível superior | Padrões de arquivos de origem. Valores do mapa podem definir modelos de saída. |
| `targets` | map ou lista | quando as fontes estão configuradas | Códigos de localidade de destino. Um mapa pode associar um código de localidade a um nome de idioma. |
| `output` | string | quando não há mapeamento de origem ou `target_path` fornece um destino | Modelo de arquivo de saída. |
| `target_path` | string | quando não houver mapeamento de origem ou `output` fornece um destino | Modelo de diretório base para arquivos traduzidos. |
| `translate` | list | no | Múltiplas regras de tradução, cada uma com suas próprias fontes e substituições opcionais. |
| `exclude` | list | no | Padrões de arquivos para pular. |
| `preserve` | list | no | Tipos de conteúdo que devem permanecer inalterados, como placeholders ou localizadores de recursos uniformes. |
| `frontmatter` | string | no | `preserve` por padrão, ou `translate`. |
| `prompt` | string | no | Orientação adicional para este escopo ou regra. |
| `validation` | list | para extensões de arquivo sem um adaptador integrado | Um comando de validação seguido de seus argumentos. O comando recebe o candidato em seu caminho de destino real e deve retornar um status não nulo quando o arquivo é inválido. |
| `check_cmd` | string | não | Um comando de verificação disponível para o fluxo de trabalho de tradução. |
| `check_cmds` | map | não | Comandos de verificação nomeados disponíveis para o fluxo de trabalho de tradução. |
| `retries` | integer | não | Número de tentativas de reinício após uma verificação falha. O padrão é `2`. |
| `locale` | string | não | Localidade anexada a um arquivo de contexto específico da localidade. |

Campos de frontmatter desconhecidos são ignorados.

## Formatos de arquivo

Glossia possui tratamento nativo para Markdown, JavaScript Object Notation, YAML Ain't Markup Language, objeto portátil e arquivos de texto plano. Outras extensões de arquivo falham no planejamento a menos que o aplicável `L10N.md` declara um `validation` comando. Isso evita tratar silenciosamente um formato estruturado proprietário como texto sem restrições.

O comando de validação é executado após o candidato ter sido escrito temporariamente para seu caminho de destino real. Ele pode invocar o parser, compilador ou comando de construção nativo do repositório. O Glossia restaura o destino anterior após cada tentativa de validação e escreve apenas o candidato aceito posteriormente.

## Mapeamentos de fonte

O formato mais claro mapeia cada padrão de fonte para um modelo de saída:

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

## Idiomas alvo

Um mapa usa cada código de localização como seu identificador de idioma:

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
| `{locale}` ou `{lang}` | Código de localização de destino. |
| `{relpath}` | Caminho de origem relativo ao padrão correspondente. |
| `{basename}` | Nome do arquivo de origem sem sua extensão. |
| `{ext}` | Extensão do arquivo de origem sem o ponto inicial. |

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

Os valores das regras substituem os valores herdados do arquivo circundante.

## Contexto de escopo

O Glossia lê os arquivos `L10N.md` da raiz do repositório até o arquivo de origem:

- Configurações de nível superior fornecem o padrão.
- Um arquivo mais profundo substitui campos para seu diretório.
- O contexto de Markdown é acumulado do pai para o filho.
- Orientação específica para a localização e um gerenciador de modelo específico para a localização podem residir em `L10N/<locale>.md`.

Isso permite que um repositório mantenha orientações gerais de tom na raiz, ao mesmo tempo que posiciona orientações da área do produto ou específicas do idioma próximas ao conteúdo que afetam.