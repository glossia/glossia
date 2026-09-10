%{
  title: "Commandes",
  summary: "Référence pour toutes les commandes en ligne de commande Glossia et leurs options.",
  category: "référence",
  subcategory: "cli",
  order: 1
}
---
## `glossia init`

Créer un`L10N.md` fichier de configuration dans le dépôt actuel.

```bash
glossia init
```

échoue si`L10N.md`déjà existe.

## Traduction côté serveur

La traduction s'exécute sur le serveur Glossia, pas dans l'interface en ligne de commande. Lorsqu'un engagement arrive,
Glossia planifie le travail à partir de vos`L10N.md` fichiers, traduit chaque fichier avec
le modèle configuré de votre compte, et ouvre une pull request avec les résultats.
 pouvez surveiller chaque fichier et les tours du modèle en direct sur la page de session de traduction.

Le modèle est choisi par document: un`L10N.md` `model:` nommant l'un de vos
modèle de compte sélectionné le gère; sinon, le modèle par défaut de votre compte est utilisé.

La CLI ne planifie, ne traduit, ne valide,
 examine, ni supprime les traductions générées. Elle ne lit pas non plus
 les verrous de traduction du serveur.

## `glossia revisit`

Réserver
 en Rust

```bash
glossia revisit
```

## Paramètres globaux

| Flag | Description |
|---|---|
| `--path <PATH>` | Surcharger le répertoire racine du projet |
| `--no-color` | Désactiver la coloration de la sortie |