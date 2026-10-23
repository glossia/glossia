%{
  title: "Defina um glossário",
  summary:
    "Declare os termos em L10N.md e suas traduções aprovadas no arquivo de sobreescrita de cada idioma.",
  category: "Tutorial",
  section: "translation",
  order: 6
}
---

Sua equipe já tem termos que devem ser traduzidos de uma maneira específica: nomes de produtos que permanecem em inglês, termos técnicos com uma renderização preferida e palavras de marca que carregam um tom específico. Declare-os no seu repositório e o Glossia os aplicará a todas as traduções futuras.

Um glossário existe em dois tipos de arquivos que você já usa:

- `L10N.md` declara os **termos**: o que a palavra é e o que significa. Isso é o mesmo para todas as línguas.
- `L10N/<locale>.md` declara as **traduções** para uma língua. Os revisores de cada língua cuidam do seu próprio arquivo.

Se sua conta também tiver um glossário no Glossia, os dois são fundidos no momento da tradução. Consulte [Glossário](/docs/explanation/glossary) para as regras e para [quando usar qual](/docs/explanation/glossary#when-to-use-which).

## 1. Declare os termos em L10N.md

Adicione uma `glossary` lista ao frontmatter do seu `L10N.md` principal:

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

Cada termo precisa de um `source`, a palavra conforme ela aparece no seu texto. Um `definition` ajuda o modelo a decidir se uma correspondência é realmente o conceito que você deseja. O `case_sensitive: true` faz o `API` corresponder sem corresponder a "api" no texto.

## 2. Traduza-os em cada arquivo de língua:

Crie ou abra `L10N/<locale>.md` ao lado do seu `L10N.md` e mapeie cada termo para a tradução aprovada:

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

As chaves são o `source` do termo. Uma língua sem tradução para um termo fecha para o glossário da conta, ou deixa o modelo escolher.

## 3. Adicione um termo necessário apenas para uma língua:

Um arquivo de língua pode traduzir uma palavra que `L10N.md` não declara. A regra então aplica-se apenas a essa língua:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. Dê a um termo um id estável:

Quando a mesma palavra precisa de um significado preciso, ou você deseja renomear o `source` de um termo mais tarde, dê a ela um `id` e use esse id como chave para as traduções:

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

## 5. Refine o glossário para parte do repositório:

Um `L10N.md` ou `L10N/<locale>.md` aninhado herda de seus diretórios pai e pode adicionar ou sobrescrever entradas para sua subárvore:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Os arquivos espanhóis abaixo de `marketing/` traduzem "commit" como `compromiso`; o restante do repositório mantém `commit`.

## 6. Commit e push

Faça o commit da mudança e o push. Na próxima execução da tradução, o Glossia retraduz apenas os arquivos que usam os termos que você adicionou ou alterou, nas línguas cujas traduções mudaram. Os arquivos que não contêm esses termos mantêm suas traduções existentes.

Se um glossário tiver um erro, o Glossia ignora o glossário do repositório para os arquivos afetados e usa apenas o glossário da conta, então verifique as [regras de validação](/docs/reference/glossary#validation) quando um termo não parecer se aplicar.

## Ver também

- [Referência do Glossário](/docs/reference/glossary): todos os campos e regras de validação.
- [Glossário](/docs/explanation/glossary): como os glossários do repositório e da conta se combinam.
- [Referência do L10N.md](/docs/reference/l10n-md): os outros campos do frontmatter.
