%{
  title: "L10N.md",
  summary: "Referência para configurações de tradução do repositório e contexto.",
  category: "referência",
  section: "translation",
  order: 1
}
---

`L10N.md` diz ao Glossia quais arquivos traduzir, onde os arquivos traduzidos pertencem, para quais idiomas e qual contexto deve guiar o resultado. Um repositório pode ter um arquivo raiz e arquivos adicionais escopados em subdiretórios.

## Estrutura

Cada arquivo tem duas partes:

1. [YAML não é uma linguagem de marcação](https://yaml.org/) frontmatter entre `---` marcadores.
2. Markdown abaixo do frontmatter com contexto de produto, público-alvo, voz ou domínio.

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

Credenciais do provedor pertencem nas configurações de conta, nunca em `L10N.md`. O valor opcional `model` é um identificador de modelo de conta.

## Campos do frontmatter

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `source_language` | string | no | Localidade de origem para este escopo. Padrão para `en`. |
| `model` | string | no | Identificador de modelo de conta. O Glossia usa o padrão da conta quando omitido e relata um erro quando um identificador explícito não existe. |
| `sources` | mapa ou lista | para uma regra de nível superior | Padrões de arquivo de origem. Valores de mapa podem definir modelos de saída. |
| `targets` | mapa ou lista | quando as fontes estão configuradas | Códigos de localidade-alvo. Um mapa pode associar um código de localidade a um nome de idioma. |
| `output` | string | quando não há mapeamento de fonte ou `target_path` fornece um destino | Modelo de arquivo de saída. |
| `target_path` | string | quando não há mapeamento de fonte ou `output` fornece um destino | Modelo de diretório base para arquivos traduzidos. |
| `translate` | lista | no | Regras de tradução múltiplas, cada uma com suas próprias fontes e opções de sobrescrita. |
| `exclude` | lista | no | Padrões de arquivo para ignorar. |
| `preserve` | lista | no | Tipos de conteúdo que devem permanecer inalterados, como placeholders ou uniform resource locators. |
| `frontmatter` | string | no | `preserve` por padrão, ou `translate`. |
| `prompt` | string | no | Orientações adicionais para este escopo ou regra. |
| `validation` | lista | para extensões de arquivo sem um adaptador embutido | Um comando de validação seguido de seus argumentos. O comando recebe o candidato em seu caminho-alvo real e deve retornar um status diferente de zero quando o arquivo é inválido. |
| `check_cmd` | string | no | Um comando de verificação disponível para o fluxo de trabalho de tradução. |
| `check_cmds` | mapa | no | Comandos de verificação nominais disponíveis para o fluxo de trabalho de tradução. |
| `retries` | inteiro | no | Número de tentativas de reexecução após uma falha. Padrão para `2`. |
| `locale` | string | no | Localidade anexada a um arquivo de contexto específico para localidade. |
| `glossary` | lista ou mapa | no | Em `L10N.md`, uma lista de termos do glossário. Em `L10N/<locale>.md`, um mapeamento de cada termo para sua tradução naquele idioma. Arquivos aninhados adicionam às entradas herdadas e as sobrescrevem. Veja a [referência do glossário](/docs/reference/glossary). |

Campos desconhecidos do frontmatter são ignorados.

## Formatos de arquivo

O Glossia possui tratamento embutido para Markdown, JavaScript Object Notation, YAML não é uma linguagem de marcação, objeto portátil e arquivos de texto puro. Outras extensões de arquivo falham no planejamento a menos que o aplicável `L10N.md` declare um comando `validation`. Isso evita tratar silenciosamente um formato estruturado proprietário como texto não restrito.

Em Markdown, apenas o texto corrido é traduzido: parágrafos, cabeçalhos, itens de lista, células de tabela, os atributos `title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, e `caption` dos componentes e HTML, e o texto de um HTML `<summary>`. Todo outro byte, incluindo código, destinos de link, componentes, alertas e âncoras de cabeçalho explícitas, é mantido exatamente como na fonte. Veja [recuperação de tradução](/docs/explanation/translation-recovery) para entender como isso funciona.

O comando de validação é executado após o candidato ser escrito temporariamente para seu caminho-alvo real. Ele pode invocar o analisador nativo, compilador ou comando de build do repositório. O Glossia restaura o alvo anterior após cada tentativa de validação e escreve apenas o candidato aceito em seguida.

## Mapeamentos de origem

A forma mais clara mapeia cada padrão de origem para um modelo de saída:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Uma lista de origem também é válida, mas precisa verificar `output` ou `target_path` para definir o destino:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Idiomas-alvo

Uma lista usa cada código de localidade como seu identificador de idioma:

```yaml
targets:
  - es
  - ja
```

Um mapa pode adicionar um nome de linguagem legível:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variáveis de saída

| Variável | Valor |
|---|---|
| `{locale}` ou `{lang}` | Código de localidade-alvo. |
| `{relpath}` | Caminho de origem relativo ao padrão correspondido. |
| `{basename}` | Nome do arquivo de origem sem a extensão. |
| `{ext}` | Extensão do arquivo de origem sem o ponto inicial. |

## Regras múltiplas

Use `translate` quando grupos de conteúdo diferentes precisam de destinos ou verificações distintas:

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

## Contexto com alcance

O Glossia lê arquivos `L10N.md` a partir da raiz do repositório até o arquivo de origem:

- As configurações do escopo mais amplo fornecem valores padrão.
- Arquivos mais profundos substituem campo para o seu diretório.
- O contexto do Markdown é acumulado do pai para o filho.
- Orientações específicas para localidade e um identificador de modelo específico para localidade podem residir em `L10N/<locale>.md`.

Isso permite a um repositório manter orientações de voz abrangentes na raiz enquanto posiciona orientações específicas de área de produto ou locaisidade próximas ao conteúdo que afeta.
