%{
  title: "L10N.md",
  summary: "Référence pour les paramètres de traduction du dépôt et le contexte.",
  category: "référence",
  order: 1
}
---
`L10N.md` indique à Glossia quels fichiers traduire, où appartiennent les fichiers traduits, quelles langues cibler et quel contexte doit se servir comme guide pour les résultats. Un dépôt peut avoir un fichier racine et des fichiers supplémentaires répartis dans des sous-répertoires.

## Structure

Chaque fichier dispose de deux parties :

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre les `---` marqueurs.
2. Markdown après le frontmatter avec un contexte produit, public, ton ou domaine.

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

Les identifiants de fournisseur appartiennent aux paramètres de compte, jamais dans `L10N.md`. La valeur optionnelle `model` est une poignée de modèle de compte.

## Champs de frontmatter

| Champ | Type | Requis | Description |
|---|---|---|---|
| `source_language` | string | oui | Couleur locale source pour cette portée. Par défaut `en`. |
| `model` | string | non | Poignée de modèle de compte. Glossia utilise le défaut du compte si omis et signale une erreur si la poignée explicite n'existe pas. |
| `sources` | mapping ou liste | pour une règle de niveau supérieur | Modèles de fichiers sources. Les valeurs du mapping peuvent définir des modèles de sortie. |
| `targets` | mapping ou liste | quand les sources sont configurées | Codes de locale cible. Un mapping peut associer un code de locale à un nom de langue. |
| `output` | string | quand aucun mappage source ou `target_path` n'apporte une destination | Modèle de fichier de sortie. |
| `target_path` | string | quand aucun mappage source ou `output` n'apporte une destination | Modèle de répertoire de base pour les fichiers traduits. |
| `translate` | liste | non | Règles de traduction multiples, chacune avec ses propres sources et des overrides optionnels. |
| `exclude` | liste | non | Modèles de fichiers à sauter. |
| `preserve` | liste | non | Types de contenu qui doivent rester inchangés, comme des placeholders ou des uniform resource locators (URLs). |
| `frontmatter` | string | non | `preserve` par défaut, ou `translate`. |
| `prompt` | string | non | Guidance supplémentaire pour cette portée ou règle. |
| `validation` | liste | pour des extensions de fichiers sans adaptation intégrée | Une commande de validation suivie de ses arguments. La commande reçoit le candidat à son véritable chemin cible et doit retourner une valeur d'état non nulle si le fichier est invalide. |
| `check_cmd` | string | non | Une commande de vérification disponible au processus de traduction. |
| `check_cmds` | mapping | non | Commandes de vérification nommées disponibles au processus de traduction. |
| `retries` | entier | non | Nombre de tentatives de reprise après une vérification échouée. Par défaut `2`. |
| `locale` | string | non | Locale attachée à un fichier de contexte spécifique à la locale. |

Les champs de frontmatter inconnus sont ignorés.

## Formats de fichiers

Glossia dispose d'une gestion intégrée pour Markdown, Objet JavaScript Notation, YAML Ain't Markup Language, objet portable et fichiers texte plain. D'autres extensions de fichiers échouent à l'organisation à moins que le applicable `L10N.md` déclare une `validation` command. Cela évite de traiter silencieusement un format structuré propriétaire comme un texte non contraint.

La commande de validation s'exécute après que le candidat a été écrit temporairement à son vrai chemin cible. Il peut invoquer le parseur, compilateur ou commande de construction native du dépôt. Glossia restaure la cible précédente après chaque tentative de validation et n'écrit le candidat accepté qu'ensuite.

## Mappages de sources

La forme la plus claire mappe chaque modèle source à un modèle de sortie :

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

Une liste utilise chaque code de localisation comme identifiant de langue :

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
| `{locale}` ou `{lang}` | Code de localisation cible. |
| `{relpath}` | Chemin source relatif au motif correspondant. |
| `{basename}` | Nom de fichier source sans son extension. |
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

Les valeurs de règle écrasent les valeurs issues du fichier environnant.

## Contexte de portée

Glossia lit les fichiers `L10N.md` depuis la racine du dépôt jusqu'au fichier source :

- Les paramètres parents fournissent des valeurs par défaut.
- Un fichier plus profond surcharge les champs de son répertoire.
- Le contexte Markdown est accumulé du parent vers le descendant.
- Les directives spécifiques à la localisation et un gestionnaire de modèle spécifique à la langue peuvent se trouver dans `L10N/<locale>.md`.

Cela permet à un dépôt de conserver des directives de ton générales à la racine tout en plaçant des directives spécifiques au domaine produit ou à la langue à proximité du contenu qu'elles concernent.