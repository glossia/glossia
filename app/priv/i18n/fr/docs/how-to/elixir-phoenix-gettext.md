%{
  title: "Elixir et Phoenix (Gettext)",
  summary:
    "Configurez la traduction Gettext, préservez les métadonnées du catalogue et réduisez les conflits de fusion.",
  category: "tutoriel",
  section: "ecosystems",
  order: 1
}
---

Utilisez ce guide pour connecter une application Elixir ou Phoenix existante via [Gettext](https://hexdocs.pm/gettext/) à Glossia et maintenez ses catalogues adaptables à la fusion. Exécutez les commandes Mix depuis le dossier contenant `mix.exs`.

## 1. Configurez l'extraction déterministe

Ajoutez ces options à votre configuration existante `project/0` dans `mix.exs` :

```elixir
def project do
  [
    # Keep the application's other project options here.
    gettext: [
      write_reference_line_numbers: false,
      sort_by_msgid: :case_sensitive
    ]
  ]
end
```

Conservez les autres options Gettext que vous utilisez déjà. `sort_by_msgid: :case_sensitive` est pris en charge par la version de Gettext utilisée par Glossia ; vérifiez les [options d'extraction](https://hexdocs.pm/gettext/Mix.Tasks.Gettext.Extract.html) de votre dépendance lorsque vous appliquez cela à un autre projet.

Régénérez les modèles et les fichiers de localisation :

```sh
mix gettext.extract --merge
```

Examinez et soumettez cette normalisation ponctuelle séparément des modifications de libellés. L'ordre des messages doit changer, pas les traductions existantes. Coordonnez cette normalisation avec les pull requests ouvertes afin que leurs catalogues puissent être mis à jour pour le même ordre.

Le tri place les nouveaux messages indépendants dans leurs positions canoniques au lieu d'ajouter chaque ajout à la fin du fichier. Omettre les numéros de ligne de référence évite les différences non connexes lorsque le code se déplace ; les références de fichiers sources restants. Ces options réduisent les conflits, mais ne peuvent pas éliminer les conflits sur le même message ni garantir que chaque paire d'insertions se fusionne automatiquement.

## 2. Traduisez les modèles, pas la source de l'application

Créez un `L10N.md` à côté de `mix.exs`, ou ajoutez les mappings suivants à votre configuration existante :

```yaml
---
source_language: en
sources:
  "priv/gettext/default.pot": "priv/gettext/{locale}/LC_MESSAGES"
  "priv/gettext/errors.pot": "priv/gettext/{locale}/LC_MESSAGES"
targets:
  - es
  - fr
---

Translate user-facing messages naturally and preserve all Gettext metadata.
Keep interpolation placeholders unchanged, including their names and syntax.
```

N'incluez que les domaines présents dans votre application. Ajoutez un mapping pour chaque domaine supplémentaire, tel que `dashboard_projects.pot`. La destination est un dossier : le gestionnaire d'objets portables y écrit `default.po`, `errors.po`, et d'autres noms de fichiers de domaine correspondants.

Utilisez `.pot` comme modèles sources et les fichiers `.po` de localisation comme sorties. N'utilisez pas une localisation traduite comme source pour d'autres localisations. Consultez la [référence L10N.md](/docs/reference/l10n-md) pour les configurations imbriquées et le [guide de prise en main](/docs/tutorials/getting-started) pour connecter le dépôt à Glossia.

## 3. Extraction avant la publication des modifications de source

Quand une pull request modifie un appel `gettext`, `dgettext`, ou `ngettext` :

1. Mettez à jour le code de l'application.
2. Exécutez `mix gettext.extract --merge`.
3. Examinez les diffs des modèles et des fichiers de localisation ensemble avec la modification de code.
4. Soumettez les modifications générées avant de fusionner la pull request.

Après la fusion des modifications de source, Glossia traduit les modèles actualisés et publie les modifications de localisation dans une pull request de traduction. Examinez ces traductions par le processus normal du dépôt.

Conservez `msgid` et `msgctxt` comme identifiants sources. Traduisez les valeurs `msgstr`, y compris les variantes plurielles requises. Préservez les marqueurs d'interpolation, les en-têtes de formes plurielles, les références sources, les commentaires des traducteurs et les drapeaux. Une entrée `fuzzy` nécessite une révision : ne retirez pas le drapeau juste pour qu'un contrôle passe, et n'assumez pas que sa traduction précédente est correcte pour un message modifié.

## 4. Validez les modifications de catalogue en CI

Exécutez :

```sh
mix gettext.extract --merge --check-up-to-date
mix compile --warnings-as-errors
```

Le contrôle d'extraction repère les modèles ou les fichiers de localisation qui ne correspondent plus à la source de l'application. La compilation vérifie que Gettext peut compiler les catalogues. Aucun de ces commandes ne vérifie la qualité linguistique ou prouve que chaque message a une traduction revue.

Si l'extraction signale des fichiers obsolètes, régénérez-les localement, examinez le diff, et soumettez-le. Ne contournez pas le contrôle ni réécrivez les modèles dans le travailleur de traduction à plusieurs reprises pour cacher un désalignement de source.

## 5. Résolvez les conflits de catalogue par l'identité du message

Quand vous mettez à jour une branche à partir de la branche par défaut :

1. Résolvez d'abord les conflits de source d'application, en préservant le texte d'interface utilisateur souhaité.
2. Réconciliez les entrées de catalogue des deux branches en utilisant leur contexte et l'identité du message source, y compris les identifiants pluriels s'ils sont présents. Conservez les traductions existantes, commentaires, drapeaux et formes plurielles ; retirez les marqueurs de conflit et les entrées en doublon avant de lancer l'analyseur.
3. Exécutez `mix gettext.extract --merge` sur la source résolue.
4. Exécutez les contrôles de CI ci-dessus et examinez le diff de catalogue résultant.

Ne résolvez pas un conflit de catalogue en acceptant entièrement et aveuglément un côté, en activant un pilote de fusion text-union, ou en concaténant les catalogues. Ces approches peuvent entraîner la perte de traductions valides, la duplication d'identifiants ou la conservation d'un fichier invalide. Pour les conflits récurrents, ajoutez un test de régression qui génère des catalogues sur deux branches avec de nouveaux messages différents et vérifie que Git fusionne à la fois le modèle et le catalogue traduit sans perdre d'entrées.
