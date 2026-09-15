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

Créez un fichier de démarrage `L10N.md` de configuration dans le dépôt actuel.

```bash
glossia init
```

Échoue si `L10N.md`déjà existe.

## La traduction est du côté serveur

La traduction s'exécute sur le serveur Glossia, pas dans l'interface en ligne de commande. Lorsqu'un commit est intégré,
Glossia planifie le travail à partir de vos `L10N.md` fichiers, traduit chaque fichier avec
le modèle configuré de votre compte et ouvre une demande de fusion avec les résultats. Vous
pouvez surveiller chaque fichier et les échanges du modèle en direct sur la page de session de traduction.

Le modèle est choisi par document : un `L10N.md` `model:` désignant l'un de vos
modèle de compte gère la sélection ; sinon le modèle par défaut de votre compte est utilisé.

L'interface en ligne de commande ne planifie, ne traduit, ne valide,@ -
examine, ni ne supprime les traductions générées. Elle ne lit également ni
les fichiers de verrouillage de traduction du serveur.

## `glossia revisit`

Réserver pour une future révision du source.
L'interface Rust renvoie actuellement une erreur non implémentée pour cette commande.

```bash
glossia revisit
```

## Options globales

| Option | Description |
|---|---|
| `--path <PATH>` | Définir le répertoire racine du projet |
| `--no-color` | Désactiver la sortie colorée |