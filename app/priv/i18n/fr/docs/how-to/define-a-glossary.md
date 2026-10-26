%{
  title: "Définir un glossaire",
  summary:
    "Déclarer les termes dans L10N.md et leurs traductions approuvées dans le fichier de remplacement de chaque langue.",
  category: "Guide",
  section: "translation",
  order: 6
}
---

Votre équipe dispose déjà de termes qui doivent être traduits d'une manière spécifique : des noms de produits qui restent en anglais, des termes techniques avec un rendu privilégié, des mots de marque qui portent une tonalité spécifique. Déclarez-les dans votre dépôt et Glossia les applique à chaque future traduction.

Un glossaire réside dans deux types de fichiers que vous utilisez déjà :

- `L10N.md` définit **termes** : ce que le mot est et ce qu'il signifie. C'est le même pour chaque langue.
- `L10N/<locale>.md` définit **traductions** pour une langue. Les réviseurs de chaque langue possèdent leur propre fichier.

Si votre compte dispose également d'un glossaire dans Glossia, les deux sont fusionnés lors de la traduction. Voir [Glossaire](/docs/explanation/glossary) pour les règles et pour [quand utiliser quoi](/docs/explanation/glossary#when-to-use-which).

## 1. Déclarez les termes dans L10N.md

Ajoutez une liste `glossary` dans le frontmatter de votre fichier racine `L10N.md` :

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

Chaque terme a besoin d'un `source`, le mot tel qu'il apparaît dans votre texte. Un `definition` aide le modèle à décider si une correspondance est vraiment le concept que vous entendez. `case_sensitive: true` fait en sorte que `API` corresponde sans correspondre « api » dans le texte.

## 2. Traduisez-les dans le fichier de chaque langue

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

Les clés sont le `source` du terme. Une langue qui n'a pas de traduction pour un terme recourt au glossaire de compte ou laisse le modèle choisir.

## 3. Ajoutez un terme dont une seule langue a besoin

Un fichier de langue peut traduire un mot que `L10N.md` ne déclare pas. La règle s'applique alors à cette langue seulement :

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  pull request: pull request
---
```

## 4. Attribuez une clé stable à un terme

Quand un même mot a besoin d'un sens précis, ou vous voulez renommer le `source` d'un terme plus tard, donnez-lui un `id` et cloutez ses traductions avec cet id :

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

Un `L10N.md` imbriqué ou `L10N/<locale>.md` hérite de ses répertoires parents et peut ajouter ou remplacer des entrées pour sa sous-arbre :

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Les fichiers espagnols sous `marketing/` traduisent « commit » comme `compromiso` ; le reste du référentiel garde `commit`.

## 6. Commitez et poussez

Commitez le changement et poussez. Lors du prochain cycle de traduction, Glossia rétraduit uniquement les fichiers utilisant les termes que vous avez ajoutés ou modifiés, dans les langues dont les traductions ont changé. Les fichiers ne contenant pas ces termes conservent leurs traductions existantes.

Si un glossaire contient une erreur, Glossia ignore le glossaire du dépôt pour les fichiers concernés et n'utilise que le glossaire du compte, vérifiez donc les [règles de validation](/docs/reference/glossary#validation) lorsqu'un terme ne semble pas s'appliquer.

## Voir également

- [Référence Glossaire](/docs/reference/glossary) : tous les champs et règles de validation.
- [Glossaire](/docs/explanation/glossary) : comment les glossaires du dépôt et du compte se combinent.
- [Référence L10N.md](/docs/reference/l10n-md) : les autres champs frontmatter.
