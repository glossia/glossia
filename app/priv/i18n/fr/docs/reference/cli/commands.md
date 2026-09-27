%{
  title: "Commandes",
  summary:
    "Référence pour toutes les commandes de ligne de commande Glossia et de leurs options.",
  category: "référence",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Créer un fichier de démarrage `L10N.md` de configuration dans le dépôt actuel.

```bash
glossia init
```

Échoue si `L10N.md` il existe déjà.

## La traduction est côté serveur

La traduction s'exécute sur le serveur Glossia, et non dans l'interface de ligne de commande. Lorsqu'un commit est déposé,
Glossia planifie le travail à partir de vos `L10N.md` fichiers, traduit chaque fichier avec
votre modèle configuré pour le compte, et ouvre une pull request avec les résultats. Vous
pouvez surveiller chaque fichier et les tours du modèle en direct sur la page de session de traduction.

Le modèle est choisi par document : un `L10N.md` `model:` en nommant l'un de vos
gestionnaires de modèle de compte le sélectionnent ; sinon le modèle par défaut du compte est utilisé.

L'interface de ligne de commande n'essaie délibérément pas de planifier, traduire, valider,
inspecter, ni supprimer les traductions générées. Elle ne lit pas le serveur
fichiers de verrouillage de traduction.

## `glossia revisit`

Réservé pour une future révision de la langue source. La ligne de commande Rust
l'interface retourne actuellement une erreur non implémentée pour cette commande.

```bash
glossia revisit
```

## Options globales

| Option | Description |
|---|---|
| `--path <PATH>` | Définir le répertoire racine du projet |
| `--no-color` | Désactiver la sortie colorée |