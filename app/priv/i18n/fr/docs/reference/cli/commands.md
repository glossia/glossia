%{
  title: "Commandes",
  summary:
    "Référence pour toutes les commandes en ligne de commande de Glossia et leurs options.",
  category: "référence",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Créer un modèle `L10N.md` fichier de configuration dans le dépôt actuel.

```bash
glossia init
```

Échoue si `L10N.md` le fichier existe déjà.

## La traduction est côté serveur.

La traduction s'exécute sur le serveur Glossia, pas dans l'interface en ligne de commande. Lorsqu'un commit est intégré,
Glossia planifie le travail à partir de vos `L10N.md` fichiers, traduit chaque fichier avec
le modèle configuré de votre compte, et ouvre une demande de fusion avec les résultats. Vous
pouvez surveiller chaque fichier et les tours du modèle en direct sur la page de session de traduction.

Le modèle est choisi par document : un `L10N.md` `model:` nomination d'un de vos
gestionnaires de modèles de votre compte sélectionnent celui-ci ; sinon le modèle par défaut de votre compte est utilisé.

L'interface de ligne de commande ne planifie pas intentionnellement, ne traduit pas, ne valide pas,
inspecter, ou supprimer les traductions générées. Elle ne lit pas non plus le serveur
fichiers de verrouillage de traduction.

## `glossia revisit`

Réservé pour un futur cycle de révision de la langue source. La commande de
l'interface Rust renvoie actuellement une erreur de fonction non implémentée pour cette commande.

```bash
glossia revisit
```

## Options globales

| Paramètre | Description |
|---|---|
| `--path <PATH>` | Définir le répertoire racine du projet |
| `--no-color` | Désactiver la sortie en couleurs |