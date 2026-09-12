%{
  title: "L10N.md",
  summary: "Référence pour les paramètres de traduction du dépôt et le contexte.",
  category: "Référence",
  order: 1
}
---
`L10N.md` indique à Glossia quels fichiers traduire, où les fichiers traduits appartiennent, les langues à cibler et le contexte qui devrait guider le résultat. Un dépôt peut avoir un fichier racine et des fichiers scopés supplémentaires dans des sous-répertoires.

## Structure

Chaque fichier a deux parties:

1. [YAML Ain't Markup Language](https://yaml.org/) frontmatter entre `---` marqueurs.
2. Markdown sous la frontmatter avec contexte produit, public, voix ou domaine.

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
| `source_language` | string | non | Locale source pour cette portée. Défaut à `en`. |
| `model` | string | non | Identifiant de modèle de compte. Glossia utilise le défaut du compte si omis et signale une erreur si un identifiant explicite n'existe pas. |
| `sources` | map ou list | pour une règle de niveau supérieur | Modèles de fichiers source. Les valeurs map peuvent définir des modèles de sortie. |
| `targets` | map ou list | lorsque sources sont configurées | Codes de locale cible. Une map peut associer un code de locale à un nom de langue. |
| `output` | string | lorsque pas de mappage source ou `target_path` fournit une destination | Modèle de fichier de sortie. |
| `target_path` | string | lorsque pas de mappage source ou `output` fournit une destination | Modèle de dossier de base pour les fichiers traduits. |
| `translate` | list | non | Plusieurs règles de traduction, chacune avec ses propres sources et overrides optionnels. |
| `exclude` | list | non | Modèles de fichiers à exclure. |
| `preserve` | list | non | Types de contenu qui doivent rester inchangés, tels que des placeholders ou des uniform resource locators. |
| `frontmatter` | string | non | `preserve` par défaut, ou `translate`. |
| `prompt` | string | non | Guidance supplémentaire pour cette portée ou règle. |
| `validation` | list | pour des extensions de fichiers sans adaptateur intégré | Une commande de validation suivie de ses arguments. La commande reçoit le candidat à son véritable chemin de cible et doit retourner un statut non nul lorsque le fichier est invalide. |
| `check_cmd` | string | non | Une commande de vérification disponible pour le flux de traduction. |
| `check_cmds` | map | non | Commandes de vérification nommées disponibles pour le flux de traduction. |
| `retries` | entier | non | Nombre de tentatives de réessai après une vérification échouée. Défaut à `2`. |
| `locale` | string | non | Locale attachée à un fichier de contexte spécifique à cette locale. |

Les champs frontmatter inconnus sont ignorés.

## Formats de fichiers

Glossia possède une prise en charge native de Markdown, JavaScript Object Notation, YAML Ain't Markup Language, objet portable et fichiers de texte brut. D'autres extensions échouent la planification à moins que `L10N.md` déclare une `validation` command. Cela évite de traiter silencieusement un format structuré propriétaire comme du texte sans contraintes.

La commande de validation s'exécute après que le candidat ait été écrit temporairement à son véritable chemin de cible. Elle peut invoquer l'analyseur natif, le compilateur ou la commande de build du dépôt. Glossia restaure la cible précédente après chaque tentative de validation et n'écrit le candidat accepté qu'ensuite.

## Mappings des sources

La forme la plus claire mappe chaque modèle source à un modèle de sortie:

```yaml
sources:
  "docs/**/*.md": "docs/i18n/{locale}/{relpath}"
  "content/*.json": "content/{locale}/{basename}.{ext}"
```

Une liste de sources est également valide, mais elle a besoin `output` ou `target_path` pour définir la destination:

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

Une mapping peut ajouter un nom de langue lisible:

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

Utilisez `translate` lorsque des groupes de contenu différents nécessitent des destinations ou des vérifications différentes:

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

## Contexte de portée

Glossia lit `L10N.md` à partir de la racine du dépôt vers le fichier source:

- Les paramètres du parent fournissent des valeurs par défaut.
- Un fichier plus profond surcharge les champs de son dossier.
- Le contexte Markdown est accumulé du parent à l'enfant.
- les conseils spécifiques à la localisation et un gestionnaire de modèle spécifique à la localisation`L10N/<locale>.md` .

Cela permet à un dépôt de conserver des orientations vocales larges à la racine tout en plaçant les conseils spécifiques à un domaine produit ou à une langue à proximité du contenu qu'ils affectent.