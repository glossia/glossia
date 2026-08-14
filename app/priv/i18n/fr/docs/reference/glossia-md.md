%{
  title: "GLOSSIA.md",
  summary: "Référence des paramètres et du contexte de traduction du dépôt.",
  category: "reference",
  order: 1
}
---
`GLOSSIA.md` indique à Glossia quels fichiers traduire, où placer les fichiers traduits, quelles langues cibler et quel contexte doit guider le résultat. Un dépôt peut contenir un fichier racine et des fichiers supplémentaires limités à certains sous-répertoires.

## Structure

Chaque fichier comporte deux parties :

1. Des métadonnées liminaires au format [YAML Ain't Markup Language](https://yaml.org/) entre des marqueurs `---`.
2. Du Markdown sous les métadonnées liminaires, avec le contexte relatif au produit, au public, à la voix ou au domaine.

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

Les identifiants du fournisseur doivent figurer dans les paramètres du compte, jamais dans `GLOSSIA.md`. La valeur facultative `model` est un identifiant de modèle du compte.

## Champs des métadonnées liminaires

| Champ | Type | Obligatoire | Description |
|---|---|---|---|
| `source_language` | chaîne | non | Locale source pour cette portée. Valeur par défaut : `en`. |
| `model` | chaîne | non | Identifiant de modèle du compte. Glossia utilise le modèle par défaut du compte lorsqu'il est omis et signale une erreur lorsqu'un identifiant explicite n'existe pas. |
| `sources` | table de correspondance ou liste | pour une règle de premier niveau | Motifs des fichiers sources. Les valeurs de la table de correspondance peuvent définir des modèles de sortie. |
| `targets` | table de correspondance ou liste | lorsque des sources sont configurées | Codes des locales cibles. Une table de correspondance peut associer un code de locale à un nom de langue. |
| `output` | chaîne | lorsqu'aucune correspondance de source ou aucun `target_path` ne fournit de destination | Modèle de fichier de sortie. |
| `target_path` | chaîne | lorsqu'aucune correspondance de source ou aucun `output` ne fournit de destination | Modèle de répertoire de base pour les fichiers traduits. |
| `translate` | liste | non | Plusieurs règles de traduction, chacune avec ses propres sources et d'éventuelles substitutions. |
| `exclude` | liste | non | Motifs de fichiers à ignorer. |
| `preserve` | liste | non | Types de contenu qui doivent rester inchangés, tels que les espaces réservés ou les localisateurs uniformes de ressources. |
| `frontmatter` | chaîne | non | `preserve` par défaut, ou `translate`. |
| `prompt` | chaîne | non | Instructions supplémentaires pour cette portée ou cette règle. |
| `validation` | liste | pour les extensions de fichier sans adaptateur intégré | Une commande de validation suivie de ses arguments. La commande reçoit le fichier candidat à son chemin cible réel et doit renvoyer un état différent de zéro lorsque le fichier n'est pas valide. |
| `check_cmd` | chaîne | non | Une commande de vérification disponible pour le processus de traduction. |
| `check_cmds` | table de correspondance | non | Des commandes de vérification nommées disponibles pour le processus de traduction. |
| `retries` | entier | non | Nombre de nouvelles tentatives après l'échec d'une vérification. Valeur par défaut : `2`. |
| `locale` | chaîne | non | Locale associée à un fichier de contexte propre à une locale. |

Les champs inconnus des métadonnées liminaires sont ignorés.

## Formats de fichiers

Glossia prend nativement en charge les fichiers Markdown, JavaScript Object Notation, YAML Ain't Markup Language, Portable Object et texte brut. Pour les autres extensions de fichier, la planification échoue sauf si le `GLOSSIA.md` applicable déclare une commande `validation`. Cela évite de traiter silencieusement un format structuré propriétaire comme du texte sans contraintes.

La commande de validation s'exécute après l'écriture temporaire du fichier candidat à son chemin cible réel. Elle peut appeler l'analyseur syntaxique, le compilateur ou la commande de compilation native du dépôt. Glossia restaure la cible précédente après chaque tentative de validation et n'écrit le fichier candidat accepté qu'ensuite.

## Correspondances des sources

La forme la plus claire associe chaque motif source à un modèle de sortie :

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

Une liste utilise chaque code de paramètres régionaux comme identifiant de langue :

```yaml
targets:
  - es
  - ja
```

Une table de correspondance peut ajouter un nom de langue lisible :

```yaml
targets:
  es: Spanish
  ja: Japanese
```

## Variables de sortie

| Variable | Valeur |
|---|---|
| `{locale}` ou `{lang}` | Code des paramètres régionaux cibles. |
| `{relpath}` | Chemin de la source relatif au motif correspondant. |
| `{basename}` | Nom du fichier source sans son extension. |
| `{ext}` | Extension du fichier source sans le point initial. |

## Règles multiples

Utilisez `translate` lorsque différents groupes de contenu nécessitent des destinations ou des vérifications distinctes :

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

Les valeurs de la règle remplacent les valeurs héritées du fichier englobant.

## Contexte délimité

Glossia lit les fichiers `GLOSSIA.md` depuis la racine du dépôt jusqu’au fichier source :

- Les paramètres parents fournissent les valeurs par défaut.
- Un fichier situé plus profondément remplace les champs pour son répertoire.
- Le contexte Markdown est accumulé du parent vers l’enfant.
- Les consignes propres aux paramètres régionaux et un identifiant de modèle propre à ces paramètres peuvent être placés dans `GLOSSIA/<locale>.md`.

Cela permet à un dépôt de conserver des consignes générales relatives à la voix à la racine, tout en plaçant les consignes propres à une partie du produit ou à une langue à proximité du contenu concerné.