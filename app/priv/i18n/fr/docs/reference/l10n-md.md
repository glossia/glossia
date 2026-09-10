%{
  title: "L10N.md",
  summary: "Référence pour les paramètres de traduction du référentiel et le contexte.",
  category: "référence",
  order: 1
}
---
`L10N.md` indique à Glossia quels fichiers traduire, où appartiennent les fichiers traduits, les langues à cibler, et quel contexte devrait guider le résultat. Un dépôt peut avoir un fichier racine et des fichiers supplémentaires dans des sous-répertoires.

## Structure

Chaque fichier comprend deux parties:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre balises `---`.
2. Markdown après le frontmatter avec contexte sur le produit, l'audience, le ton ou le domaine.

<!-- end list -->

```yaml
---
source_language: en
model: translation-default
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
targets:
  - es
  - ja
validation:
  - ./scripts/validate-docs.sh
  - --strict
frontmatter: preserve
preserve:
  - placeholders
  - urls
---

Write for software developers. Keep product names and code samples unchanged.
```

Les identifiants de fournisseur appartiennent aux paramètres du compte, jamais dans `L10N.md`. La valeur optionnelle `model` est un identifiant du modèle du compte.

## Champs du frontmatter

| Champ | Type | Requis | Description |
|---|---|---|---|
| `source_language` | chaîne | non | Locale source pour cet étendue. Par défaut à `en`. |
| `model` | chaîne | non | Identifiant du modèle du compte. Glossia utilise la valeur du compte par défaut lorsqu'il est omis et signale une erreur lorsqu'un identifiant explicatif n'existe pas. |
| `sources` | map ou liste | pour une règle de niveau supérieur | Modèles de fichiers sources. Les valeurs map peuvent définir des modèles de sortie. |
| `targets` | map ou liste | lorsque sources sont configurées | Codes de locale cible. Une map peut associer un code de langue à un nom de langue. |
| `output` | chaîne | sans mapping source ou `target_path` qui fournit une destination | Modèle de fichier de sortie. |
| `target_path` | chaîne | sans mapping source ou `output` qui fournit une destination | Modèles de répertoire de base pour fichiers traduits. |
| `translate` | liste | non | Plusieurs règles de traduction, chacune avec ses propres sources et recouvrements optionnels. |
| `exclude` | liste | non | Modèles de fichiers à exclure. |
| `preserve` | liste | non | Types de contenu qui doivent rester inchangés, tels que des placeholders ou des uniform resource locators. |
| `frontmatter` | chaîne | non | `preserve` par défaut, ou `translate`. |
| `prompt` | chaîne | non | Guida补充补充 pour cette étendue ou règle. |
| `validation` | liste | pour des extensions de fichier sans adaptateur intégré | Une commande de validation suivie de ses arguments. La commande reçoit le candidat à son chemin cible réel et doit retourner un état non zéro lorsque le fichier est invalide. |
| `check_cmd` | chaîne | non | Une commande de vérification disponible à la traduction workflow. |
| `check_cmds` | map | non | Commandes de vérification nommées disponibles à la traduction workflow. |
| `retries` | entier | non | Nombre d'essais après une vérification échouée. Par défaut `2`. |
| `locale` | chaîne | non | Locale attachée à un fichier de contexte spécifique au locale. |

Les champs de frontmatter inconnus sont ignorés.

## Formats de fichiers

Glossia a un traitement intégré pour les fichiers Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable objet et plain text. D'autres extensions échouent la planification à moins que l'`L10N.md` applicable n'annonce une commande `validation`. Cela évite de traiter silencieusement un format structuré propriétaire comme un texte non contraint.

La commande de validation s'exécute après que le candidat ait été écrit temporairement à son chemin cible réel. Elle peut invoquer le parseur, le compilateur ou la commande de build natif du dépôt. Glossia restaure la cible précédente après chaque tentative de validation et n'écrit que le candidat accepté après.

## Mappings sources

La forme la plus claire map chaque modèle source à un modèle de sortie:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Une liste source est aussi valide, mais elle nécessite `output` ou `target_path` pour définir la destination:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Langues cibles

Une liste utilise chaque code de localisation comme son identifiant de langue :

```yaml
targets:
  - es
  - ja
```

Une map peut ajouter un nom de langue lisible :

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variables de sortie

| Variable | Valeur |
|---|---|
| `{locale}` ou `{lang}` | Code de la langue cible. |
| `{relpath}` | Chemin source relatif au motif apparié. |
| `{basename}` | Nom du fichier source sans son extension. |
| `{ext}` | Extension du fichier source sans le point initial. |

## Plusieurs règles

Utilisez `translate` lorsque différents groupes de contenu ont besoin de destinations ou de vérifications différentes :

```yaml
---
source_language: en
targets:
  - es
translate:
  - sources:
      - "docs/**/*.md"
    output: "docs/i18n/{locale}/{relpath}"
  - source: "messages/*.json"
    output: "messages/{locale}/{basename}.{ext}"
---
```

Les valeurs de règle prévalent sur les valeurs héritées du fichier environnant.

## Contexte restreint

Glossia lit `L10N.md` des fichiers depuis la racine du dépôt vers le fichier source :

- Les paramètres parents fournissent les valeurs par défaut.
- Un fichier plus profond remplace les champs de son répertoire.
- Le contexte Markdown est accumulé du parent à l'enfant.
- Les directives spécifiques à la locale et le gestionnaire de modèle spécifique à la locale peuvent résider dans `L10N/<locale>.md`.

Cela permet à un référentiel de conserver des directives générales sur le ton à la racine tout en plaçant les directives spécifiques au domaine du produit ou à la langue à proximité du contenu qu'elles concernent.