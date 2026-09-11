%{
  title: "L10N.md",
  summary: "Referência para configurações de tradução do repositório e contexto.",
  category: "Referência",
  order: 1
}
---
`L10N.md`diz ao Glossia quais arquivos traduzir, onde os arquivos traduzidos devem ficar, quais idiomas alvejar e que contexto deve guiar o resultado. Um repositório pode ter um arquivo raiz e arquivos escopados adicionais em subdiretórios.

## Estrutura

Cada arquivo tem duas partes:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre `---` markers.
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

As credenciais do provedor pertencem nas configurações de conta, nunca em `L10N.md`. O valor comercial `model` é opcional e representa o handle do modelo de conta.

## Campos do frontmatter

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `source_language` | string | não | Locale de origem para este escopo. Padrão é `en`. |
| `model` | string | não | Handle do modelo de conta. Uso o padrão da conta quando omitido e reporta erro quando um handle explícito não existe. |
| `sources` | mapa ou lista | para uma regra de nível superior | Padrões de arquivos de origem. Valores de mapa podem definir modelos de saída. |
| `targets` | mapa ou lista | quando sources configurados | Códigos de locale de destino. Um mapa pode associar um código de locale a um nome de idioma. |
| `output` | string | quando não mapeamento de origem ou `target_path` fornece destino | Modelo de arquivo de saída. |
| `target_path` | string | quando não mapeamento de origem ou `output` fornece destino | Modelo de diretório base para arquivos traduzidos. |
| `translate` | lista | não | Múltiplas regras de tradução, cada uma com suas próprias fontes e superposições opcionais. |
| `exclude` | lista | não | Padrões de arquivo a ignorar. |
| `preserve` | lista | não | Tipos de conteúdo que devem permanecer inalterados, como placeholders ou uniform resource locators. |
| `frontmatter` | string | não | `preserve` por padrão, ou `translate`. |
| `prompt` | string | não | Orientação adicional para este escopo ou regra. |
| `validation` | lista | para extensões de arquivo sem adaptador prévio | Um comando de validação seguido por seus argumentos. O comando recebe o candidato em seu caminho alvo real e deve retornar um status não nulo quando o arquivo é inválido. |
| `check_cmd` | string | não | Um comando de verificação disponível ao fluxo de trabalho de tradução. |
| `check_cmds` | mapa | não | Comandos de verificação nomeados disponíveis ao fluxo de trabalho de tradução. |
| `retries` | inteiro | não | Número de tentativas de retomada após uma verificação falhada. Padrão é `2`. |
| `locale` | string | não | Locale anexado a um arquivo de contexto específico de locale. |

Campos desconhecidos do frontmatter são ignorados.

## Formatos de arquivo

O Glossia tem tratamento nativo para Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable object e arquivos de texto plano. Outras extensões de arquivo falham no planejamento salvo se `L10N.md` declare um `validation` command. Isso evita tratar silenciosamente um formato estruturado proprietário como texto sem restricciones.

O comando de verificação roda após o candidato ter sido escrito temporariamente em seu destino real. Pode invocar o parser nativo do repositório, compilador ou comando de build. O Glossia restaura o alvo anterior após cada tentativa de verificação e somente escreve o candidato aceito posteriormente.

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

## Idiomas alvo

Uma lista usa cada código de idioma como seu identificador de idioma:

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
| `{locale}` ou `{lang}` | Código do idioma alvo. |
| `{relpath}` | Caminho fonte relativo ao padrão correspondido. |
| `{basename}` | Nome do arquivo fonte sem a extensão. |
| `{ext}` | Extensão do arquivo fonte sem o ponto inicial. |

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

Os valores da regra sobrepõem os valores heredados do arquivo circundante.

## Contexto escopado

O Glossia lê arquivos `L10N.md` da raiz do repositório em direção ao arquivo fonte:

- Configurações do diretório pai fornecem valores padrão.
- Um arquivo mais profundo sobrepõe campos para seu diretório.
- O contexto do Markdown é acumulado do pai para o filho.
- Orientação específica do idioma e um manipulador de modelo específico do idioma podem residir em `L10N/<locale>.md`.

Isso permite que um repositório mantenha orientação ampla do idioma na raiz, ao mesmo tempo que coloca orientação específica para área do produto ou idioma próxima ao conteúdo que afeta.