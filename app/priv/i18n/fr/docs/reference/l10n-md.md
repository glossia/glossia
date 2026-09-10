%{
  title: "L10N.md",
  summary: "Référence pour les paramètres de traduction du dépôt et le contexte.",
  category: "référence",
  order: 1
}
---
`L10N.md` indique à Glossia quels fichiers traduire, où les fichiers traduits doivent se situer, quelles langues cibler et quel contexte doit guider le résultat. Un dépôt peut comporter un fichier racine et des fichiers scopeés dans des sous-répertoires.

## Structure

Chaque fichier comporte deux parties :

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre les marqueurs `---`.
2. Markdown au-dessous du frontmatter avec un contexte produit, public, voix ou domaine.

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

Les identifiants de fournisseur appartiennent aux paramètres de compte, jamais dans `L10N.md`. La valeur `model` optionnelle est un identifiant de modèle de compte.

## Champs frontmatter

| Champ | Type | Requis | Description |
|---|---|---|---|
| `source_language` | string | non | Locale source pour cette zone de portée. Par défaut, `en`. |
| `model` | string | non | Identifiant de modèle de compte. Glossia utilise la valeur par défaut du compte si elle est omise et rapporte une erreur si un identifiant explicite n'existe pas. |
| `sources` | map ou liste | pour une règle de niveau supérieur | Motifs de fichiers sources. Les valeurs de map peuvent définir des modèles de sortie. |
| `targets` | map ou liste | lorsque les sources sont configurées | Codes de locale cible. Une map peut associer un code de locale à un nom de langue. |
| `output` | string | lorsqu'il n'y a pas de cartes de source ou `target_path` fournit une destination | Modèle de fichier de sortie. |
| `target_path` | string | lorsqu'il n'y a pas de carte de source ou `output` fournit une destination | Modèle de répertoire de base pour les fichiers traduits. |
| `translate` | liste | non | Plusieurs règles de traduction, chacune avec ses sources et des dépassements optionnels. |
| `exclude` | liste | non | Motifs de fichiers à sauter. |
| `preserve` | liste | non | Types de contenu qui doivent rester inchangés, utilisant par exemple les placeholders ou des uniform resource locators. |
| `frontmatter` | string | non | `preserve` par défaut, ou `translate`. |
| `prompt` | string | non | Guidance supplémentaire pour cette zone de portée ou règle. |
| `validation` | liste | pour les extensions de fichier sans adaptateur intégré | Une commande de validation suivie de ses arguments. La commande reçoit le candidat à son chemin d'objectif réel et doit retourner un statut non nul lorsque le fichier est invalide. |
| `check_cmd` | string | non | Une commande de contrôle disponible pour le flux de travail de traduction. |
| `check_cmds` | map | non | Commandes de contrôle nommées disponibles pour le flux de travail de traduction. |
| `retries` | integer | non | Nombre de tentatives de réessai après une vérification échouée. Par défaut, `2`. |
| `locale` | string | non | Locale accolée à un fichier de contexte spécifique à un locale. |

Les champs de frontmatter ignorés sont ignorés.

## Formats de fichier

Glossia a un traitement intégré pour les fichiers Markdown, JavaScript Object Notation, YAML Ain't Markup Language, porte objet et fichiers de texte simples. D'autres extensions de fichier échouent la planification sauf si le `L10N.md` applicable déclare une commande `validation`. Cela évite de traiter silencieusement un format structuré propriétaire comme du texte non contraint.

La commande de validation est exécutée après que le candidat a été écrit temporairement à son chemin d'objectif réel. Elle peut invoquer le parseur natif du dépôt, le compilateur ou la commande de construction. Glossia restaure l'objectif précédent après chaque tentative de validation et n'écrit le candidat accepté qu'ensuite.

## Cartes de source

La forme la plus claire est de mapper chaque motif de source à un modèle de sortie :

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Une liste de sources est également valide, mais elle a besoin de `output` ou `target_path` pour définir le destinataire :

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Langues cibles

Une liste utilise chaque code de langue comme identifiant de langue :

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
| `{locale}` ou `{lang}` | Code de langue cible. |
| `{relpath}` | Chemin source relatif par rapport au motif correspondu. |
| `{basename}` | Nom de fichier source sans son extension. |
| `{ext}` | Extension de fichier source sans le point initial. |

## Règles multiples

Utilisez `translate` lorsque différents groupes de contenu nécessitent des destinations différentes ou des vérifications :

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

## Contexte de portée

Glossia lit les fichiers `L10N.md` depuis la racine du dépôt jusqu'au fichier source :

- Les paramètres parent fournissent les valeurs par défaut.
- Un fichier plus profond remplace les champs de son répertoire.
- Le contexte Markdown est accumulé du parent vers le fichier enfant.
- Les consignes spécifiques à la langue et un gestionnaire de modèle spécifique à la langue peuvent résider dans `L10N/<locale>.md`.

Cela permet à un dépôt de maintenir une orientation de ton large à la racine tout en plaçant les orientations spécifiques au domaine produit ou à la langue à proximité du contenu qu'elles affectent.