%{
  title: "L10N.md",
  summary: "Référence pour les paramètres de traduction du dépôt et le contexte.",
  category: "référence",
  section: "translation",
  order: 1
}
---
`L10N.md` indique à Glossia quels fichiers traduire, où placer les fichiers traduits, quelles langues cibler et quel contexte doit guider le résultat. Un dépôt peut contenir un fichier racine et des fichiers supplémentaires dans des sous-dossiers.

## Structure

Chaque fichier comprend deux parties :

1. [YAML n'est pas un langage de balisage](https://yaml.org/) frontmatter entre `---` marqueurs.
2. Le Markdown après le frontmatter comprend les contextes du produit, du public, du ton ou du domaine.

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

Les identifiants du fournisseur relèvent des paramètres de compte, jamais dans `L10N.md`. L'optionnel `model` valeur est un identifiant de modèle de compte.

## Champs frontmatter

| Champ | Type | Obligatoire | Description |
|---|---|---|---|
| `source_language` | chaîne | non | Locale source pour cette portée. Par défaut `en`. |
| `model` | string | no | Identifiant de modèle de compte. Glossia utilise la valeur par défaut du compte lorsqu'il est omis et signale une erreur lorsqu'un identifiant explicite n'existe pas.
| `sources` | carte ou liste | pour une règle de niveau supérieur | Modèles de fichiers source. Les valeurs de carte peuvent définir des modèles de sortie.
| `targets` | carte ou liste | quand les sources sont configurées | Codes de langue cible. Une carte peut associer un code de langue à un nom de langue.
| `output` | chaîne | lorsqu'aucune correspondance de source ou `target_path` fournit une destination | Modèle de fichier de sortie. |
| `target_path` | chaîne | lorsque aucun mappage de source ou `output` fournit une destination | Modèle de répertoire de base pour les fichiers traduits. |
| `translate` | liste | non | plusieurs règles de traduction, chacune avec ses propres sources et des surcharges optionnelles. |
| `exclude` | liste | non | motifs de fichiers à ignorer. |
| `preserve` | list | no | Types de contenu qui doivent rester inchangés, tels que les placeholders ou les localisateurs de ressources unifiées. |
| `frontmatter` | string | no | `preserve` par défaut, ou `translate`. |
| `prompt` | string | no | Conseils supplémentaires pour cette portée ou règle. |
| `validation` | list | pour les extensions de fichiers sans adaptateur intégré | Une commande de validation suivie de ses arguments. La commande reçoit le candidat sur son chemin cible réel et doit retourner un statut non nul lorsque le fichier est invalide. |
| `check_cmd` | string | no | Une commande de vérification disponible pour le flux de traduction. |
| `check_cmds` | map | no | Commandes de vérification nommées disponibles pour le flux de traduction. |
| `retries` | integer | no | Nombre de tentatives de reprise après une vérification échouée. Par défaut à `2`. |
| `locale` | string | no | Paramètre de localisation attaché à un fichier de contexte spécifique à la localisation. |
| `glossary` | liste ou dictionnaire | non | Dans `L10N.md`, une liste de termes du glossaire. Dans `L10N/<locale>.md`, un dictionnaire pour chaque terme à sa traduction dans cette langue. Les fichiers imbriqués ajoutent et remplacent les entrées héritées. Voir la [référence au glossaire](/docs/reference/glossary). |

Les champs frontmatter inconnus sont ignorés.

## Formats de fichiers

Glossia gère nativement le Markdown, la notation JSON, le langage YAML, les objets portables et les fichiers texte brut. D'autres extensions échouent en planification sauf si l'applicable `L10N.md` déclare une `validation` commande. Cela évite de traiter silencieusement un format structuré propriétaire comme du texte non contraint.

La commande de validation s'exécute après que le candidat ait été écrit temporairement vers son chemin cible réel. Elle peut invoquer le parseur natif, le compilateur ou la commande de construction du dépôt. Glossia restaure la cible précédente après chaque tentative de validation et n'écrit le candidat accepté qu'ensuite.

## Mappings de source

La forme la plus claire associe chaque motif de source à un modèle de sortie :

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Une liste de sources est également valide, mais elle a besoin `output` ou `target_path` pour définir la destination :

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Langues cibles

Une liste utilise chaque code de locale comme identifiant de langue :

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
| `{locale}` ou `{lang}` | Code de locale cible. |
| `{relpath}` | Chemin de source relatif au motif correspondant. |
| `{basename}` | Nom de fichier source sans extension. |
| `{ext}` | Extension du fichier source sans le point initial. |

## Plusieurs règles

Utilisez `translate` lorsque les différents groupes de contenu nécessitent des destinations différentes ou des contrôles :

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

Les valeurs de règle remplacent les valeurs héritées du fichier environnant.

## Contexte à portée restreinte

Glossia lit les fichiers `L10N.md` depuis la racine du dépôt jusqu'au fichier source :

- Les paramètres parents fournissent les valeurs par défaut.
- Un fichier plus profond remplace les champs de son répertoire.
- Le contexte Markdown est accumulé du parent vers l'enfant.
- La guidance spécifique au locale et un gestionnaire de modèle spécifique au locale peuvent résider dans `L10N/<locale>.md`.

Cela permet à un dépôt de conserver des directives de ton générales à la racine tout en plaçant des directives spécifiques à une zone de produit ou à une langue près du contenu qu'elles affectent.