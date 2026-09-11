%{
  title: "L10N.md",
  summary: "Référence pour les paramètres de traduction du dépôt et le contexte.",
  category: "référence",
  order: 1
}
---
`L10N.md` indique à Glossia quels fichiers traduire, où placer les fichiers traduits, quelles langues cibler et quel contexte guider le résultat. Un dépôt peut avoir un fichier racine et fichiers zoéiers supplémentaires dans les sous-dossiers.

## Structure

Chaque fichier a deux parties :

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre les marqueurs `---`.
2. Markdown sous le frontmatter avec le contexte produit, public cible, ton ou domaine.

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

Les identifiants du fournisseur appartiennent aux paramètres du compte, jamais dans `L10N.md`. La valeur optionnelle `model` est un identifiant de modèle de compte.

## Champs frontmatter

| Champ | Type | Requis | Description |
|---|---|---|---|
| `source_language` | string | non | Locale source pour ce domaine. Par défaut : `en`. |
| `model` | string | non | Identifiant de modèle de compte. Glossia utilise la valeur par défaut du compte si omis et signale une erreur si un identifiant explicite n'existe pas. |
| `sources` | map ou liste | pour une règle de niveau supérieur | Modèles de fichiers source. Les valeurs de map peuvent définir des modèles de sortie. |
| `targets` | map ou liste | lorsque les sources sont configurées | Codes de locales cibles. Une map peut associer un code de locale à un nom de langue. |
| `output` | string | lorsque aucun mappage de source ou `target_path` ne fournit une destination | Modèle de fichier de sortie. |
| `target_path` | string | lorsque aucun mappage de source ou `output` ne fournit une destination | Modèle de répertoire de base pour les fichiers traduits. |
| `translate` | liste | non | Plusieurs règles de traduction, chacune avec ses propres sources et overrides optionnels. |
| `exclude` | liste | non | Modèles de fichiers à sauter. |
| `preserve` | liste | non | Types de contenu qui doivent rester inchangés, tels que placeholders ou identifiants de ressources uniformes (URL). |
| `frontmatter` | string | non | `preserve` par défaut, ou `translate`. |
| `prompt` | string | non | Guider supplémentaire pour ce domaine ou cette règle. |
| `validation` | liste | pour les extensions de fichier sans adaptateur natif | Une commande de validation suivie de ses arguments. La commande reçoit le candidat à son chemin cible réel et doit retourner un statut non nul lorsque le fichier est invalide. |
| `check_cmd` | string | non | Une commande de vérification disponible pour le flux de traduction. |
| `check_cmds` | map | non | Commandes de vérification nommées disponibles pour le flux de traduction. |
| `retries` | entier | non | Nombre de tentatives de reprise après une vérification échouée. Par défaut : `2`. |
| `locale` | string | non | Locale attachée à un fichier de contexte spécifique à une locale. |

Les champs frontmatter inconnus sont ignorés.

## Formats de fichiers

Glossia gère nativement les fichiers Markdown, Objet Notation JSON, Langage YAML n'est pas Markdown, Objet Portable et fichiers texte brut. D'autres extensions échouent dans la planification sauf si le `L10N.md` applicable déclare une commande `validation`. Cela évite de traiter silencieusement un format structuré propriétaire comme du texte non contraint.

La commande de validation s'exécute après que le candidat a été écrit temporairement à son chemin cible réel. Elle peut invoquer l'analyseur natif, le compilateur ou la commande de construction du dépôt. Glossia restaure la cible précédente après chaque tentative de validation et écrit le candidat retenu uniquement ensuite.

## Mappages sources

La forme la plus claire établit une correspondance de chaque modèle source à un modèle de sortie :

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

Une liste utilise chaque code de localisation comme identifiant de langue: 

```yaml
targets:
  - es
  - ja
```

Un objet peut ajouter un nom de langue lisible: 

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variables de sortie

| Variable | Valeur |
|---|---|
| `{locale}` or `{lang}` | Code de locale cible. |
| `{relpath}` | Chemin source relatif au motif correspondant. |
| `{basename}` | Nom de fichier source sans son extension. |
| `{ext}` | Extension du fichier source sans le point initial. |

## Règles multiples

 Utilisez `translate` lorsque des groupes de contenu différents ont besoin de destinations ou de vérifications différentes: 

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

## Contexte attribué

Glossia lit `L10N.md` depuis la racine du dépôt vers le fichier source: 

- Les paramètres parents fournissent des valeurs par défaut. 
- Un fichier plus profond remplace les champs de son répertoire. 
- Le contexte Markdown s'accumule des parents aux enfants. 
- Des directives spécifiques à la localisation et un gestionnaire de modèle spécifique à la localisation peuvent résider dans `L10N/<locale>.md`. 

Cela permet à un dépôt de maintenir des directives de ton générales au niveau racine tout en plaçant des directives spécifiques au domaine ou à la langue à proximité du contenu qu'elles affectent.