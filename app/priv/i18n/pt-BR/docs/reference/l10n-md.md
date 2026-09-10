%{
  title: "L10N.md",
  summary: "Referência para configurações de tradução de repositório e contexto.",
  category: "referência",
  order: 1
}
---
`L10N.md` Diz ao Glossia quais arquivos devem ser traduzidos, para onde os arquivos traduzidos pertencem, quais idiomas são os alvos e qual contexto deve orientar o resultado. Um repositório pode ter um arquivo raiz e arquivos adicionais escopados em subdiretórios.

## Estrutura

Cada arquivo possui duas partes:

1. [YAML não é uma Linguagem de Marcação](https://yaml.org/) frontmatter entre `---` marcadores.
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

As credenciais do provedor devem ficar nas configurações da conta, nunca em `L10N.md`. Opcional `model` valor é um identificador de modelo de conta.

## Campos Frontmatter

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `source_language` | string | não | Localização de origem deste escopo. Por padrão `en`. |
| `model` | string | não | Handle do modelo de conta. Glossia usa o padrão da conta quando omitido e relata um erro quando um handle explícito não existe. |
| `sources` | map ou lista | para uma regra de nível superior | Padrões de arquivo de origem. Valores de mapa podem definir modelos de saída. |
| `targets` | map ou lista | quando as fontes estão configuradas | Códigos de localização de destino. Um mapa pode associar um código de localização com um nome de idioma. |
| `output` | string | quando não há mapeamento de fonte ou `target_path` fornece um destino | Modelo de arquivo de saída. |
| `target_path` | string | quando não há mapeamento de origem ou `output` fornece um destino | Modelo de diretório base para arquivos traduzidos. |
| `translate` | list | não | Múltiplas regras de tradução, cada uma com suas próprias fontes e sobrescritas opcionais. |
| `exclude` | list | não | Padrões de arquivo para ignorar. |
| `preserve` | list | no | Tipos de conteúdo que devem permanecer inalterados, como placeholders ou localizadores de recursos uniformes. |
| `frontmatter` | string | no | `preserve` por padrão, ou `translate`. |
| `prompt` | string | no | Orientação adicional para este escopo ou regra. |
| `validation` | list | para extensões de arquivo sem um adaptador embutido | Um comando de validação seguido pelos seus argumentos. O comando recebe o candidato em seu caminho real de destino e deve retornar um status diferente de zero quando o arquivo é inválido. |
| `check_cmd` | string | não | Um comando de verificação disponível ao fluxo de trabalho de tradução. |
| `check_cmds` | map | não | Comandos de verificação nomeados disponíveis ao fluxo de trabalho de tradução. |
| `retries` | integer | não | Número de reintentos após uma verificação falha. Padrão é `2`. |
| `locale` | string | não |

Campos de frontmatter desconhecidos são ignorados.

## Formatos de arquivo

O Glossia possui tratamento nativo para Markdown, Notação de Objeto JavaScript, Linguagem de Marcação YAML, objetos portáteis e arquivos de texto simples. Outras extensões de arquivo falham no planejamento a menos que a aplicável `L10N.md` declara um `validation` comando. Isso evita silenciosamente tratar um formato estruturado proprietário como texto sem restrições.

O comando de validação é executado após o candidato ter sido escrito temporariamente para seu caminho de destino real. Ele pode invocar o analisador nativo, o compilador ou o comando de build do repositório. O Glossia restaura o destino anterior após cada tentativa de validação e escreve o candidato aceito apenas após isso.

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

Uma lista usa cada código de localidade como seu identificador de idioma:

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
| `{relpath}` | Caminho de origem relativo ao padrão correspondido. |
| `{basename}` | Nome do arquivo de origem sem a extensão. |
| `{ext}` | Extensão do arquivo de origem sem o ponto inicial. |

## Regras múltiplas

Use `translate` quando diferentes grupos de conteúdo precisarم destinos ou verificações diferentes:

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

Valores de regra sobre-escrevem valores herdados do arquivo circundante.

## Contexto escopado

O Glossia lê os arquivos `L10N.md` da raiz do repositório em direção ao arquivo de origem:

- Configurações do arquivo pai fornecem padrões.
- Um arquivo mais profundo substitui campos para o seu diretório.
- O contexto Markdown é acumulado do arquivo pai para o arquivo filho.
- Orientações específicas de localidade e um manipulador de modelo específico de localidade podem residir em `L10N/<locale>.md`.

Isso permite que um repositório mantenha orientações de tom gerais na raiz, enquanto coloca orientações específicas de área de produto ou idioma próximas ao conteúdo que afetam.