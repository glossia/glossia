%{
  title: "L10N.md",
  summary: "Référence pour les paramètres de traduction du référentiel et du contexte.",
  category: "référence",
  section: "translation",
  order: 1
}
---
`L10N.md`indique à Glossia quels fichiers traduire, où appartiennent les fichiers traduits, quelles langues cibler, et quel contexte doit guider le résultat. Un dépôt de code peut avoir un fichier racine et des fichiers étendus supplémentaires dans des sous-répertoires.

## Structure

Chaque fichier a deux parties :

1. [YAML Ain't Markup Language](https://yaml.org/)frontmatter entre`---`marqueurs.
2. Markdown sous le frontmatter avec le contexte de produit, public, ton ou domaine.

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

Les credentials du fournisseur appartiennent aux paramètres de compte, jamais dans`L10N.md`. La valeur `model`model

## Champs de frontmatter

| Champ | Type | Obligatoire | Description |
|---|---|---|---|
| \``source_language` | string | non | Langue source pour cette portée. Par défaut `en`. |
| \``model` | string | non | Identifiant de modèle de compte. Glossia utilise la valeur par défaut du compte si omis et signale une erreur si un identifiant explicite n'existe pas. |
| \``sources` | mappe ou liste | pour une règle de niveau supérieur | Motifs de fichiers sources. Les valeurs de mappe peuvent définir des modèles de sortie. |
| \``targets` | mappe ou liste | lorsque les sources sont configurées | Codes de langue cible. Une mappe peut associer un code de langue à un nom de langue. |
| \``output` | string | si aucun mappage de source ou `target_path` ne fournit une destination | Modèle de fichier de sortie. |
| \``target_path` | string | si aucun mappage de source ou `output` ne fournit une destination | Modèle de répertoire de base pour les fichiers traduits. |
| \``translate` | liste | non | Plusieurs règles de traduction, chacune avec ses sources et des corrections optionnelles. |
| \``exclude` | liste | non | Motifs de fichiers à omettre. |
| \``preserve` | liste | non | Types de contenu qui doit rester inchangé, tels que des séquences ou des uniform resource locators. |
| \``frontmatter` | string | non | `preserve` par défaut, ou `translate`. |
| \``prompt` | string | non | Guidance supplémentaire pour cette portée ou règle. |
| \``validation` | liste | pour les extensions de fichier sans adaptateur intégré | Une commande de validation suivie de ses arguments. La commande reçoit le candidat à son chemin réel de cible et doit retourner un statut non nul si le fichier est invalide. |
| \``check_cmd` | string | non | Une commande de vérification disponible au flux de travail de traduction. |
| \``check_cmds` | mappe | non | Commandes de vérification nommées disponibles au flux de travail de traduction. |
| \``retries` | entier | non | Nombre d'essais redemande après une vérification échouée. Par défaut `2`. |
| \``locale` | string | non | Langue jointe à un fichier de contexte spécifique à la langue. |
| \``glossary` | liste ou mappe | non | Dans `L10N.md`, une liste de termes de vocabulaire. Dans `L10N/<locale>.md`, une mappe de chaque terme à sa traduction dans cette langue. Les fichiers imbriqués ajoutent et modifient les entrées héritées. Voir la [référence du vocabulaire](/docs/reference/glossary). |

Les champs de frontmatter inconnus sont ignorés.

## Formats de fichier

Glossia a un traitement natif pour Markdown, JavaScript Object Notation, YAML Ain't Markup Language, portable object, et fichiers texte simple. D'autres extensions échouent la planification sauf si le `L10N.md` applicable déclare un `validation`commande. Cela évite de traiter silencieusement un format structuré propriétaire comme un texte non contraint.

Dans Markdown, seul le discours est traduit : paragraphes, titres, éléments de liste, éléments de table, les `title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label`, et `caption`attributs des composants et HTML, et le texte d'un HTML `<summary>`. Chaque autre octet, y compris le code, les destinations de lien, les composants, les alertes et les ancres explicites de titre, est conservé exactement comme dans la source. Voir [récupération de traduction](/docs/explanation/translation-recovery)pour comprendre le fonctionnement.

La commande de validation s’exécute après que le candidat ait été écrit temporairement dans son chemin de cible réel. Elle peut invoquer l’analyseur natif, le compilateur ou la commande de construction du dépôt. Glossia restaure la cible précédente après chaque tentative de validation et n’écrit le candidat accepté qu’ensuite.

## Correspondances de source

La forme la plus claire associe chaque motif de source à un modèle de sortie :

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Une liste de source est également valide, mais elle nécessite `output` ou `target_path` pour définir la destination :

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Langues cibles

Cette liste utilise chaque code de localisation comme identifiant de langue :

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
| `{locale}` ou `{lang}` | Code de localisation cible. |
| `{relpath}` | Chemin de source relatif au motif correspondant. |
| `{basename}` | Nom de fichier source sans extension. |
| `{ext}` | Extension de fichier source sans le point initial. |

## Règles multiples

Utilisez `translate` lorsque différents groupes de contenu ont besoin de destinations ou de contrôles différents :

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

Glossia lit les fichiers `L10N.md` depuis la racine du dépôt vers le fichier source :

- Les paramètres parents fournissent des valeurs par défaut.
- Un fichier plus profond remplace les champs pour son dossier.
- Le contexte Markdown est accumulé du parent vers l'enfant.
- Les conseils spécifiques au code local et le gestionnaire de modèle spécifique au code local peuvent vivre dans `L10N/<locale>.md`.

Cela permet à un dépôt de maintenir des directives générales de ton à la racine tout en plaçant les directives spécifiques au domaine de produit ou à la langue près du contenu qu'il affecte.