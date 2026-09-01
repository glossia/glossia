%{
  title: "GLOSSIA.md",
  summary: "Référence pour les paramètres de traduction et le contexte du dépôt.",
  category: "référence",
  order: 1
}
---
`GLOSSIA.md` indique à Glossia quels fichiers traduire, où appartiennent les fichiers traduits, quelles langues cibler et quel contexte doit guider le résultat. Un dépôt peut avoir un fichier racine et des fichiers supplémentaires étendus dans des sous-répertoires.

## Structure

Chaque fichier comporte deux parties:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre `---` marqueurs.
2. Le Markdown situé sous le frontmatter avec le contexte produit, public, voix ou domaine.

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

Les identifiants de fournisseur appartiennent aux paramètres de compte, jamais dans `GLOSSIA.md`. La valeur optionnelle `model` est un identifiant de modèle de compte.

## Champs du frontmatter

| Champ | Type | Obligatoire | Description |
|---|---|---|---|
| `source_language` | chaîne | non | Locale source pour cette portée. Par défaut `en`. |
| `model` | chaîne | non | Identifiant de modèle de compte. Glossia utilise la valeur par défaut du compte si omis et signale une erreur si l'identifiant explicite n'existe pas. |
| `sources` | mappe ou liste | pour une règle de haut niveau | Patterns de fichiers sources. Les valeurs de la mappe peuvent définir des modèles de sortie. |
| `targets` | mappe ou liste | lorsque les sources sont configurées | Codes de locale cible. Une mappe peut associer un code de locale à un nom de langue. |
| `output` | chaîne | lorsque aucune traduction de source ou `target_path` fournit une destination | Modèle de fichier de sortie. |
| `target_path` | chaîne | lorsqu'une mappe de source ou `output` fournit une destination | Modèle de répertoire de base pour les fichiers traduits. |
| `translate` | liste | non | Plusieurs règles de traduction, chacune avec ses propres sources et options de remplissage facultatives. |
| `exclude` | liste | non | Patterns de fichier à sauter. |
| `preserve` | liste | non | Types de contenu qui doivent rester inchangés, tels que les placeholders ou les uniform resource locators. |
| `frontmatter` | chaîne | non | `preserve` par défaut, ou `translate`. |
| `prompt` | chaîne | non | Guidance supplémentaire pour cette portée ou cette règle. |
| `validation` | liste | pour les extensions de fichiers sans adaptateur préconstruit | Une commande de validation suivie de ses arguments. La commande reçoit le candidat à son réel chemin cible et doit retourner un statut non nul si le fichier est invalide. |
| `check_cmd` | chaîne | non | Une commande de vérification disponible au flux de travail de traduction. |
| `check_cmds` | mappe | non | Commandes de vérification nommées disponibles au flux de travail de traduction. |
| `retries` | entier | non | Nombre de tentatives de reprise après une vérification échouée. Par défaut `2`. |
| `locale` | chaîne | non | Locale attachée à un fichier de contexte spécifique à la locale. |

Les champs frontmatter inconnus sont ignorés.

## Formats de fichier

Glossia gère nativement Markdown, JavaScript Object Notation, YAML Ain't Markup Language, objet portable et fichiers texte plat. Les autres extensions échouent la planification sauf si la `GLOSSIA.md` déclarant une `validation` commande. Ceci évite de traiter silencieusement un format structuré propriétaire comme un texte non contraint.

La commande de validation s'exécute après que le candidat ait été écrit temporairement à son réel chemin cible. Il peut invoquer l'analyseur natif du dépôt, le compilateur ou la commande de construction. Glossia restaure la cible précédente après chaque tentative de validation et n'écrir le candidat accepté qu'ensuite.

## Traductions de sources

La forme la plus claire mappe chaque pattern de source à un modèle de sortie:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Une liste de sources est aussi valide, mais elle a besoin de `output` ou `target_path` pour définir la destination:

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Langues cibles

Une liste utilise chaque code de locale en tant qu'identifiant de langue :

```yaml
targets:
  - es
  - ja
```

Une carte peut ajouter un nom de langue lisible :

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variables de sortie

| Variable | Valeur |
|---|---|
| `{locale}` ou `{lang}` | Code de locale cible. |
| `{relpath}` | Chemin source relatif par rapport au modèle correspondant. |
| `{basename}` | Nom du fichier source sans son extension. |
| `{ext}` | Extension du fichier source sans le point. |

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

## Contexte spécifié

Glossia lit les fichiers `GLOSSIA.md` à partir de la racine du dépôt vers le fichier source :

- Les paramètres du parent fournissent des valeurs par défaut.
- Un fichier plus profond remplace les champs pour son répertoire.
- Le contexte Markdown est cumulatif du parent à l'enfant.
- Les orientations spécifiques à la locale et un gestionnaire de modèle spécifique à la locale peuvent résider dans `GLOSSIA/<locale>.md`.

Cela permet à un dépôt de conserver les orientations de voix générales à la racine tout en plaçant les orientations spécifiques aux zones de produit ou à la langue à proximité du contenu qu'elles affectent.