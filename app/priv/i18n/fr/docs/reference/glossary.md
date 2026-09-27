%{
  title: "Glossaire",
  summary:
    "Référence pour le champ glossaire dans L10N.md et dans le fichier de surcharge de chaque langue.",
  category: "référence",
  section: "traduction",
  order: 2
}
---
Un glossaire de dépôt est réparti sur deux fichiers. Glossia le fusionne avec le glossaire serveur du compte pour chaque fichier qu'il traduit. Voir [Glossaire](/docs/explanation/glossary) pour savoir comment les deux se combinent.

| Fichier | `glossary` contient | Exemple |
|---|---|---|
| `L10N.md` | Une liste de **termes**, c'est le même pour chaque langue. | `- source: commit` |
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

| Champ | Type | Requis | Description |
|---|---|---|---|
| `source` | string | oui | Le terme tel qu'il apparaît dans le texte source. |
| `definition` | string | non | Conseil bref lu par le modèle pour décider si une correspondance est vraiment ce concept. |
| `case_sensitive` | boolean | non | Lorsque `true`, le terme ne correspond que dans la casse exacte écrite. Par défaut `false`, . Utilisez-le pour les noms et acronymes tels que `API` ou `SDK`, . |
| `id` | string | non | Identifiant stable. Dérivé de `source` lorsqu'il est omis (`Version Control` devient `version-control`, `C++` devient `cplusplus`). Définissez-le sur les traductions de clés par id, pour renommer `source` sans perdre l'identité du terme, ou de surclasser un terme issu d'un parent `L10N.md`. |

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

Chaque clé est d'un terme `id` ou son `source`, et chaque valeur est la traduction approuvée pour cette langue.

- Une clé qui ne correspond à aucun terme dans `L10N.md` déclare un terme pour cette langue uniquement.
- Un terme sans traduction dans une langue retombe sur le glossaire du serveur pour cette langue.
- Pour conserver un nom sans traduction, mappez-le à lui-même, par exemple `Glossia: Glossia`.

## Fichiers imbriqués

Chaque fichier est traduit avec le glossaire de sa chaîne de répertoires :

- Un fichier imbriqué `L10N.md` ajoute des termes à ceux qu'il hérite. Un terme avec le même `id`, ou le même `source` lorsqu'aucun `id` est défini, remplace celui hérité pour ce sous-arbre.
- Un imbriqué `L10N/<locale>.md` ajoute des traductions à celles qu'il hérite, et sa traduction l'emporte pour un terme que les deux déclarent.

## Validation

Si un glossaire est invalide, Glossia traduit les fichiers affectés avec le glossaire du serveur uniquement, de sorte qu'une faute de frappe ne bloque jamais les traductions. Causes courantes :

- **Manquant `source`.** Chaque terme nécessite une valeur non vide.
- **Dupliqué `id`.** Chaque terme doit correspondre à un identifiant unique, qu'il soit défini explicitement ou dérivé de `source`.
- **Traductions dans L10N.md.** Un terme avec `targets`. Déplacer les traductions vers `L10N/<locale>.md`.
- **Traduction vide.** Un terme mappé à une chaîne vide. Omettez-le à la place.
- **Formes ou types incorrects.** `glossary` doit être une liste dans `L10N.md` et un tableau dans `L10N/<locale>.md`. Traductions, `id`, et `definition` doivent être des chaînes ; `case_sensitive` doit être `true` ou `false`.

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

- `applied` liste les entrées qui correspondent au fichier. Les entrées du dépôt apparaissent sous `repo:<id>`, les entrées du serveur apparaissent sous `account:<id>`.
- `shadowed` liste les entrées serveur remplacées par une entrée de référentiel pour ce fichier.

Modifier un terme ou une traduction ne retraduit que les fichiers qui l'utilisent.

## Voir aussi

- [Définir un glossaire](/docs/how-to/define-a-glossary): guide pas à pas.
- [Glossaire](/docs/explanation/glossary): comment les glossaires de référentiel et de serveur se combinent.
- [L10N.md référence](/docs/reference/l10n-md): les autres champs frontmatter.