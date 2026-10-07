%{
  title: "Commandes",
  summary:
    "Référence pour toutes les commandes en ligne de commande de Glossia et leurs drapeaux.",
  category: "Référence",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Créer un modèle `L10N.md` fichier de configuration dans le dépôt actuel.

```bash
glossia init
```

Échoue si `L10N.md` il existe déjà.

## La traduction est côté serveur.

La traduction s'exécute dans le service Glossia hébergé, et non dans l'interface en ligne de commande. Lorsqu'un commit atterrit,
Glossia planifie le travail à partir de vos `L10N.md` fichiers, traduit chaque fichier avec
le modèle configuré de votre compte, et ouvre une demande de tirage avec les résultats. Vous
pouvez surveiller chaque fichier et les passes du modèle en direct sur la page de session de traduction.

Le modèle est choisi par document : a `L10N.md` `model:` en sélectionnant l'un de vos
le gestionnaire de modèle du compte sélectionne ; sinon le modèle par défaut de votre compte est utilisé.

L'interface de ligne de commande ne planifie pas intentionnellement, ne traduit pas, ne valide pas,
inspecter, ou supprimer les traductions générées. Elle ne lit pas non plus les fichiers de verrouillage de traduction publiés par Glossia.

## `glossia revisit`

Réservé pour une future passe de révision de la langue source. La ligne de commande Rust
L'interface renvoie actuellement une erreur non implémentée pour cette commande.

```bash
glossia revisit
```

## Options globales

| Option | Description |
|---|---|
| `--path <PATH>` | Définir le répertoire racine du projet |
| `--no-color` | Désactiver la sortie en couleur |