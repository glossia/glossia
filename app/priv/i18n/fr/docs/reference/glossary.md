%{
  title: "Glossaire",
  summary:
    "Référence pour le champ glossaire dans L10N.md et dans le fichier de surcharge de chaque langue.",
  category: "référence",
  section: "translation",
  order: 2
}
---

Un glossaire de dépôt est réparti sur deux fichiers. Glossia le combine avec le glossaire du compte pour chaque fichier qu'il traduit. Voir [Glossaire](/docs/explanation/glossary) pour savoir comment les deux se combinent.

| Fichier | `glossary` | Exemple |
|---|---|---|
| `L10N.md` | Une liste de **termes**, la même pour chaque langue. | `- source: commit` |
| `L10N/<locale>.md` | Une carte du terme à sa **traduction** dans cette langue. | `commit: commit` |

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
| `source` | chaîne | oui | Le terme tel qu'il apparaît dans le texte source. |
| `definition` | chaîne | non | Indice bref lu par le modèle pour décider si une correspondance est vraiment ce concept. |
| `case_sensitive` | booléen | non | Lorsque `true` est défini, le terme ne correspond que dans le cas exact écrit. La valeur par défaut est `false`. Utilisez-le pour les noms et acronymes tels que `API` ou `SDK`. |
| `id` | chaîne | non | Identifiant stable. Dérivé de `source` lorsqu'il est omis (`Version Control` devient `version-control`, `C++` devient `cplusplus`). Définissez-le pour indexer les traductions par identifiant, pour renommer `source` sans perdre l'identité du terme, ou pour remplacer un terme d'un parent `L10N.md`. |

Les termes ne contiennent pas de traductions. Un terme ayant un champ `targets` est rejeté : les traductions appartiennent aux fichiers de langue.

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

Chaque clé est le `id` d'un terme ou son `source`, et chaque valeur est la traduction officielle pour cette langue.

- Une clé qui ne correspond à aucun terme dans `L10N.md` déclare un terme uniquement pour cette langue.
- Un terme sans traduction dans une langue revient au glossaire du compte pour cette langue.
- Pour garder un nom sans traduction, mappez-le à lui-même, par exemple `Glossia: Glossia`.

## Fichiers imbriqués

Chaque fichier est traduit avec le glossaire de sa chaîne de répertoires :

- Un fichier `L10N.md` imbriqué ajoute des termes à ceux qu'il hérite. Un terme ayant le même `id` ou le même `source` lorsque aucun `id` n'est défini remplace le terme hérité pour cette sous-arbre.
- Un fichier `L10N/<locale>.md` imbriqué ajoute des traductions à celles qu'il hérite, et sa traduction l'emporte pour un terme déclaré par les deux.

## Validation

Causes courantes :

- **Champ `source` manquant.** Chaque terme doit avoir une valeur non vide.
- **Identifiant `id` dupliqué.** Chaque terme doit se résoudre à un identifiant unique, qu'il soit défini explicitement ou dérivé de `source`.
- **Les traductions dans L10N.md.** Un terme avec `targets`. Déplacez les traductions vers `L10N/<locale>.md`.
- **Traduction vide.** Un terme mappé à une chaîne vide. Omettez-le à la place.
- **Formes ou types incorrects.** `glossary` doit être une liste dans `L10N.md` et une carte dans `L10N/<locale>.md`. Les traductions, `id`, et `definition` doivent être des chaînes ; `case_sensitive` doit être `true` ou `false`.

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

- `applied` répertorie les entrées qui correspondent au fichier. Les entrées du dépôt apparaissent sous `repo:<id>`. Les entrées du compte sous `account:<id>`.
- `shadowed` liste les entrées du compte qui ont été remplacées par une entrée du dépôt pour ce fichier.

La modification d'un terme ou d'une traduction ne retraduit que les fichiers qui l'utilisent.

## Voir aussi

- [Définir un glossaire](/docs/how-to/define-a-glossary) : guide étape par étape.
- [Glossaire](/docs/explanation/glossary) : comment les glossaires de dépôt et de compte se combinent.
- [Référence L10N.md](/docs/reference/l10n-md) : les autres champs frontmatter.
