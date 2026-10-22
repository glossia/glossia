%{
  title: "L10N.md",
  summary: "Referência para configurações de tradução do repositório e contexto.",
  category: "referência",
  section: "translation",
  order: 1
}
---

`L10N.md` diz ao Glossia quais arquivos traduzir, onde os arquivos traduzidos devem ficar, quais idiomas de destino e que contexto deve guiar o resultado. Um repositório pode ter um arquivo raiz e arquivos adicionais de escopo em subdiretórios.

## Estrutura

Cada arquivo tem duas partes:

1. [YAML não é Linguagem de Marcação](https://yaml.org/) frontmatter entre os marcadores `---`.
2. Markdown abaixo do frontmatter com contexto de produto, público, voz ou domínio.

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

Credenciais do provedor pertencem às definições da conta, nunca em `L10N.md`. O valor opcional `model` é um handle de modelo de conta.

## Campos do frontmatter

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `source_language` | string | não | Local de origem para este escopo. Padrão é `en`. |
| `model` | string | não | Handle do modelo de conta. O Glossia usa o padrão da conta quando omitido e relata um erro quando um handle explícito não existe. |
| `sources` | mapa ou lista | para uma regra de nível superior | Padrões de arquivo de origem. Valores de mapa podem definir modelos de saída. |
| `targets` | mapa ou lista | quando as fontes estão configuradas | Códigos de local de destino. Um mapa pode associar um código de local a um nome de idioma. |
| `output` | string | quando não há mapeamento de origem ou `target_path` fornece um destino | Modelo de arquivo de saída. |
| `target_path` | string | quando não há mapeamento de origem ou `output` fornece um destino | Modelo de diretório base para arquivos traduzidos. |
| `translate` | lista | não | Múltiplas regras de tradução, cada uma com suas próprias fontes e substituições opcionais. |
| `exclude` | lista | não | Padrões de arquivos para ignorar. |
| `preserve` | lista | não | Tipos de conteúdo que devem permanecer inalterados, como placeholders ou localizadores de recursos uniformes. |
| `frontmatter` | string | não | `preserve` por padrão, ou `translate`. |
| `prompt` | string | não | Orientação adicional para este escopo ou regra. |
| `validation` | lista | para extensões de arquivo sem adaptador nativo | Um comando de validação seguido de seus argumentos. O comando recebe o candidato em seu caminho real de destino e deve retornar um status não zero quando o arquivo for inválido. |
| `check_cmd` | string | não | Um comando de verificação disponível para o fluxo de trabalho de tradução. |
| `check_cmds` | mapa | não | Comandos de verificação nomeados disponíveis para o fluxo de trabalho de tradução. |
| `retries` | inteiro | não | Número de tentativas de reintentação após uma verificação falha. Padrão é `2`. |
| `locale` | string | não | Local anexado a um arquivo de contexto específico para local. |
| `glossary` | lista ou mapa | não | Em `L10N.md`, uma lista de termos do glossário. Em `L10N/<locale>.md`, um mapa de cada termo para sua tradução naquele idioma. Arquivos aninhados adicionam e substituem as entradas herdadas. Veja a [referência de glossário](/docs/reference/glossary). |

Campos frontmatter desconhecidos são ignorados.

## Formatos de arquivo

O Glossia possui tratamento nativo para Markdown, JavaScript Object Notation, YAML Ain't Markup Language, objetos portáveis e arquivos de texto simples. Outras extensões de arquivo não atendem ao planejamento a menos que o `L10N.md` aplicável declare um comando `validation`. Isso evita silenciosamente tratar um formato estruturado proprietário como texto sem restrições.

No Markdown, apenas verso prosa é traduzido: parágrafos, cabeçalhos, itens de lista, células de tabela, os atributos `title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, e `caption` de componentes e HTML, e o texto de um `<summary>` HTML. Cada outro byte, incluindo código, destinos de link, componentes, alertas e âncoras explícitas de cabeçalho, é mantido exatamente como na fonte. Veja [recuperação de tradução](/docs/explanation/translation-recovery) para ver como isso funciona.

O comando de validação executa após o candidato ter sido escrito temporariamente em seu caminho real de destino. Ele pode invocar o parser, compilador ou comando de build nativo do repositório. O Glossia restaura o alvo anterior após cada tentativa de validação e apenas escreve o candidato aceito por em seguida.

## Mapeamentos de origem

A forma mais clara mapeia cada padrão de origem a um modelo de saída:

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

Uma lista usa cada código de local como seu identificador de idioma:

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
| `{locale}` ou `{lang}` | Código de local de destino. |
| `{relpath}` | Caminho de origem relativo ao padrão correspondido. |
| `{basename}` | Nome do arquivo de origem sem sua extensão. |
| `{ext}` | Extensão do arquivo de origem sem o ponto inicial. |

## Múltiplas regras

Use `translate` quando diferentes grupos de conteúdo Requerem destinos ou verificações diferentes:

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

Os valores da regra substituem os valores herdados do arquivo circundante.

## Contexto escopado

O Glossia lê os arquivos `L10N.md` da raiz do repositório em direção ao arquivo de origem:

- Configurações pai fornecem valores padrão.
- Um arquivo mais profundo substitui campos para seu diretório.
- O contexto do Markdown é acumulado do pai para o filho.
- Orientações específicas de local e um identificador de modelo específico de local podem residir em `L10N/<locale>.md`.

Isso permite que um repositório mantenha orientações gerais de voz na raiz, enquanto coloca orientações específicas de área de produto ou de idioma próximas ao conteúdo que afetam.
