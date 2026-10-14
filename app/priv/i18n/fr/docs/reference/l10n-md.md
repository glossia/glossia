%{
  title: "L10N.md",
  summary: "Référence pour les paramètres de traduction du dépôt et le contexte.",
  category: "Référence",
  section: "translation",
  order: 1
}
---

`L10N.md` indique à Glossia quels fichiers traduire, où ils appartiennent, quelles langues cibler et quel contexte doit guider le résultat. Un dépôt peut avoir un fichier racine et des fichiers supplémentaires à portée dans les sous-répertoires.

## Structure

Chaque fichier comporte deux parties :

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre `---` marqueurs.
2. Markdown en dessous du frontmatter avec le contexte du produit, du public, de la tonalité ou du domaine.

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

Les identifiants de fournisseur appartiennent aux paramètres de compte, jamais dans `L10N.md`. La valeur facultative `model` est un identifiant de modèle de compte.

## Champs du frontmatter

| Champ | Type | Obligatoire | Description |
|---|---|---|---|
| `source_language` | chaîne | non | Locale source pour cette portée. Par défaut à `en`. |
| `model` | chaîne | non | Identifiant de modèle de compte. Glossia utilise la valeur par défaut du compte lorsqu'il est omis et signale une erreur lorsqu'un identifiant explicite n'existe pas. |
| `sources` | tableau ou liste | pour une règle de niveau supérieur | Modèles de fichiers source. Les valeurs de la carte peuvent définir des modèles de sortie. |
| `targets` | tableau ou liste | lorsque les sources sont configurées | Codes de locale cible. Une carte peut associer un code de locale à un nom de langue. |
| `output` | chaîne | lorsqu'aucune correspondance source ou `target_path` ne fournit une destination | Modèle de fichier de sortie. |
| `target_path` | chaîne | lorsqu'aucune correspondance source ou `output` ne fournit une destination | Modèle de répertoire de base pour les fichiers traduits. |
| `translate` | liste | non | Plusieurs règles de traduction, chacune avec ses propres sources et redéfinitions optionnelles. |
| `exclude` | liste | non | Modèles de fichier à sauter. |
| `preserve` | liste | non | Types de contenu qui doivent rester inchangés, tels que les espaces réservés ou les identifiants de ressources uniformes. |
| `frontmatter` | chaîne | non | `preserve` par défaut, ou `translate`. |
| `prompt` | chaîne | non | Conseils supplémentaires pour cette portée ou règle. |
| `validation` | liste | pour les extensions de fichier sans adaptateur intégré | Une commande de validation suivie de ses arguments. La commande reçoit le candidat à son réel chemin de cible et doit retourner un statut non nul lorsque le fichier est invalide. |
| `check_cmd` | chaîne | non | Une commande de contrôle disponible pour le flux de travail de traduction. |
| `check_cmds` | carte | non | Commandes de contrôle nommées disponibles pour le flux de travail de traduction. |
| `retries` | entier | non | Nombre de tentatives de réessaimage après une vérification échouée. Par défaut à `2`. |
| `locale` | chaîne | non | Locale attachée à un fichier de contexte spécifique au contexte local. |
| `glossary` | tableau ou carte | non | Dans `L10N.md`, une liste de termes du glossaire. Dans `L10N/<locale>.md`, une carte de chaque terme vers sa traduction dans cette langue. Les fichiers imbriqués ajoutent à et remplacent les entrées héritées. Voir la [référence du glossaire](/docs/reference/glossary). |

Les champs inconnus du frontmatter sont ignorés.

## Formats de fichiers

Glossia intègre un traitement pour Markdown, JavaScript Object Notation, YAML Ain't Markup Language, objets portables et fichiers de texte brut. Les autres extensions de fichiers échouent lors de la planification sauf si le `L10N.md` applicable déclare une commande `validation`. Cela évite de traiter silencieusement un format structuré propriétaire comme du texte non contraint.

En Markdown, seul le texte est traduit : paragraphes, titres, éléments de liste, cellules de tableau, ainsi que les attributs `title`, `details`, `alt`, `label`, `description`, `summary`, `placeholder`, `aria-label` et `caption` des composants et du HTML, ainsi que le texte d'un `<summary>` HTML. Tout autre octet, y compris le code, les destinations de liens, les composants, les alertes et les ancres de titre explicites, est conservé exactement tel quel dans la source. Voir [récupération de traduction](/docs/explanation/translation-recovery) pour comprendre comment cela fonctionne.

La commande de validation s'exécute après que le candidat ait été écrit temporairement à son réel chemin de cible. Il peut invoker le parseur natif, le compilateur, ou la commande de build du dépôt. Glossia restaure la cible précédente après chaque tentative de validation et n'écrit le candidat accepté qu'ensuite.

## Mappages de source

La forme la plus claire rapproche chaque motif de source vers un modèle de sortie :

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Une liste de source est également valide, mais elle a besoin de `output` ou `target_path` pour définir la destination :

```yaml
sources:
  - "docs/**/*.md"
target_path: "docs/i18n/{locale}"
```

## Langues cibles

Une liste utilise chaque code de locale comme son identifiant de langue :

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
| `{relpath}` | Chemin de source par rapport au motif correspondu. |
| `{basename}` | Nom de fichier source sans son extension. |
| `{ext}` | L'extension de fichier source sans le point initial. |

## Règles multiples

Utilisez `translate` lorsque des groupes de contenu différents ont besoin de destinations ou de contrôles différents :

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

Les valeurs de règle surclassent les valeurs héritées du fichier environnant.

## Contexte de portée

Glossia lit les fichiers `L10N.md` depuis la racine du dépôt vers le fichier source :

- Les paramètres parents fournissent des valeurs par défaut.
- Un fichier plus profond surcharge les champs du répertoire.
- Le contexte Markdown est accumulé du parent vers l'enfant.
- Les directives spécifiques à l'locale et un gestionnaire de modèle spécifique à l'locale peuvent résider dans `L10N/<locale>.md`.

Cela permet à un dépôt de conserver des directives de voix générales à la racine tout en plaçant des directives spécifiques à la zone de produit ou à la langue à proximité du contenu qu'elles affectent.
