%{
  title: "L10N.md",
  summary: "Referência para configurações e contexto de tradução do repositório.",
  category: "referência",
  order: 1
}
---
`L10N.md` informa ao Glossia quais arquivos traduzir, onde os arquivos traduzidos devem ser armazenados, quais idiomas atender e qual contexto deve guiar o resultado. Um repositório pode ter um arquivo raiz e arquivos adicionais escopados em subdiretórios.

## Estrutura

Cada arquivo tem duas partes:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre `---` marcadores.
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

 credentials do provedor devem ficar nas configurações de conta, nunca em `L10N.md`. O valor opcional `model` é um identificador de modelo de conta.

## Campos do frontmatter

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `source_language` | string | não | Local de origem para este escopo. Padrão é `en`. |
| `model` | string | não | Identificador de modelo de conta. O Glossia usa o padrão da conta quando omitido e relata um erro quando um identificador explícito não existe. |
| `sources` | mapa ou lista | para uma regra de nível superior | Padrões de arquivos de entrada. Valores do mapa podem definir templates de saída. |
| `targets` | mapa ou lista | quando fontes são configuradas | Códigos de idioma de destino. Um mapa pode associar um código de idioma a um nome de idioma. |
| `output` | string | quando não há mapeamento de fonte ou `target_path` fornece um destino | Modelo de arquivo de saída. |
| `target_path` | string | quando não há mapeamento de fonte ou `output` fornece um destino | Template de diretório base para arquivos traduzidos. |
| `translate` | lista | não | Múltiplas regras de tradução, cada uma com suas próprias fontes e sobreposições opcionais. |
| `exclude` | lista | não | Padrões de arquivo para ignorar. |
| `preserve` | lista | não | Tipos de conteúdo que devem permanecer inalterados, como substituidores de marcador de posição ou uniform resource locators. |
| `frontmatter` | string | não | `preserve` por padrão, ou `translate`. |
| `prompt` | string | não | Orientação adicional para este escopo ou regra. |
| `validation` | lista | para extensões de arquivo sem adaptador integrado | Um comando de validação seguido de seus argumentos. O comando recebe o candidato em seu caminho de destino real e deve retornar um estado não zero quando o arquivo é inválido. |
| `check_cmd` | string | não | Um comando de verificação disponível para o fluxo de trabalho de tradução. |
| `check_cmds` | mapa | não | Comandos de verificação nomeados disponíveis para o fluxo de trabalho de tradução. |
| `retries` | inteiro | não | Número de tentativas de reenvio após uma verificação falha. Padrão para `2`. |
| `locale` | string | não | Localidade associada a um arquivo de contexto específico da localidade. |

Campos desconhecidos do frontmatter são ignorados.

## Formatos de arquivo

O Glossia possui tratamento nativo para Markdown, Notação de Objeto JavaScript, YAML Ain't Markup Language, objeto portátil e arquivos de texto simples. Outras extensões de arquivo falham no planejamento a menos que a aplicável `L10N.md` declare um `validation` comandos. Isso evita tratar silenciosamente um formato estruturado proprietário como texto não restrito.

O comando de validação roda depois que o candidato foi escrito temporariamente para seu caminho de destino real. Ele pode invocar o parser, compilador ou comando de construção nativo do repositório. O Glossia restaura o destino anterior após cada tentativa de validação e escreve o candidato aceito posteriormente.

## Mapeamentos de fonte

A forma mais clara mapeia cada padrão de origem para um template de saída:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Uma lista de fontes também é válida, mas precisa `output` ou `target_path` para definir o destino:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Idiomas de destino

Uma lista usa cada código de idioma como seu identificador linguístico:

```yaml
targets:
  - es
  - ja
```

Um mapeamento pode adicionar um nome legível do idioma:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variáveis de saída

| Variável | Valor |
|---|---|
| `{locale}` ou `{lang}` | Código de localização de destino. |
| `{relpath}` | Caminho de origem relativo ao padrão correspondido. |
| `{basename}` | Nome do arquivo de origem sem sua extensão. |
| `{ext}` | Extensão do arquivo de origem sem o ponto inicial. |

## Regras múltiplas

Use `translate` quando grupos de conteúdo diferentes precisem de destinos ou verificações distintos:

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

Valores de regra substituem valores herdados do arquivo circundante.

## Contexto escopado

O Glossia lê os arquivos `L10N.md` da raiz do repositório em direção ao arquivo de origem:

- As configurações do pai fornecem padrões.
- Um arquivo mais profundo sobrescreve campos para o seu diretório.
- O contexto Markdown é acumulado do pai para o filho.
- Orientações específicas de localidade e um manipulador de modelo específico de localidade podem residir em `L10N/<locale>.md`.

Isso permite que um repositório mantenha orientação de voz ampla na raiz, enquanto posiciona orientação de área de produto ou específica de idioma perto do conteúdo que afeta.