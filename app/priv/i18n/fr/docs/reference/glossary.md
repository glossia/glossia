%{
  title: "Glossaire",
  summary:
    "Référence pour le champ glossaire dans L10N.md et dans le fichier de surcharge de chaque langue.",
  category: "référence",
  section: "translation",
  order: 2
}
---

Un glossaire de dépôt est réparti sur deux fichiers. Glossia le fusionne avec le glossaire du compte pour chaque fichier traduit. Consultez [Glossaire](/docs/explanation/glossary) pour comprendre comment les deux se combinent.

| Fichier | `glossary` contient | Exemple |
|---|---|---|
| `L10N.md` | Une liste de **termes**, la même pour chaque langue. | `- source: commit` |
| `L10N/<locale>.md` | Une correspondance du terme à sa **traduction** dans cette langue. | `commit: commit` |

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

| Champ | Type | Obligatoire | Description |
|---|---|---|---|
| `source` | texte | oui | Le terme tel qu'il apparaît dans le texte source. |
| `definition` | texte | non | Une brève guidance que le modèle lit pour décider si une correspondance correspond vraiment à ce concept. |
| `case_sensitive` | booléen | non | Lorsque `true`, le terme ne correspond que dans la casse exacte écrite. Par défaut, il est défini sur `false`. Utilisez-le pour les noms et acronymes tels que `API` ou `SDK`. |
| `id` | texte | non | Identifiant stable. Dérivé de `source` s'il est omis (`Version Control` devient `version-control`, `C++` devient `cplusplus`). Assignez-le pour traduire par identifiant, pour renommer `source` sans perdre l'identité du terme, ou pour surcharger un terme d'un parent `L10N.md`. |

Les termes ne contiennent pas de traductions. Un terme possédant un champ `targets` est rejeté : les traductions appartiennent aux fichiers de langue.

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

Chaque clé est le `id` ou sa `source` d'un terme, et chaque valeur est la traduction approuvée pour cette langue.

- Une clé qui ne correspond à aucun terme dans `L10N.md` déclare un terme pour cette langue uniquement.
- Un terme sans traduction dans une langue tombe en arrière vers le glossaire de compte pour cette langue.
- Pour garder un nom sans traduction, mappe-le à luimême, par exemple `Glossia: Glossia`.

## Fichiers imbriqués

Chaque fichier est traduit avec le glossaire de sa chaîne de répertoires:

- Un fichier imbriqué `L10N.md` ajoute des termes à ceux qu'il hérite. Un terme avec le même `id` ou le même `source` lorsqu'aucun `id` n'est défini, remplace celui hérité pour ce sous-arbre.
- Un fichier imbriqué `L10N/<locale>.md` ajoute des traductions à celles qu'il hérite, et sa traduction l'emporte pour un terme qu'ils déclarent tous les deux.

## Validation

Si un glossaire est invalide, Glossia traduit les fichiers affectés avec le glossaire de compte uniquement, de sorte qu'une erreur de frappe n'arrête jamais les traductions. Causes communes:

- **.`source`Manquante** Chaque terme doit avoir une valeur non vide.
- **.`id`Dupliquée** Chaque terme doit résoudre une identité unique, qu'elle soit définie explicitement ou dérivée de `source`.
- **Traductions dans L10N.md.** Un terme possédant un `targets`. Déplacez les traductions vers `L10N/<locale>.md`.
- **Traduction vide.** Un terme mappé à une chaîne vide. Omettez-le à la place.
- **Formes ou types incorrects.** `glossary` doit être une liste dans `L10N.md` et une carte dans `L10N/<locale>.md`. Les traductions, `id` et `definition` doivent être des chaînes de caractères ; `case_sensitive` doit être `true` ou `false`.

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

- `applied` liste les entrées qui correspondent au fichier. Les entrées du dépôt apparaissent sous `repo:<id>`, les entrées du compte sous `account:<id>`.
- `shadowed` liste les entrées du compte remplacées par une entrée du dépôt pour ce fichier.

La modification d'un terme ou d'une traduction ne rétraduit que les fichiers qui l'utilisent.

## Voir aussi

- [Définir un glossaire](/docs/how-to/define-a-glossary) : guide étape par étape.
- [Glossaire](/docs/explanation/glossary) : comment les glossaires de dépôt et de compte se combinent.
- [Référence L10N.md](/docs/reference/l10n-md) : les autres champs frontmatter.
