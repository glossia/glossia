%{
  title: "Définir un glossaire",
  summary:
    "Déclarez les termes dans L10N.md et leurs traductions approuvées dans le fichier de surcharge de chaque langue.",
  category: "Guide",
  section: "Traduction",
  order: 6
}
---
Votre équipe dispose déjà de termes qui doivent être traduits d'une manière spécifique : noms de produits qui restent en anglais, termes techniques avec un rendu préféré, mots de marque qui portent une tonalité spécifique. Déclarez-les dans votre dépôt et Glossia les applique à chaque traduction future.

Un glossaire réside dans deux types de fichiers que vous utilisez déjà :

- `L10N.md` **déclare les termes** : ce que le mot est et ce qu'il signifie. C'est le même pour toutes les langues.
- `L10N/<locale>.md` **déclare les traductions** pour une langue. Les relecteurs de chaque langue gèrent leur propre fichier.

Si votre compte dispose également d'un glossaire sur le serveur, les deux sont fusionnés au moment de la traduction. Voir [Glossaire](/docs/explanation/glossary) pour les règles et pour [quand utiliser lequel](/docs/explanation/glossary#when-to-use-which).

## 1\. Déclarez les termes dans L10N.md

Ajoutez une liste `glossary` au frontmatter de votre arbre `L10N.md` :

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

Chaque terme nécessite une valeur `source`, le mot tel qu'il apparaît dans votre texte. Une clé `definition` aide le modèle à décider si l'appariement est réellement le concept que vous visez. `case_sensitive: true` fait en sorte que `API` corresponde sans correspondre à "api" dans le texte.

## 2\. Traduisez-les dans le fichier de chaque langue

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

Les clés sont le `source` du terme. Si une langue n'a pas de traduction pour un terme, elle recourt au glossaire du serveur, ou laisse le modèle choisir.

## 3\. Ajoutez un terme dont seulement une langue a besoin

Un fichier linguistique peut traduire un mot que `L10N.md` ne déclare pas. La règle s'applique alors seulement à cette langue :

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4\. Donnez à un terme un identifiant stable

Lorsque le même mot a besoin d'une signification précise, ou lorsque vous souhaitez renommer la `source` d'un terme plus tard, attribuez-lui un `id` et associez ses traductions par cet id :

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

Un `L10N.md` ou `L10N/<locale>.md` imbriqué hérite des répertoires parents et peut ajouter ou surcharger des éléments pour son sous-arbre :

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Les fichiers espagnols sous `marketing/` traduisent "commit" en `compromiso` ; le reste du dépôt conserve `commit`.

## 6\. Validez et poussez

Validez le changement et poussez. À l'exécution suivante de traduction, Glossia re-traduit uniquement les fichiers qui utilisent les termes que vous avez ajoutés ou modifiés, dans les langues dont les traductions ont changé. Les fichiers ne contenant pas ces termes conservent leurs traductions existantes.

Si un glossaire contient une erreur, Glossia ignore le glossaire du dépôt pour les fichiers concernés et utilise uniquement le glossaire du serveur, donc vérifiez les [règles de validation](/docs/reference/glossary#validation) si un terme ne semble pas s'appliquer.

## Voir aussi

- [Référence du glossaire](/docs/reference/glossary) : chaque champ et règle de validation.
- [Glossaire](/docs/explanation/glossary) : comment les glossaires de dépôt et de serveur se combinent.
- [Référence L10N.md](/docs/reference/l10n-md) : les autres champs frontmatter.