%{
  title: "Defina um glossário",
  summary:
    "Declare os termos em L10N.md e suas traduções aprovadas em cada arquivo de override do idioma.",
  category: "Tutoriais",
  section: "translation",
  order: 6
}
---
Sua equipe já possui termos que devem ser traduzidos de uma maneira específica: nomes de produtos que permanecem em inglês, termos técnicos com uma renderização preferida e palavras de marca que carregam um tom específico. Declare-os no seu repositório e o Glossia os aplicará a todas as futuras traduções.

Um glossário vive em dois tipos de arquivos que você já usa:

- `L10N.md` declara os **termos**: a palavra e o que ela significa. Isso é o mesmo para todos os idiomas.
- `L10N/<locale>.md` declara as **traduções** para um idioma. Os revisores de cada idioma são responsáveis por seu próprio arquivo.

Se sua conta também possui um glossário no Glossia, os dois são mesclados no momento da tradução. Veja [Glossary](/docs/explanation/glossary) para as regras e para [quando usar cada um](/docs/explanation/glossary#when-to-use-which).

## 1\. Declare the terms in L10N.md

Adicione uma lista `glossary` ao frontmatter da sua `L10N.md` raiz:

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

Cada termo precisa de uma `source`, a palavra conforme ela aparece no seu texto. Uma `definition` ajuda o modelo a decidir se uma correspondência é realmente o conceito que você tem em mente. `case_sensitive: true` faz com que `API` seja considerado uma correspondência sem concordar com "api" no texto corrido.

## 2\. Translate them in each language's file

Crie ou abra `L10N/<locale>.md` ao lado do seu `L10N.md` e mapeie cada termo para sua tradução aprovada:

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

As chaves são a `source` do termo. Se um idioma não tem tradução para um termo específico, ele ressoa para o glossário da conta ou deixa o modelo escolher.

## 3\. Add a term that only one language needs

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

## 4\. Give a term a stable id

Quando a mesma palavra precisa de um significado preciso, ou você deseja renomear a `source` de um termo posteriormente, atribua um `id` e chaveie suas traduções por esse id:

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

## 5\. Refine the glossary for part of the repository

Um `L10N.md` ou `L10N/<locale>.md` aninhado herda dos diretórios pai e pode adicionar ou sobrescrever entradas para sua subárvore:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Arquivos espanhóis sob `marketing/` traduzem "commit" como `compromiso`; o restante do repositório mantém `commit`.

## 6\. Commit and push

Faça o commit da alteração e empurre. Na próxima execução de tradução, o Glossia re-translation apenas os arquivos que usam os termos que você adicionou ou alterou, nos idiomas cujas traduções mudaram. Arquivos que não contêm esses termos mantêm suas traduções existentes.

Se um glossário tem um erro, o Glossia ignora o glossário do repositório para os arquivos afetados e usa apenas o glossário da conta, então verifique as [regras de validação](/docs/reference/glossary#validation) quando um termo não parece se aplicar.

## See also

- [Glossary reference](/docs/reference/glossary): todos os campos e regras de validação.
- [Glossary](/docs/explanation/glossary): como os glossários do repositório e da conta se combinam.
- [L10N.md reference](/docs/reference/l10n-md): os outros campos de frontmatter.