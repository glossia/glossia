%{
  title: "Définir un glossaire",
  summary:
    "Définir les termes dans L10N.md et leurs traductions approuvées dans le fichier de surcharge de chaque langue.",
  category: "Tutoriel",
  section: "translation",
  order: 6
}
---
Votre équipe possède déjà des termes qui doivent être traduits d'une manière spécifique : noms de produits qui restent en anglais, termes techniques avec une représentation préférée, mots de marque qui portent un ton précis. Déclarez-les dans votre dépôt et Glossia les appliquera à chaque traduction future.

Un glossaire réside dans deux types de fichiers que vous utilisez déjà :

- `L10N.md` déclare les **termes** : ce que signifie le mot et ce qu'il veut dire. Cela est le même pour chaque langue.
- `L10N/<locale>.md` déclare les **traductions** pour une langue. Les réviseurs de chaque langue gèrent leur propre fichier.

Si votre compte possède également un glossaire dans Glossia, les deux sont fusionnés au moment de la traduction. Voir [Glossaire](/docs/explanation/glossary) pour les règles et pour [quand utiliser laquelle](/docs/explanation/glossary#when-to-use-which).

## 1\. Déclarez les termes dans L10N.md

Ajoutez une `glossary` list à la frontmatter de votre `L10N.md` racine :

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

Chaque terme nécessite un `source`, le mot tel qu'il apparaît dans votre texte. Un `definition` aide le modèle à décider si une correspondance est vraiment le concept que vous entendez. `case_sensitive: true` fait en sorte que `API` corresponde sans correspondre "api" en prose.

## 2\. Traduisez-les dans le fichier de chaque langue

Créez ou ouvrez `L10N/<locale>.md` à côté de votre `L10N.md` et mappez chaque terme à sa traduction approuvée :

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

Les clés sont le `source` du terme. Une langue sans traduction pour un terme se rabatte sur le glossaire du compte, ou laisse le modèle choisir.

## 3\. Ajoutez un terme nécessaire à une seule langue

Un fichier de langue peut traduire un mot que `L10N.md` ne déclare pas. La s'applique alors uniquement à cette langue :

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. Attribuez un identifiant stable à un terme

Quand le même mot a besoin d'une signification précise, ou que vous voulez renommer le `source` d'un terme plus tard, donnez-lui un `id` et並以 cet identifiant\`.

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

## 5\. Affinez le glossaire pour une partie du dépôt

Un `L10N.md` imbriqué ou `L10N/<locale>.md` hérite de ses dossiers parents et peut ajouter ou override les entrées pour son sous-arbre :

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Les fichiers espagnols sous `marketing/` traduisent "commit" en `compromiso`; le reste du dépôt garde `commit`.

## 6\. Commitez les modifications et poussez

Commitez le changement et poussez. Au prochain cycle de traduction, Glossia ne rétraduit que les fichiers qui utilisent les termes que vous avez ajoutés ou modifiés, dans les langues dont les traductions ont changé. Les fichiers qui ne contiennent pas ces termes conservent leurs traductions existantes.

Si un glossaire contient une erreur, Glossia ignore le glossaire du dépôt pour les fichiers concernés et n'utilise que le glossaire du compte, donc [vérifiez les règles de validation](/docs/reference/glossary#validation) quand un terme semble ne pas s'appliquer.

## Voir aussi

- [Glossaire de référence](/docs/reference/glossary) : chaque champ et règle de validation.
- [Glossaire](/docs/explanation/glossary) : kombinés glossaire dépôt et compte.
- [L10N.md référence](/docs/reference/l10n-md) : les autres champs frontmatter.