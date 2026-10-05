%{
  title: "L10N.md",
  summary: "Referência para configurações de tradução do repositório e contexto.",
  category: "Referência",
  section: "translation",
  order: 1
}
---
`L10N.md`indica à Glossia quais arquivos traduzir, para onde os arquivos traduzidos pertencem, quais idiomas alvejar e que contexto deve guiar o resultado. Um repositório pode ter um arquivo raiz e arquivos escopados adicionais em subdiretórios.

## Estrutura

Cada arquivo tem duas partes:

1. [YAML Ain't Markup Language](https://yaml.org/)frontmatter entre`---`marcadores.
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

As credenciais do provedor pertencem nas configurações da conta, nunca em`L10N.md`. O valor opcional`model` é um identificador de modelo de conta.

## Campos do frontmatter

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `source_language` | string | não | Locale de origem para este escopo. Padrão para`en`. |
| `model` | string | não | Identificador de modelo de conta. A Glossia usa o padrão da conta se omisso e relata um erro se um identificador explícito não existe. |
| `sources` | mapa ou lista | para uma regra de nível superior | Modelos de padrões de arquivo de origem. Valores de mapa podem definir templates de saída. |
| `targets` | mapa ou lista | quando fontes estiverem configuradas | Códigos de idiomas de destino. Um mapa pode associar um código de idioma a um nome de idioma. |
| `output` | string | quando não há mapeamento de origem ou`target_path` fornece um destino | Template de arquivo de saída. |
| `target_path` | string | quando não há mapeamento de origem ou`output` fornece um destino | Template de diretório base para arquivos traduzidos. |
| `translate` | lista | não | Múltiplas regras de tradução, cada uma com suas próprias fontes e sobrescrições opcionais. |
| `exclude` | lista | não | Modelos de arquivos a ignorar. |
| `preserve` | lista | não | Tipos de conteúdo que devem permanecer inalterados, como placeholders ou uniform resource locators. |
| `frontmatter` | string | não | `preserve` por padrão, ou`translate`. |
| `prompt` | string | não | Orientação adicional para este escopo ou regra. |
| `validation` | lista | para extensões de arquivo sem adaptador interno | Um comando de validação seguido de seus argumentos. O comando recebe o candidato em seu caminho de destino real e deve retornar um status diferente de zero quando o arquivo é inválido. |
| `check_cmd` | string | não | Um comando de validação disponível para o fluxo de trabalho de tradução. |
| `check_cmds` | mapa | não | Comandos de validação com nome disponíveis para o fluxo de trabalho de tradução. |
| `retries` | inteiro | não | Número de tentativas de repetição após um falho de verificação. Padrão para`2`. |
| `locale` | string | não | Locale anexado a um arquivo de contexto específico de locale. |
| `glossary` | lista ou mapa | não | Em `L10N.md`, uma lista de termos de glossário. Em `L10N/<locale>.md`, um mapa de cada termo para sua tradução nesse idioma. Arquivos aninhados adicionam e substituem as entradas herdadas. Veja o [referência de glossário](/docs/reference/glossary). |

Campos desconhecidos do frontmatter são ignorados.

## Formatos de arquivo

A Glossia possui tratamento nativo para Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable object e arquivos de texto simples. Outras extensões de arquivo falham o planejamento a menos que o `L10N.md` declarada um `validation` comando. Isso evita silenciosamente tratar um formato estruturado proprietário como texto sem restrições.

O comando de validação executa após o candidato foi escrito temporariamente ao seu caminho de destino real. Ele pode invocar o parser nativo, compilador ou comando de construção do repositório. A Glossia restaura o alvo anterior após cada tentativa de validação e escreve apenas o candidato aceito em seguida.

## Mapeamentos de origem

A forma mais clara mapeia cada padrão de origem para um template de saída:

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

## Idiomas alvos

Uma lista usa cada código de localização como seu identificador de idioma:

```yaml
targets:
  - es
  - ja
```

Um mapa pode adicionar um nome legível do idioma:

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variáveis de saída

| Variável | Valor |
|---|---|
| `{locale}` ou `{lang}` | Código do idioma do local alvo. |
| `{relpath}` | Caminho da fonte relativo ao padrão correspondente. |
| `{basename}` | Nome do arquivo de fonte sem sua extensão. |
| `{ext}` | Extensão do arquivo de fonte sem o ponto inicial. |

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

Os valores da regra substituem os valores herdados do arquivo circundante.

## Contexto escopo

O Glossia lê arquivos `L10N.md` a partir da raiz do repositório até o arquivo de origem:

- Configurações do pai fornecem padrões.
- Arquivos mais profundos sobrescrevem campos para seu diretório.
- O contexto do Markdown é acumulado do pai para o filho.
- Orientações específicas do idioma e um manipulador de modelo específico do local podem residir em `L10N/<locale>.md`.

Isso permite que um repositório mantenha orientações abrangentes de voz na raiz enquanto posiciona orientações específicas da área de produto ou do idioma próximas ao conteúdo que afetam.