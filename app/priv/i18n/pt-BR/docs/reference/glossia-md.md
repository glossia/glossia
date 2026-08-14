%{
  title: "GLOSSIA.md",
  summary: "Referência para configurações e contexto de tradução do repositório.",
  category: "reference",
  order: 1
}
---
`GLOSSIA.md` informa ao Glossia quais arquivos devem ser traduzidos, onde os arquivos traduzidos devem ser armazenados, quais idiomas devem ser usados como destino e qual contexto deve orientar o resultado. Um repositório pode ter um arquivo raiz e arquivos adicionais com escopo definido em subdiretórios.

## Estrutura

Cada arquivo tem duas partes:

1. Metadados iniciais em [YAML Ain't Markup Language](https://yaml.org/) entre marcadores `---`.
2. Markdown abaixo dos metadados iniciais com contexto de produto, público, voz ou domínio.

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

As credenciais do provedor devem ser configuradas nas configurações da conta, nunca em `GLOSSIA.md`. O valor opcional `model` é um identificador de modelo da conta.

## Campos dos metadados iniciais

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `source_language` | string | não | Localidade de origem deste escopo. O padrão é `en`. |
| `model` | string | não | Identificador de modelo da conta. O Glossia usa o padrão da conta quando omitido e relata um erro quando um identificador explícito não existe. |
| `sources` | mapa ou lista | para uma regra de nível superior | Padrões dos arquivos de origem. Os valores do mapa podem definir modelos de saída. |
| `targets` | mapa ou lista | quando as origens estão configuradas | Códigos das localidades de destino. Um mapa pode associar um código de localidade a um nome de idioma. |
| `output` | string | quando nenhum mapeamento de origem ou `target_path` fornece um destino | Modelo do arquivo de saída. |
| `target_path` | string | quando nenhum mapeamento de origem ou `output` fornece um destino | Modelo do diretório-base para os arquivos traduzidos. |
| `translate` | lista | não | Múltiplas regras de tradução, cada uma com suas próprias origens e substituições opcionais. |
| `exclude` | lista | não | Padrões de arquivos que devem ser ignorados. |
| `preserve` | lista | não | Tipos de conteúdo que devem permanecer inalterados, como espaços reservados ou localizadores uniformes de recursos. |
| `frontmatter` | string | não | `preserve` por padrão ou `translate`. |
| `prompt` | string | não | Orientações adicionais para este escopo ou regra. |
| `validation` | lista | para extensões de arquivo sem um adaptador integrado | Um comando de validação seguido de seus argumentos. O comando recebe o candidato em seu caminho de destino real e deve retornar um status diferente de zero quando o arquivo for inválido. |
| `check_cmd` | string | não | Um comando de verificação disponível para o fluxo de trabalho de tradução. |
| `check_cmds` | mapa | não | Comandos de verificação nomeados disponíveis para o fluxo de trabalho de tradução. |
| `retries` | inteiro | não | Número de novas tentativas após uma verificação com falha. O padrão é `2`. |
| `locale` | string | não | Localidade associada a um arquivo de contexto específico da localidade. |

Campos desconhecidos nos metadados iniciais são ignorados.

## Formatos de arquivo

O Glossia oferece tratamento integrado para arquivos Markdown, JavaScript Object Notation, YAML Ain't Markup Language, Portable Object e texto simples. Outras extensões de arquivo causam falha no planejamento, a menos que o `GLOSSIA.md` aplicável declare um comando `validation`. Isso evita que um formato estruturado proprietário seja tratado silenciosamente como texto sem restrições.

O comando de validação é executado depois que o candidato é gravado temporariamente em seu caminho de destino real. Ele pode invocar o analisador, o compilador ou o comando de compilação nativo do repositório. O Glossia restaura o destino anterior após cada tentativa de validação e somente grava o candidato aceito depois disso.

## Mapeamentos de origem

A forma mais clara associa cada padrão de origem a um modelo de saída:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Uma lista de fontes também é válida, mas requer `output` ou `target_path` para definir o destino:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Idiomas de destino

Uma lista usa cada código de localidade como identificador do idioma:

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
| `{locale}` ou `{lang}` | Código da localidade de destino. |
| `{relpath}` | Caminho da fonte relativo ao padrão correspondente. |
| `{basename}` | Nome do arquivo de origem sem a extensão. |
| `{ext}` | Extensão do arquivo de origem sem o ponto inicial. |

## Várias regras

Use `translate` quando diferentes grupos de conteúdo exigirem destinos ou verificações distintos:

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

Os valores da regra substituem os valores herdados do arquivo que a contém.

## Contexto com escopo

A Glossia lê os arquivos `GLOSSIA.md` desde a raiz do repositório até o arquivo de origem:

- As configurações do nível superior fornecem os valores padrão.
- Um arquivo em um nível mais profundo substitui os campos para seu diretório.
- O contexto Markdown é acumulado do nível superior para o inferior.
- Orientações específicas da localidade e um identificador de modelo específico da localidade podem ficar em `GLOSSIA/<locale>.md`.

Isso permite que um repositório mantenha orientações gerais de voz na raiz e coloque orientações específicas da área do produto ou do idioma próximas ao conteúdo afetado.