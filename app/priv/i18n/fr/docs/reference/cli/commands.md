%{
  title: "Commandes",
  summary: "Référence pour toutes les commandes en ligne de commande Glossia et leurs options.",
  category: "référence",
  subcategory: "cli",
  order: 1
}
---

## `glossia init`

Créez un fichier de configuration `L10N.md` de départ dans le dépôt actuel.

```bash
glossia init
```

Échoue si `L10N.md` existe déjà.

## La traduction est côté serveur.

La traduction s'exécute dans le service Glossia hébergé, et non dans l'interface en ligne de commande. Lorsqu'un commit atterrit, Glossia planifie le travail à partir de vos `L10N.md`/, traduit chaque fichier avec le modèle configuré de votre compte, et ouvre une demande de tirage avec les résultats. Vous pouvez surveiller chaque fichier et les tours du modèle en direct sur la page de session de traduction.

Le modèle est choisi par document : un `L10N.md` `model:` désignant l'un des gestionnaires de modèle de votre compte le sélectionne ; sinon, le modèle par défaut de votre compte est utilisé.

L'interface de ligne de commande ne planifie, ne traduit, ne valide, n'inspecte ou ne supprime intentionnellement les traductions générées. Elle ne lit également pas les fichiers de verrouillage de traduction publiés par Glossia.

## `glossia revisit`

Réservé pour un futur passage de révision des langues sources. L'interface de ligne de commande Rust retourne actuellement une erreur non implémentée pour cette commande.

```bash
glossia revisit
```

## Drapeaux globaux

| Drapeau | Description |
|---|---|
| `--path <PATH>` | Définir le répertoire racine du projet |
| `--no-color` | Désactiver la sortie colorée |
