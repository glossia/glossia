%{
  title: "Commandes",
  summary: "Référence pour toutes les commandes en ligne de commande Glossia et leurs drapeaux.",
  category: "Référence",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Créer un fichier de démarrage `L10N.md` configuration file

```bash
glossia init
```

Echoue si `L10N.md` existe déjà.

## La traduction se fait côté serveur

La traduction s'exécute sur le serveur Glossia, pas dans l'interface en ligne de commande. Lorsqu'un commit arrive,
Glossia planifie le travail à partir de votre `L10N.md` files,
traduit chaque fichier avec
le modèle configuré de votre compte, et ouvre une pull request avec les résultats. Vous pouvez surveiller chaque fichier et les tours du modèle en temps réel sur la page de session de traduction.

Le modèle est choisi par document : a `L10N.md` `model:` nommant l'un de vos
modèle de gestion du compte sélectionne celui-ci ; sinon le modèle par défaut du compte est utilisé.

L'interface en ligne de commande ne planifie, ne traduit, ne valide,
inspecte, ou supprime les traductions générées. Elle ne lit pas non plus les
fichiers de verrouillage de traduction.

## `glossia revisit`

Réservé pour un future passage de révision de la langue source.
L'interface en ligne de commande en Rust retourne actuellement une erreur non implémentée pour cette commande.

```bash
glossia revisit
```

## Paramètres globaux

| Paramètre | Description |
|---|---|
| `--path <PATH>` | Remplacer le répertoire racine du projet |
| `--no-color` | Désactiver la sortie colorée |