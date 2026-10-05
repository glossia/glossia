%{
  title: "Defina um glossário",
  summary:
    "Declare os termos em L10N.md e suas traduções aprovadas em cada arquivo de override do idioma.",
  category: "Tutoriais",
  section: "translation",
  order: 6
}
---
Sua equipe já possui termos que precisam ser traduzidos de maneira específica: nomes de produtos que permanecem em inglês, termos técnicos com renderização preferida e palavras de marca com tom específico. Declare-os no seu repositório e o Glossia os aplicará a todas as traduções futuras.

O glossário reside em dois tipos de arquivos que você já usa:

- `L10N.md` declara os **termos**: a palavra e o que ela significa. Isso é o mesmo para todos os idiomas.
- `L10N/<locale>.md` declara as **traduções** para um idioma. Os revisores de cada idioma são os donos do próprio arquivo.

Se sua conta também tiver um glossário no Glossia, os dois são mesclados no momento da tradução. Veja [Glossary](/docs/explanation/glossary) para as regras e para [quando usar cada um](/docs/explanation/glossary#when-to-use-which).

## 1\. Declare os termos em L10N.md

Adicione uma `glossary` list ao frontmatter do seu `L10N.md` raiz:

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

Cada termo precisa de uma `source`, a palavra como ela aparece no seu texto. Uma `definition` ajuda o modelo a decidir se uma coincidência é realmente o conceito que você quer. `case_sensitive: true` faz com que `API` corresponda sem corresponder a "api" em texto corrido.

## 2\. Traduza-os no arquivo de cada idioma

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

As chaves são a `source` do termo. Um idioma sem tradução para um termo sobe para o glossário da conta ou permite que o modelo escolha.

## 3\. Adicione um termo que apenas um idioma precisa

O arquivo de idioma pode traduzir uma palavra que o `L10N.md` não declara. A regra então se aplica apenas a esse idioma:

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. Dê a um termo um ID estável

Quando a mesma palavra precisa de um significado preciso, ou quiser renomear a `source` de um termo posteriormente, dê a ele um `id` e chaveie suas traduções por esse ID:

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

## 5\. Refine o glossário para parte do repositório

Um `L10N.md` ou `L10N/<locale>.md` aninhado herda de seus diretórios pais e pode adicionar ou sobrescrever entradas para a subárvore:

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Os arquivos espanhóis em `marketing/` traduzem "commit" como `compromiso`; o restante do repositório mantém `commit`.

## 6\. Faça o commit e o push

Faça o commit e o push. Na próxima execução de tradução, o Glossia re-traduz apenas os arquivos que usam os termos que você adicionou ou alterou, nos idiomas cujas traduções mudaram. Arquivos que não contêm esses termos mantêm suas traduções existentes.

Se um glossário tiver um erro, o Glossia ignora o glossário do repositório para os arquivos afetados e usa apenas o glossário da conta, então verifique as [regras de validação](/docs/reference/glossary#validation) quando um termo não parecer se aplicar.

## Veja também

- [Glossary reference](/docs/reference/glossary): todos os campos e regras de validação.
- [Glossary](/docs/explanation/glossary): como os glossários de repositório e conta se combinam.
- [L10N.md reference](/docs/reference/l10n-md): os outros campos do frontmatter.