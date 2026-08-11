%{
  title: "Commandes",
  summary: "Référence de toutes les commandes de ligne de commande Glossia et de leurs options.",
  category: "reference",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Créez un fichier de configuration `GLOSSIA.md` initial dans le dépôt actuel.

```bash
glossia init
```

Échoue si `GLOSSIA.md` existe déjà.

## La traduction s’effectue côté serveur

La traduction s’exécute sur le serveur Glossia, et non dans l’interface en ligne de commande. Lorsqu’un commit est intégré, Glossia planifie le travail à partir de vos fichiers `GLOSSIA.md`, traduit chaque fichier avec le modèle configuré pour votre compte et ouvre une pull request contenant les résultats. Vous pouvez suivre en direct chaque fichier et les interactions du modèle sur la page de la session de traduction.

Le modèle est choisi pour chaque document : un `GLOSSIA.md` `model:` indiquant l’un des identifiants de modèle de votre compte le sélectionne. Sinon, le modèle par défaut de votre compte est utilisé.

L’interface en ligne de commande ne planifie, ne traduit, ne valide, n’inspecte ni ne supprime intentionnellement les traductions générées. Elle ne lit pas non plus les fichiers de verrouillage de traduction du serveur.

## `glossia revisit`

Réservé à une future passe de révision dans la langue source. L’interface en ligne de commande Rust renvoie actuellement une erreur indiquant que cette commande n’est pas implémentée.

```bash
glossia revisit
```

## Options globales

| Option | Description |
|---|---|
| `--path <PATH>` | Remplacer le répertoire racine du projet |
| `--no-color` | Désactiver la sortie en couleur |