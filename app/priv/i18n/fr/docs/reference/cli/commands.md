%{
  title: "Commandes",
  summary:
    "Référence pour toutes les commandes en ligne de commande de Glossia et leurs options.",
  category: "Référence",
  subcategory: "cli",
  order: 1
}
---

## `glossia init`

Créez un fichier de configuration `L10N.md` de démarrage dans le dépôt actuel.

```bash
glossia init
```

Échoue si `L10N.md` existe déjà.

## La traduction est côté serveur.

La traduction s'exécute dans le service Glossia hébergé, et non dans l'interface en ligne de commande. Lorsqu'un commit est enregistré, Glossia planifie le travail à partir de vos `L10N.md` fichiers, traduit chaque fichier avec le modèle configuré de votre compte, et ouvre une pull request avec les résultats. Vous pouvez suivre l'évolution de chaque fichier et les passages du modèle en direct sur la page de session de traduction.

Le modèle est choisi par document : un fichier `L10N.md` `model:` nommant l'un des gestionnaires de modèles de votre compte le sélectionne ; sinon, le modèle par défaut de votre compte est utilisé.

L'interface en ligne de commande ne planifie, ne traduit, ne valide, ne vérifie ni ne supprime intentionnellement aucune traduction générée. Elle ne lit également pas les fichiers de verrouillage de traduction publiés par Glossia.

## `glossia revisit`

Réservé pour une future révision de la langue source. L'interface en ligne de commande Rust renvoie actuellement une erreur non implémentée pour cette commande.

```bash
glossia revisit
```

## Drapeaux globaux

| Drapeau | Description |
|---|---|
| `--path <PATH>` | Surcharger le répertoire racine du projet |
| `--no-color` | Désactiver la sortie colorée |
