%{
  title: "Définir un glossaire",
  summary:
    "Définir les termes dans L10N.md et leurs traductions approuvées dans le fichier de surcharge de chaque langue.",
  category: "Tutoriel",
  section: "translation",
  order: 6
}
---
Votre équipe dispose déjà de termes qui doivent se traduire d'une manière spécifique : noms de produits restant en anglais, termes techniques ayant une représentation préférée, mots de marque ayant une tonalité particulière. Déclarez-les dans votre dépôt et Glossia les appliquera à chaque traduction future.

Un glossaire réside dans deux types de fichiers que vous utilisez déjà :

- `L10N.md` déclare les **termes** : ce que le mot est et ce qu'il signifie. C'est le même pour toutes les langues.
- `L10N/<locale>.md` déclare les **traductions** pour une langue. Chaque réviseur de langue possède son propre fichier.

Si votre compte a également un glossaire dans Glossia, les deux sont fusionnés au moment de la traduction. Voir [Glossaire](/docs/explanation/glossary) pour les règles et pour [quand utiliser lequel](/docs/explanation/glossary#when-to-use-which).

## 1\. Déclarez les termes dans L10N.md

Ajoutez une liste `glossary` dans l'entête de métadonnées (frontmatter) de votre fichier `L10N.md` racine :

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

Chaque terme nécessite une `source`, le mot tel qu'il apparaît dans votre texte. Une `definition` aide le modèle à décider si un retour est bien le concept que vous signifiez. `case_sensitive: true` fait que `API` correspond sans correspondre "api" en prose.

## 2\. Traduisez-les dans le fichier de chaque langue

Créez ou ouvrez `L10N/<locale>.md` à côté de votre `L10N.md` et mappez chaque terme vers sa traduction approuvée :

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

Les clés sont la `source` du terme. Une langue sans traduction pour un terme tombe par défaut sur le glossaire du compte, ou laisse le modèle choisir.

## 3\. Ajoutez un terme dont une langue seule a besoin

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

## 4\. Donnez un terme un identifiant stable

Lorsque le même mot nécessite une signification précise, ou que vous souhaitez changer ultérieurement la `source` d'un terme, donnez-lui un `id` et clésez ses traductions par cet id :

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

Un `L10N.md` ou un `L10N/<locale>.md` imbriqués héritent de ses dossiers parents et peuvent ajouter ou remplacer des entrées pour son sous-arbre :

```yaml
# marketing/L10N/es.md
---
locale: es
glossary:
  commit: compromiso
---
```

Les fichiers西班牙语 dans `marketing/` traduisent "commit" comme `compromiso` ; le reste du dépôt conserve `commit`.

## 6\. Validez et poussez

Validez le changement et poussez-le. Au prochain cycle de traduction, Glossia ne re-traite que les fichiers utilisant les termes que vous avez ajoutés ou modifiés, dans les langues dont les traductions ont changé. Les fichiers qui ne contiennent pas ces termes conservent leurs traductions existantes.

Si un glossaire contient une erreur, Glossia ignore le glossaire du dépôt pour les fichiers concernés et n'utilise que le glossaire du compte, alors vérifiez les [règles de validation](/docs/reference/glossary#validation) quand un terme ne semble pas s'appliquer.

## Voir également

- [Référence Glossaire](/docs/reference/glossary) : tous les champs et règles de validation.
- [Glossaire](/docs/explanation/glossary) : comment les glossaires du dépôt et du compte se combinent.
- [Référence L10N.md](/docs/reference/l10n-md) : les autres champs d'entête.