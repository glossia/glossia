%{
  title: "Defina um glossário",
  summary:
    "Declare os termos em L10N.md e suas traduções aprovadas em cada arquivo de sobreposição de idioma.",
  category: "Como fazer",
  section: "Tradução",
  order: 6
}
---
Sua equipe já tem termos que precisam ser traduzidos de forma específica: nomes de produtos que permanecem em inglês, termos técnicos com uma renderização preferencial, palavras de marca que carregam um tom específico. Declare-os no seu repositório e o Glossia aplica-os a todas as futuras traduções.

Um glossário reside em dois tipos de arquivos que você já usa:

- `L10N.md` declara os **termos**: o que é a palavra e o que ela significa. Isso é o mesmo para cada idioma.
- `L10N/<locale>.md` declara as **traduções** para um idioma. Os revisores de cada idioma são donos do próprio arquivo.

Se sua conta também tiver um glossário no servidor, os dois são mesclados no momento da tradução. Veja [Glossário](/docs/explanation/glossary) para as regras e para [quando usar qual](/docs/explanation/glossary#when-to-use-which).

## 1\. Declare os termos em L10N.md

Adicione uma lista `glossary` ao frontmatter do `L10N.md` raiz:

```yaml
---
source_language: en
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
glossary:
  - source: commit
    definition: The version-control action of recording changes.
  - source: API
    case_sensitive: true
---

Write for software developers.
```

Cada termo precisa de um `source`, a palavra conforme aparece no seu texto. Uma `definition` ajuda o modelo a decidir se uma coincidência é realmente o conceito que você pretende. `case_sensitive: true` faz com que `API` corresponda sem corresponder a "api" no texto corrido.

## 2\. Traduzi-los no arquivo de cada idioma

Crie ou abra `L10N/<locale>.md` ao lado do seu `L10N.md` e mapeie cada termo à sua tradução aprovada:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  API: API
---
```

```yaml
# L10N/ja.md
---
locale: ja
glossary:
  commit: コミット
  API: API
---
```

As chaves são o `source` do termo. Um idioma sem tradução para um termo cai para o glossário do servidor, ou permite que o modelo escolha.

## 3\. Adicionar um termo que apenas um idioma precisa

Um arquivo de idioma pode traduzir uma palavra que `L10N.md` não declara. A regra então se aplica apenas a esse idioma:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. Atribuir um ID estável a um termo

Quando a mesma palavra precisa de um significado preciso, ou você deseja renomear o `source` de um termo posteriormente, dê a ela um `id` e chaves suas traduções por esse id:

```yaml
# L10N.md
glossary:
  - id: vcs-branch
    source: branch
    definition: A line of development in version control, not a company branch office.
```

```yaml
# L10N/es.md
glossary:
  vcs-branch: rama
```

## 5\. Refinar o glossário para parte do repositório

Um `L10N.md` ou `L10N/<locale>.md` aninhado herda de seus diretórios pais e pode adicionar ou sobrescrever entradas para sua subárvore:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Arquivos em espanhol em `marketing/` traduzem "commit" como `compromiso`; o restante do repositório mantém `commit`.

## 6\. Fazer commit e push

Faça commit à mudança e push. Na próxima execução da tradução, o Glossia retraduz apenas os arquivos que usam os termos que você adicionou ou alterou, nos idiomas cujas traduções mudaram. Arquivos que não contêm esses termos mantêm suas traduções existentes.

Se um glossário tiver um erro, o Glossia ignora o glossário do repositório para os arquivos afetados e usa apenas o glossário do servidor, portanto verifique as [regras de validação](/docs/reference/glossary#validation) quando um termo não parecer se aplicar.

## Veja também

- [Glossário](/docs/reference/glossary): todos os campos e regras de validação.
- [Glossário](/docs/explanation/glossary): como os glossários do repositório e do servidor são combinados.
- [Referência do L10N.md](/docs/reference/l10n-md): os outros campos do frontmatter.