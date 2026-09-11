%{
  title: "L10N.md",
  summary: "Référence pour les paramètres de traduction du dépôt et du contexte.",
  category: "référence",
  order: 1
}
---
`L10N.md` indique à Glossia quels fichiers traduire, où placer les fichiers traduits, vers quelles langues cibler, et quel contexte devrait guider le résultat. Un dépôt peut contenir un fichier racine et des fichiers supplémentaires à portée dans des sous-répertoires.

## Structure

Chaque fichier comporte deux parties :

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre les marques `---`.
2. Markdown sous la frontmatter avec le contexte produit, public, voix ou domaine.

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

Les identifiants de fournisseur appartiennent aux paramètres de compte, jamais dans `L10N.md`. La valeur optionnelle `model` est un identifiant de modèle de compte. Glossia utilise le modèle par défaut du compte lorsqu'il est omis et signale une erreur lorsqu'un identifiant explicite n'existe pas.

## Champs frontmatter

| Champ | Type | Obligatoire | Description |
|---|---|---|---|
| `source_language` | chaine | no | Langue source pour cette portée. Par défaut `en`. |
| `model` | chaine | no | Identifiant de modèle de compte. Glossia utilise le modèle par défaut du compte lorsqu'il est omis et signale une erreur lorsqu'un identifiant explicite n'existe pas. |
| `sources` | map ou list | pour une règle de niveau supérieur | Motifs de fichiers sources. Les valeurs mappe peuvent définir des modèles de sortie. |
| `targets` | map ou list | lorsque les sources sont configurées | Codes de langue cible. Un mappe peut associer un code de langue à un nom de langue. |
| `output` | chaine | lorsque aucun mappage de source ou `target_path` n'indique une destination | Modèle de fichier de sortie. |
| `target_path` | chaine | lorsque aucun mappage de source ou `output` n'indique une destination | Modèle de répertoire de base pour les fichiers traduits. |
| `translate` | list | no | Règles de traduction multiples, chacune avec ses propres sources et surcharges facultatives. |
| `exclude` | list | no | Motifs de fichiers à sauter. |
| `preserve` | list | no | Types de contenu qui doivent rester inchangés, tels que des placeholder ou des uniform resource locators. |
| `frontmatter` | chaine | no | `preserve` par défaut, ou `translate`. |
| `prompt` | chaine | no | Orientation supplémentaire pour cette portée ou pour cette règle. |
| `validation` | list | pour les extensions de fichier sans adaptateur intégré | Une commande de validation suivie de ses arguments. La commande reçoit le candidat à son vrai chemin cible et doit renvoyer un statut non nul si le fichier est invalide. |
| `check_cmd` | chaine | no | Une commande de vérification disponible pour le flux de travail de traduction. |
| `check_cmds` | map | no | Commandes de vérification nommées disponibles pour le flux de travail de traduction. |
| `retries` | entier | no | Nombre de tentatives de réessai après une vérification échouée. Par défaut `2`. |
| `locale` | chaine | no | Langue attachée à un fichier de contexte spécifique à la langue. |

Les champs frontmatter inconnus sont ignorés.

## Formats de fichiers

Glossia gère nativement les fichiers Markdown, JavaScript Object Notation, YAML Ain't Markup Language, objet portable et texte brut. D'autres extensions échouent lors de la planification sauf si le fichier `L10N.md` applicable déclare une commande `validation`. Cela évite de traiter silencieusement un format structuré propriétaire comme du texte non contraint.

La commande de validation s'exécute après que le candidat ait été écrit temporairement dans son vrai chemin cible. Elle peut invoquer l'analyseur natif, le compilateur ou la commande de construction du dépôt. Glossia restaure le chemin cible précédent après chaque tentative de validation et n'écrit le candidat accepté qu'ensuite.

## Mappage des sources

Le format le plus clair associe chaque motif de source à un modèle de sortie :

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Une liste de sources est également valide, mais elle nécessite `output` ou `target_path` pour définir la destination :

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

Un dictionnaire peut ajouter un nom de langue lisible :

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variables de sortie

| Variable | Valeur |
|---|---|
| `{locale}` ou `{lang}` | Code de langue cible. |
| `{relpath}` | Chemin source relatif au motif correspondant. |
| `{basename}` | Nom de fichier source sans son extension. |
| `{ext}` | Extension de fichier source sans le point initial. |

## Règles multiples

Utilisez `translate` pour que différents groupes de contenu nécessitent des destinations ou des vérifications différentes :

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

## Portée du contexte

Glossia lit les fichiers `L10N.md` depuis la racine du référentiel vers le fichier source :

- Les paramètres parentaux fournissent les valeurs par défaut.
- Un fichier plus profond remplace les champs de son répertoire.
- Le contexte Markdown est accumulé du parent au fichier enfant.
- Les directives spécifiques au lieu et le gestionnaire de modèle spécifiques au lieu peuvent résider dans `L10N/<locale>.md`.

Cela permet à un dépôt de maintenir des directives larges de voix à la racine tout en plaçant des directives spécifiques au domaine de produit ou de langue à proximité du contenu qu'elles affectent.