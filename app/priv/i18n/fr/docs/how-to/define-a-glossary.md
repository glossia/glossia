%{
  title: "Définir un glossaire",
  summary:
    "Déclarez les termes dans L10N.md et leurs traductions approuvées dans le fichier de surcharge de chaque langue.",
  category: "tutoriel",
  section: "translation",
  order: 6
}
---

Votre équipe a déjà des termes qui doivent être traduits de manière spécifique : des noms de produit qui restent en anglais, des termes techniques avec une représentation préférée, des mots de marque qui apportent une tonalité spécifique. Déclarez-les dans votre dépô et Glossia les appliquera à chaque traduction future.

Un glossaire se trouve dans deux types de fichiers que vous utilisez déjà :

- `L10N.md` déclare **les termes** : le mot et sa signification. Cela vaut pour chaque langue.
- `L10N/<locale>.md` déclare **les traductions** pour une langue. Les réviseurs de chaque langue possèdent leur propre fichier.

Si votre compte a aussi un glossaire dans Glossia, les deux sont fusionnés au moment de la traduction. Voir [Glossaire](/docs/explanation/glossary) pour les règles et pour [quand utiliser l'un ou l'autre](/docs/explanation/glossary#when-to-use-which).

## 1. Déclarez les termes dans L10N.md

Ajoutez une liste `glossary` dans le frontmatter de votre fichier `L10N.md` racine :

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

Chaque terme nécessite un `source`, le mot tel qu'il apparaît dans votre texte. Un `definition` aide le modèle à décider si une correspondance correspond vraiment au concept que vous visez. `case_sensitive: true` rend `API` correspondre sans correspondre à "api" dans le texte.

## 2. Traduisez-les dans le fichier de chaque langue

Créez ou ouvrez `L10N/<locale>.md` à côté de votre `L10N.md` et associez chaque terme à sa traduction approuvée :

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

Les clés sont `source` du terme. Une langue ne disposant pas de traduction pour un terme utilise le glossaire du compte ou laisse le modèle choisir.

## 3. Ajoutez un terme nécessaire uniquement à une langue

Un fichier de langue peut traduire un mot que `L10N.md` ne déclare pas. La règle s'applique alors uniquement à cette langue :

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. Donnez à un terme un identifiant stable

Lorsque le même mot a besoin d'une signification précise, ou lorsque vous souhaitez renommer la `source` d'un terme plus tard, donnez-lui un `id` et associez ses traductions à cet id :

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

## 5. Affinez le glossaire pour une partie du dépôt

Un fichier `L10N.md` imbriqué ou un `L10N/<locale>.md` hérite des dossiers parents et peut ajouter ou surcharger les entrées pour son sous-dossier :

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Les fichiers espagnols sous `marketing/` traduisent "commit" en `compromiso` ; le reste du dépôt garde `commit`.

## 6. Validez et poussez

Validez le changement et poussez. Lors de la prochaine exécution de traduction, Glossia rétraduit uniquement les fichiers qui utilisent les termes que vous avez ajoutés ou modifiés, dans les langues dont les traductions ont changé. Les fichiers qui ne contiennent pas ces termes conservent leurs traductions existantes.

Si un glossaire contient une erreur, Glossia ignore le glossaire du dépôt pour les fichiers concernés et n'utilise que le glossaire du compte, donc vérifiez les [règles de validation](/docs/reference/glossary#validation) lorsqu'un terme ne semble pas s'appliquer.

## Voir aussi

- [Référence de glossaire](/docs/reference/glossary) : tous les champs et règles de validation.
- [Glossaire](/docs/explanation/glossary) : comment les glossaires de dépôt et de compte se combinent.
- [référence L10N.md](/docs/reference/l10n-md) : les autres champs du frontmatter.
