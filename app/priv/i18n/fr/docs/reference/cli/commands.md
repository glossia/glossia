%{
  title: "Commandes",
  summary:
    "Référence pour toutes les commandes en ligne de commande de Glossia et leurs drapeaux.",
  category: "Référence",
  subcategory: "CLI",
  order: 1
}
---
## `glossia init`

Créer un fichier de configuration de démarrage `L10N.md` dans le dépôt actuel.

```bash
glossia init
```

Échoue si `L10N.md` existe déjà.

## La traduction est côté serveur

La traduction s'exécute sur le serveur Glossia, et non dans l'interface en ligne de commande. Lorsqu'un commit est reçu,
Glossia planifie le travail à partir de vos `L10N.md` fichiers, traduit chaque fichier avec
le modèle configuré sur votre compte, et ouvre une demande de tirage avec les résultats. Vous
pouvez surveiller chaque fichier et les tours du modèle en direct sur la page de session de traduction.

Le modèle est choisi par document : un `L10N.md` `model:` désignant l'un des modèles de votre
compte sélectionné ; sinon, le modèle par défaut du compte est utilisé.

L'interface en ligne de commande n'intentionnellement pas planifier, traduire, valider,
inspecter, ni supprimer les traductions générées. Elle ne lit également pas les 
clous de verrouillage de traduction.

## `glossia revisit`

Réserver à un futur passage de révision de la langue source. L'interface en ligne de commande en Rust
retourne actuellement une erreur pour cette commande non implémentée.

```bash
glossia revisit
```

## Paramètres globaux

| Paramètre | Description |
|---|---|
| `--path <PATH>` | Remplacer le dossier racine du projet |
| `--no-color` | Désactiver la couleur de la sortie |