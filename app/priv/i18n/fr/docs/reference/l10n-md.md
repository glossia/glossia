%{
  title: "L10N.md",
  summary: "Référence relative aux paramètres de traduction du dépôt et du contexte.",
  category: "référence",
  order: 1
}
---
`L10N.md` indique à Glossia quels fichiers traduire, où se trouvent les fichiers traduits, quelles langues cibler et quel contexte doit guider le résultat. Un dépôt peut avoir un fichier racine et des fichiers à portée supplémentaires dans des sous-répertoires.

## Structure

Chaque fichier se compose de deux parties :

1. [YAML n'est pas un langage de balisage](https://yaml.org/) frontmatter entre `---` marqueurs.
2. Markdown sous la frontmatter avec le produit, le public, la voix ou le contexte de domaine.

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

Les identifiants du fournisseur relèvent des paramètres du compte, jamais dans `L10N.md`. L'optionnel `model` valeur est un identifiant de modèle de compte.

## Champs frontmatter

| Champ | Type | Requis | Description |
|---|---|---|---|
| `source_language` | string | non | Localisation source pour cette portée. Par défaut `en`. |
| `model` | chaîne | non | Handle du modèle de compte. Glossia utilise la valeur par défaut du compte lorsqu'il est omis et signale une erreur lorsqu'un handle explicite n'existe pas. |
| `sources` | map ou liste | pour une règle de haut niveau | Modèles de fichiers sources. Les valeurs de map peuvent définir des modèles de sortie. |
| `targets` | map ou liste | lorsque les sources sont configurées | Codes de localisation cibles. Une map peut associer un code de localisation à un nom de langue. |
| `output` | chaîne | lorsqu'aucun mappage de source ou `target_path` fournit une destination | Modèle de fichier de sortie. |
| `target_path` | string | lorsqu'il n'y a pas de correspondance de source ou `output` fournit une destination | Modèle de répertoire de base pour les fichiers traduits. |
| `translate` | list | no | Plusieurs règles de traduction, chacune avec ses propres sources et des surcharges optionnelles. |
| `exclude` | list | no | Motifs de fichiers à ignorer. |
| `preserve` | liste | non | Types de contenu qui doivent rester inchangés, tels que les placeholders ou les localisateurs de ressources uniformes. |
| `frontmatter` | chaîne | non | `preserve` par défaut, ou `translate`. |
| `prompt` | chaîne | non | Conseils supplémentaires pour cette portée ou règle. |
| `validation` | list | pour les extensions de fichier sans adaptateur intégré | Une commande de validation suivie de ses arguments. La commande reçoit le candidat à son chemin cible réel et doit retourner un statut non nul lorsque le fichier est invalide. |
| `check_cmd` | string | no | Une commande de vérification disponible pour le flux de travail de traduction. |
| `check_cmds` | map | no | Commandes de vérification nommées disponibles pour le flux de travail de traduction. |
| `retries` | integer | no | Nombre de tentatives de reprise après une vérification échouée. Par défaut à `2`. |
| `locale` | Chaîne | non | Localisation attachée à un fichier de contexte spécifique à la localisation. |

Les champs frontmatter inconnus sont ignorés.

## Formats de fichiers

Glossia prend nativement en charge Markdown, notation d'objet JavaScript, YAML n'est pas un langage de balisage, objets portables et fichiers texte simples. Les autres extensions de fichiers échouent lors de la planification à moins que l'extension applicable `L10N.md` déclare un `validation` commande. Cela évite de traiter un format structuré propriétaire comme du texte non contraint.

La commande de validation s'exécute après que le candidat ait été écrit temporairement dans son chemin cible réel. Elle peut invoquer l'analyseur natif, le compilateur ou la commande de construction du dépôt. Glossia restaure la cible précédente après chaque tentative de validation et n'écrit le candidat accepté qu'ensuite.

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

Toute liste utilise chaque code locale comme identifiant de la langue :

```yaml
targets:
  - es
  - ja
```

Une association peut ajouter un nom de langue lisible :

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variables de sortie

| Variable | Valeur |
|---|---|
| `{locale}` ou `{lang}` | Code de la locale cible. |
| `{relpath}` | Chemin de la source relatif au motif de correspondance. |
| `{basename}` | Nom du fichier source sans extension. |
| `{ext}` | Extension du fichier source sans le point initial. |

## Règles multiples

Utilisez `translate` lorsque différents groupes de contenu ont besoin de destinations ou de vérifications différentes :

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

- Les paramètres parentels fournissent des valeurs par défaut.
- Un fichier plus profond remplace les champs pour son répertoire.
- Le contexte de Markdown est accumulé du parent à l’enfant.
- La guidance spécifique à la locale et un gestionnaire de modèle spécifique à la locale peuvent résider dans `L10N/<locale>.md`.

Cela permet à un dépôt de conserver des directives de voix larges à la racine tout en plaçant les directives de produit ou spécifiques à la langue à proximité du contenu qu'elles affectent.