%{
  title: "Defina um glossário",
  summary:
    "Declare os termos em L10N.md e suas traduções aprovadas no arquivo de substituição de cada idioma.",
  category: "passo a passo",
  section: "translation",
  order: 6
}
---

Sua equipe já possui termos que devem ser traduzidos de uma maneira específica: nomes de produtos que permanecem em inglês, termos técnicos com uma renderização preferencial, e palavras de marca que carregam um tom específico. Declare-os no seu repositório e o Glossia os aplicará a todas as traduções futuras.

Um glossário reside em dois tipos de arquivos que você já usa:

- `L10N.md` declara os **termos**: qual é a palavra e o que ela significa. Isso é o mesmo para todas as línguas.
- `L10N/<locale>.md` declara as **traduções** para uma língua. Os revisores de cada língua têm seu próprio arquivo.

Se a sua conta também possui um glossário no Glossia, os dois são mesclados no momento da tradução. Veja o [Glossário](/docs/explanation/glossary) para as regras e para [quando usar qual](/docs/explanation/glossary#when-to-use-which).

## 1. Declare os termos no L10N.md

Adicione uma `glossary` lista ao frontmatter do seu `L10N.md` raiz:

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

Cada termo precisa de um `source`, a palavra conforme aparece no seu texto. Um `definition` ajuda o modelo a decidir se a correspondência é realmente o conceito que você quer. `case_sensitive: true` faz `API` corresponder sem corresponder a "api" na redação.

## 2. Traduza-os no arquivo de cada idioma

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

As chaves são o `source` do termo. Um idioma sem tradução para um termo recorre ao glossário da conta, ou escolhe o modelo.

## 3. Adicione um termo que apenas um idioma precisa

Um arquivo de língua pode traduzir uma palavra que `L10N.md` não declara. A regra então se aplica apenas a essa língua:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. Dê um termo um ID estável

Quando a mesma palavra precisa de um significado preciso, ou você quer renomear o `source` de um termo depois, dê a ele um `id` e use esse ID como chave para suas traduções:

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

## 5. Afinar o glossário para parte do repositório

Um `L10N.md` ou `L10N/<locale>.md` aninhado herda de seus diretórios pai e pode adicionar ou sobrescrever entradas para sua subárvore:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Arquivos em espanhol abaixo de `marketing/` traduzem "commit" como `compromiso`; o resto do repositório mantém `commit`.

## 6. Faça o commit e suba

Faça o commit da alteração e suba. Na próxima execução da tradução, o Glossia retraduz apenas os arquivos que usam os termos que você adicionou ou alterou, nas línguas cujas traduções mudaram. Arquivos que não contêm esses termos mantêm suas traduções existentes.

Se um glossário tem um erro, o Glossia ignora o glossário do repositório para os arquivos afetados e usa apenas o glossário da conta, então verifique as [regras de validação](/docs/reference/glossary#validation) quando um termo não parecer se aplicar.

## Veja também

- [Referência do Glossário](/docs/reference/glossary): cada campo e regra de validação.
- [Glossário](/docs/explanation/glossary): como os glossários do repositório e da conta se combinam.
- [Referência L10N.md](/docs/reference/l10n-md): os outros campos frontmatter.
