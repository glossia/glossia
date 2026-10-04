%{
  title: "Glossary",
  summary:
    "Référence pour le champ du glossaire dans L10N.md et dans le fichier de surcharge de chaque langue.",
  category: "référence",
  section: "translation",
  order: 2
}
---
Un glossaire de dépôt est réparti sur deux fichiers. Glossia le fusionne avec le glossaire du compte pour chaque fichier qu'il traduit. Voir [Glossaire](/docs/explanation/glossary) comment les deux se combinent.

| Fichier | `glossary` contient | Exemple |
|---|---|---|
| `L10N.md` | Liste de **termes**, c'est la même chose pour chaque langue. | `- source: commit` |
| `L10N/<locale>.md` | Une correspondance d'un terme à sa **traduction** dans cette langue. | `commit: commit` |

## Termes dans L10N.md

```yaml
---
glossary:
  - source: commit
    definition: The version-control action of recording changes.
  - source: API
    case_sensitive: true
  - id: vcs-branch
    source: branch
    definition: A line of development in version control.
---
```

| Champ | Type | Requis | Description |
|---|---|---|---|
| `source` | string | oui | Le terme tel qu'il apparaît dans le texte source. |
| `definition` | string | non | Conseil court que le modèle lit pour décider si une correspondance est vraiment ce concept. |
| `case_sensitive` | boolean | no | Quand `true`, le terme ne correspond que dans la casse exacte. Par défaut `false`. Utilisez-le pour les noms et les acronymes tels que `API` ou `SDK`. |
| `id` | string | no | Identifiant stable. Dérivé de `source` quand omis (`Version Control` devient `version-control`, `C++` devient `cplusplus`) . Définissez-le aux traductions clés par ID, pour renommer `source` sans perdre l'identité du terme, ou pour surclasser un terme parent `L10N.md`. |

Les termes ne contiennent pas de traductions. Un terme avec un `targets` champ est rejeté : les traductions appartiennent aux fichiers de langue.

## Traductions dans L10N/<locale>.md

```yaml
# L10N/es.md
---
locale: es
glossary:
  commit: commit
  API: API
  vcs-branch: rama
  pull request: pull request
---
```

Chaque clé est celle d'un terme `id` ou son `source`, et chaque valeur est la traduction approuvée pour cette langue.

- Une clé qui ne correspond à aucun terme dans `L10N.md` définit un terme exclusivement pour cette langue.
- Un terme sans traduction dans une langue renvoie au glossaire de compte pour cette langue.
- Pour garder un nom non traduit, mappez-le sur lui-même, par exemple `Glossia: Glossia`.

## Fichiers imbriqués

Chaque fichier est traduit avec le glossaire de sa chaîne de répertoires :

- Un fichier imbriqué `L10N.md` ajoute des termes à ceux qu'il hérite. Un terme avec le même `id`, ou le même `source` quand aucun `id` est défini, remplace celui hérité pour ce sous-arbre.
- Un glossaire imbriqué `L10N/<locale>.md` ajoute des traductions à celles qu'il hérite, et sa traduction l'emporte pour un terme déclaré par les deux.

## Vérification

Si un glossaire est invalide, Glossia traduit les fichiers affectés uniquement avec le glossaire de compte, de sorte qu'une coquille ne bloque jamais les traductions. Causes courantes:

- **Manquant `source`.** Chaque terme doit avoir une valeur non vide.
- **Dupliquer `id`.** Chaque terme doit se résoudre en un identifiant unique, qu'il soit défini explicitement ou dérivé de `source`.
- **Traductions dans L10N.md.** Un terme avec `targets`. Déplacer les traductions vers `L10N/<locale>.md`.
- **Traduction vide.** Un terme associé à une chaîne vide. Omettez-le plutôt.
- **Formes ou types incorrects.** `glossary` doit être une liste dans `L10N.md` et un objet dans `L10N/<locale>.md`. Traductions, `id`, et `definition` doivent être des chaînes; `case_sensitive` doit être `true` ou `false`.

## Ce que Glossia enregistre

Le fichier de verrouillage de chaque fichier traduit enregistre les entrées du glossaire qui l'ont façonné :

```json
{
  "server_context": {
    "glossary": {
      "applied": ["repo:commit", "account:repository"],
      "shadowed": ["account:commit"]
    }
  }
}
```

- `applied` liste les entrées qui ont correspondu au fichier. Les entrées du dépôt apparaissent comme `repo:<id>`, les entrées du compte comme `account:<id>`.
- `shadowed` liste les entrées de compte remplacées par une entrée de référentiel pour ce fichier.

La modification d'un terme ou d'une traduction ne retraduit que les fichiers qui l'utilistent.

## Voir aussi

- [Définir un glossaire](/docs/how-to/define-a-glossary): guide étape par étape.
- [Glossaire](/docs/explanation/glossary): comment les glossaires de référentiel et de compte se combinent.
- [L10N.md référence](/docs/reference/l10n-md): les autres champs frontmatter.