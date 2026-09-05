%{
  title: "Commandes",
  summary: "Référence pour toutes les commandes de ligne de commande Glossia et leurs options.",
  category: "Référence",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Créez un fichier de démarrage`GLOSSIA.md` de configuration pour le dépôt actuel.

```bash
glossia init
```

Échoue si `GLOSSIA.md` existe déjà.

## La traduction est côté serveur

La traduction s'exécute sur le serveur Glossia, pas dans l'interface en ligne de commande. Lorsqu'un commit est intégré,
Glossia planifie le travail à partir de vos `GLOSSIA.md` fichiers, traduit chaque fichier avec
le modèle de votre compte configuré, et ouvre une pull request avec les résultats. Vous
pouvez suivre chaque fichier et les réponses du modèle en direct sur la page de la session de traduction.

Le modèle est choisi par document : un `GLOSSIA.md` `model:` nommé par l'un de vos
modèle de votre compte le sélectionne ; sinon le modèle par défaut de votre compte est utilisé.

L'interface en ligne de commande n'organise, ne traduit, ne valide intentionnellement,
inspecte, ni supprimer les traductions générées. Elle ne lit pas non plus le serveur
fichiers de verrouillage de traduction.

## `glossia revisit`

Réservé pour un passage de révision de la langue source futur. Le terminal de commandes Rust
renvoie actuellement une erreur non implémentée pour cette commande.

```bash
glossia revisit
```

## Paramètres globaux

| Drapeau | Description |
|---|---|
| `--path <PATH>` | Remplacer le répertoire racine du projet |
| `--no-color` | Désactiver la sortie colorée |