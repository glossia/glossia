%{
  title: "L10N.md",
  summary: "Référence pour les paramètres de traduction du dépôt et le contexte.",
  category: "référence",
  section: "translation",
  order: 1
}
---
`L10N.md` dit à Glossia quels fichiers traduire, où appartiennent les fichiers traduits, les langues cibles et le contexte qui devrait guider le résultat. Un dépôt peut posséder un fichier racine et des fichiers supplémentaires dans des sous-répertoires.

## Structure

Chaque fichier possède deux parties :

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre les marqueurs `---`.
2. Markdown ci-dessous le frontmatter avec le contexte produit, public, voix ou domaine.

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

Les identifiants du fournisseur appartiennent aux paramètres du compte, jamais dans `L10N.md`. La valeur optionnelle `model` est un identifiant de modèle de compte. Glossia utilise le modèle par défaut du compte lorsqu'il est omis et signale une erreur lorsqu'une identité explicite n'existe pas.

## Champs du frontmatter

| Champ | Type | Obligatoire | Description |
|---|---|---|---|
| `source_language` | string | non | Langue source pour cette portée. Par défaut, `en`. |
| `model` | string | non | Identifiant de modèle de compte. Glossia utilise le modèle par défaut du compte lorsqu'il est omis et signale une erreur lorsqu'une identité explicite n'existe pas. |
| `sources` | map ou liste | pour une règle de niveau supérieur | Motifs de fichiers source. Les valeurs de la map peuvent définir des modèles de sortie. |
| `targets` | map ou liste | lorsque les sources sont configurées | Codes de langues cibles. Une map peut associer un code de langue à un nom de langue. |
| `output` | string | lorsque aucune analyse de sources ni `target_path` ne fournit une destination | Modèle de fichier de sortie. |
| `target_path` | string | lorsque aucune analyse de sources ni `output` ne fournit une destination | Modèle de le répertoire de base pour les fichiers traduits. |
| `translate` | liste | non | Règles de traduction multiples, chacune avec leurs propres sources et éventuellement des corrections. |
| `exclude` | liste | non | Motifs de fichiers à sauter. |
| `preserve` | liste | non | Types de contenu qui doivent demeurer inchangés, tels que les placeholders ou URI uniformes. |
| `frontmatter` | string | non | `preserve` par défaut, ou `translate`. |
| `prompt` | string | non | Orientation supplémentaire pour cette portée ou règle. |
| `validation` | liste | pour les extensions de fichiers sans adaptateur intégré | Une commande de validation suivie de ses arguments. La commande reçoit le candidat à son vrai chemin cible et doit retourner un état non nul lorsque le fichier est invalide. |
| `check_cmd` | string | non | Une commande de vérification disponible pour le flux de travail de traduction. |
| `check_cmds` | map | non | Commandes de vérification nommées disponibles pour le flux de travail de traduction. |
| `retries` | entier | non | Nombre d'essais redonnées après une vérification échouée. Par défaut, `2`. |
| `locale` | string | non | Langue associée à un fichier de contexte spécifique à la langue. |
| `glossary` | liste ou map | non | Dans `L10N.md`, une liste de termes du glossaire. Dans `L10N/<locale>.md`, une map de chaque terme à sa traduction dans cette langue. Les fichiers imbriqués ajoutent et écrasent les entrées héritées. Voir la [référence glossaire](/docs/reference/glossary). |

Les champs frontmatter inconnus sont ignorés.

## Formats de fichiers

Glossia dispose d'un traitement intégré pour les fichiers Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable object, et plain text. Les autres extensions échouent lors de la planification, sauf si la `L10N.md` applicable déclare une commande de `validation`. Cela évite de traiter silencieusement un format structuré propriétaire comme un texte non contraint.

La commande de validation s'exécute après que le candidat a été écrit temporairement à son vrai chemin cible. Elle peut appeler l'analiseur, compilateur ou commande de construction native du dépôt. Glossia restaure la destination précédente après chaque tentative de validation et n'écrit le candidat accepté qu'ultérieurement.

## Mappage de sources

La forme la plus claire établit un mappage pour chaque motif source à un modèle de sortie :

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