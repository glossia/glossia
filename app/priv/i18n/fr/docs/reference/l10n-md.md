%{
  title: "L10N.md",
  summary: "Référence pour les paramètres de traduction du dépôt et le contexte.",
  category: "référence",
  section: "translation",
  order: 1
}
---

`L10N.md` indique à Glossia quels fichiers traduire, où appartiennent les fichiers traduits, quelles langues cibler, et quel contexte doit guider le résultat. Un dépôt peut avoir un fichier racine et des fichiers supplémentaires couverts dans les sous-répertoires.

## Structure

Chaque fichier comporte deux parties :

1. [YAML n'est pas un langage de marquage](https://yaml.org/) entre les marques `---`.
2. Markdown sous le frontmatter accompagnant le contexte produit, public, tonique ou domaine.

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

Les identifiants du fournisseur appartiennent aux paramètres de compte, jamais dans `L10N.md`. La valeur optionnelle `model` est un handle de modèle de compte.

## Champs du frontmatter

| Champ | Type | Obligatoire | Description |
|---|---|---|---|
| `source_language` | chaîne | non | Locale source pour cette portée. Valeur par défaut `en`. |
| `model` | chaîne | non | Handle du modèle de compte. Glossia utilise la valeur par défaut du compte quand omis et signale une erreur quand un handle explicite n'existe pas. |
| `sources` | tableau ou liste | pour une règle de niveau supérieur | Motifs de fichiers sources. Les valeurs du tableau peuvent définir des modèles de sortie. |
| `targets` | tableau ou liste | lorsque des sources sont configurées | Codes de locales cibles. Un tableau peut associer un code de locale à un nom de langue. |
| `output` | chaîne | lorsqu'aucun mappage de source ou `target_path` fournit une destination | Modèle de fichier de sortie. |
| `target_path` | chaîne | lorsqu'aucun mappage de source ou `output` fournit une destination | Modèle de dossier de base pour les fichiers traduits. |
| `translate` | liste | non | Plusieurs règles de traduction, chacune avec ses propres sources et overrides optionnels. |
| `exclude` | liste | non | Motifs de fichiers à sauter. |
| `preserve` | liste | non | Types de contenu qui doivent rester inchangés, tels que des placeholders ou des uniform resource locators. |
| `frontmatter` | chaîne | non | `preserve` par défaut, ou `translate`. |
| `prompt` | chaîne | non | Guidance supplémentaire pour cette portée ou cette règle. |
| `validation` | liste | pour les extensions de fichier sans adaptateur intégré | Une commande de validation accompagnée de ses arguments. La commande reçoit le candidat sur son vrai chemin de cible et doit retourner un statut non nul lorsque le fichier est invalide. |
| `check_cmd` | chaîne | non | Une commande de vérification disponible pour le flux de traduction. |
| `check_cmds` | tableau | non | Commandes de vérification nommées disponibles pour le flux de traduction. |
| `retries` | entier | non | Nombre de tentatives de réessai après une vérification échouée. Par défaut `2`. |
| `locale` | chaîne | non | Locale attachée à un fichier de contexte spécifique à la langue. |
| `glossary` | liste ou tableau | non | Dans `L10N.md` une liste de termes du glossaire. Dans `L10N/<locale>.md` un tableau associant chaque terme à sa traduction dans cette langue. Les fichiers imbriqués s'ajoutent aux entrées héritées et les surchargent. Voir la [référence du glossaire](/docs/reference/glossary). |

Les champs frontmatter inconnus sont ignorés.

## Formats de fichiers

Glossia dispose d'un traitement intégré pour Markdown, la notation d'objet JavaScript, YAML n'est pas un langage de marquage, un objet portable et les fichiers texte brut. D'autres extensions de fichiers échouent lors de la phase de planification sauf si le `L10N.md` applicable déclare une commande `validation`. Cela évite de traiter silencieusement un format structuré propriétaire comme du texte non contraint.

Le seul texte traduit dans Markdown est : paragraphes, titres, éléments de liste, cellules de tableau, les attributs `title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, et `caption` des composants et HTML, et le texte d'un élément HTML `<summary>`. Chaque autre octet, y compris le code, les destinations de lien, les composants, les alertes et les ancres explicites de titre, est conservé exactement comme dans la source. Voir [récupération de traduction](/docs/explanation/translation-recovery) pour la façon dont cela fonctionne.

La commande de validation s'exécute après que le candidat a été écrit temporairement sur son vrai chemin de cible. Elle peut invoquer le processeur natif, le compilateur ou la commande de construction du dépôt. Glossia restaure la cible précédente après chaque tentative de validation et n'écrit le candidat accepté qu'ensuite.

## Mappages de sources

La forme la plus claire associe chaque motif de source à un modèle de sortie :

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

Une liste utilise chaque code de locale comme identifiant de langue :

```yaml
targets:
  - es
  - ja
```

Un tableau peut ajouter un nom de langue lisible :

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variables de sortie

| Variable | Valeur |
|---|---|
| `{locale}` ou `{lang}` | Code de locale cible. |
| `{relpath}` | Chemin de source relatif au motif matché. |
| `{basename}` | Nom de fichier source sans son extension. |
| `{ext}` | Extension de fichier source sans le point initial. |

## Règles multiples

Utilisez `translate` lorsque différents groupes de contenu nécessitent des destinations ou des vérifications différentes :

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

Les valeurs de règle surchargent les valeurs héritées du fichier environnant.

## Contexte restreint

Glossia lit les fichiers `L10N.md` depuis la racine du dépôt vers le fichier source :

- Les paramètres parents fournissent les valeurs par défaut.
- Un fichier plus profond surcharge les champs de son répertoire.
- Le contexte Markdown est accumulé du parent vers le fichier enfant.
- Les orientations spécifiques à la langue et un identifiant de modèle spécifique à la langue peuvent résider dans `L10N/<locale>.md`.

Cela permet à un dépôt de maintenir des orientations de voix générales à la racine tout en positionnant des orientations spécifiques au domaine ou à la langue près du contenu qu'il affecte.
