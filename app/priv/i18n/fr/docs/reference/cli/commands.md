%{
  title: "Commandes",
  summary: "Référence pour toutes les commandes en ligne de commande Glossia et leurs options.",
  category: "reference",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Créez un`GLOSSIA.md` fichier de configuration dans le dépôt actuel.

```bash
glossia init
```

Échoue si`GLOSSIA.md` existe déjà.

## La traduction est côté serveur

La traduction s'exécute sur le serveur Glossia, pas dans l'interface en ligne de commande. Lorsqu'un commit parvient,
Glossia planifie le travail à partir de vos`GLOSSIA.md` fichiers, traduit chaque fichier avec
le modèle configuré de votre compte, et ouvre une pull request avec les résultats. Vous
pouvez surveiller

un`GLOSSIA.md` `model:` un de vos
 modèle de gestion est sélectionné ; sinon le modèle par défaut de votre compte est utilisé.

L'interface en ligne de commande intentionnellement ne planifie pas, ne traduit pas, ne valide pas,
 du serveur
 fichiers de verrouillage de traduction.

## `glossia revisit`

Réservé pour une nouvelle passe de révision de la langue source.
l'interface renvoie actuellement une erreur non implémentée pour cette commande.

```bash
glossia revisit
```

## Drapeaux globaux

| Drapeau | Description |
|---|---|
||`--path <PATH>` | Remplacer le répertoire racine du projet |
| `--no-color` | Désactiver la sortie colorée |
