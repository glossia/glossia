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

Créez un fichier de configuration de départ `L10N.md` dans le dépôt actuel.

```bash
glossia init
```

Échoue si `L10N.md` existe déjà.

## Traduction côté serveur

La traduction s'exécute sur le serveur Glossia, et non dans l'interface en ligne de commande. Lorsqu'un commit est intégré,
Glossia planifie le travail à partir de vos fichiers `L10N.md`, traduit chaque fichier avec
le modèle configuré de votre compte, et ouvre une demande de fusion avec les résultats. Vous
pouvez suivre chaque fichier et les itérations du modèle en direct sur la page de session de traduction.

Le modèle est choisi par document : un `L10N.md` dans `model:` nommant l'un de vos
identifiants de modèle de compte le sélectionne ; sinon, le modèle par défaut de votre compte est utilisé.

L'interface en ligne de commande ne planifie, ne traduit, ne valide,
n'inspecte ni ne supprime intentionnellement les traductions générées. Elle ne lit pas non plus les
fichiers de verrouillage de traduction du serveur.

## `glossia revisit`

Réservé pour une future révision de langue source. L'interface de ligne de commande
en Rust retourne actuellement une erreur de non-implémentation pour cette commande.

```bash
glossia revisit
```

## Paramètres globaux

| Paramètre | Description |
|---|---|
| `--path <PATH>` | Surcharge le répertoire racine du projet |
| `--no-color` | Désactive la sortie colorée |