%{
  title: "L10N.md",
  summary: "Referência para configurações de tradução de repositório e contexto.",
  category: "referência",
  section: "translation",
  order: 1
}
---
`L10N.md` explica quais arquivos a Glossia deve localizar, onde localiza os arquivos traduzidos, quais idiomas deve alvejar, e qual contexto deve orientar o resultado. Um repositório pode ter um arquivo de raiz e arquivos adicionais abrangentes em subdiretórios.

## Estrutura

Cada arquivo tem duas partes:

1. [Linguagem Ain't Marcação de Texto (YAML)](https://yaml.org/) cabeçalho famoso entre `---` marcadores.
2. Markdown abaixo do cabeçalho familiar com contexto de produto, audiência, voz ou domínio.

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

Credenciais do provedor pertencem nas configurações de conta, nunca em `L10N.md`. O valor opcional `model` é um identificador do modelo da conta.

## Campos de cabeçalho familiar

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `source_language` | string | não | Idioma de origem para este escopo. Padrão é `en`. |
| `model` | string | não | Identificador do modelo da conta. A Glossia usa o padrão da conta quando omitido e relata erro quando um identificador explícito não existe. |
| `sources` | mapa ou lista | para uma regra de nível superior | Padrões de arquivo de origem. Valores de mapa podem definir modelos de saída. |
| `targets` | mapa ou lista | quando fontes são configuradas | Códigos de idioma de destino. Um mapa pode associar um código de idioma a um nome de idioma. |
| `output` | string | quando não há mapeamento de fonte ou `target_path` fornece um destino | Modelo de arquivo de saída. |
| `target_path` | string | quando não há mapeamento de fonte ou `output` fornece um destino | Modelo de diretório base para arquivos traduzidos. |
| `translate` | lista | não | Múltiplas regras de tradução, cada uma com suas próprias fontes e sobreposições opcionais. |
| `exclude` | lista | não | Padrões de arquivo para ignorar. |
| `preserve` | lista | não | Tipos de conteúdo que devem permanecer inalterados, como placeholders ou identificadores de localização de recursos uniformes. |
| `frontmatter` | string | não | `preserve` por padrão, ou `translate`. |
| `prompt` | string | não | Orientação adicional para este escopo ou regra. |
| `validation` | lista | para extensões de arquivo sem um provedor integrado | Um comando de validação seguido de seus argumentos. O comando recebe o candidato em seu caminho de destino real e deve retornar um status não zero quando o arquivo é inválido. |
| `check_cmd` | string | não | Um comando de verificação disponível ao fluxo de trabalho de tradução. |
| `check_cmds` | mapa | não | Comandos de verificação nomeados disponíveis ao fluxo de trabalho de tradução. |
| `retries` | inteiro | não | Número de tentativas após uma verificação falha. Padrão é `2`. |
| `locale` | string | não | Locale anexado a um arquivo de contexto específico de locale. |
| `glossary` | lista ou mapa | não | Em `L10N.md`, uma lista de termos de glosário. Em `L10N/<locale>.md`, um mapa de cada termo para sua tradução naquele idioma. Arquivos aninhados adicionam e sobrescrevem entradas herdadas. Veja a [referência de glosário](/docs/reference/glossary). |

Campos de cabeçalho familiar desconhecidos são ignorados.

## Formatos de arquivo

A Glossia possui tratamento nativo para Markdown, Notação de Objeto JavaScript, Linguagem Ain't Marcação de Texto (YAML), objeto portátil, e arquivos de texto puro. Outras extensões de arquivo falham no planejamento a menos que o `L10N.md` aplicado declare um `validation` comando. Isso evita tratar silenciosamente um formato estruturado proprietário como texto ilimitado.

Em Markdown, apenas prosa é traduzida: parágrafos, títulos, itens de lista, células de tabela, o `title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, e `caption` atributos de componentes e HTML, e o texto de um HTML `<summary>`. Cada outra byte, incluindo código, destinos de link, componentes, alertas e âncoras de título explícitas, é mantido exatamente como na fonte. Veja [recuperação de tradução](/docs/explanation/translation-recovery) de como isso funciona.

O comando de validação é executado após o candidato ser escrito temporariamente em seu caminho de destino real. Ele pode invocar o parser nativo, o compilador ou o comando de build do repositório. O Glossia restaura o destino anterior após cada tentativa de validação e só escreve o candidato aceito posteriormente.

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

Uma lista usa cada código de locale como seu identificador de linguagem:

```yaml
targets:
  - es
  - ja
```

Um mapeamento pode adicionar um nome de linguagem legível:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variáveis de saída

| Variável | Valor |
|---|---|
| `{locale}` ou `{lang}` | Código de locale de destino. |
| `{relpath}` | Caminho de origem relativo ao padrão correspondido. |
| `{basename}` | Nome do arquivo de origem sem a extensão. |
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

Os valores da regra substituem os valores herdados do arquivo envolvente.

## Contexto de escopo

O Glossia lê arquivos `L10N.md` da raiz do repositório até o arquivo da origem:

- Configurações do arquivo pai fornecem padrões.
- Um arquivo mais profundo substitui campos para o seu diretório.
- O contexto Markdown é acumulado do arquivo pai para o filho.
- Orientações específicas de locale e um manipulador de modelo específico de locale podem residir em `L10N/<locale>.md`.

Isso permite que um repositório mantenha orientações de voz gerais na raiz, enquanto posiciona orientações específicas de área de produto ou linguagem próximas ao conteúdo que afeta.