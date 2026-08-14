%{
  title: "Configuration du projet",
  summary: "États, informations de progression et résultats de la configuration du dépôt.",
  category: "reference",
  order: 2
}
---
La configuration du projet prépare un dépôt connecté pour Glossia. Elle commence lorsqu’un utilisateur sélectionne un dépôt et au moins une langue cible dans le parcours **Nouveau projet**.

## Prérequis

- Le compte dispose d’au moins un modèle configuré.
- L’application GitHub Glossia peut accéder au dépôt sélectionné.
- L’utilisateur peut créer des projets dans le compte.
- Au moins une langue cible est sélectionnée.

## États

| État | Signification | Action disponible |
|---|---|---|
| **En attente** | Le projet a été accepté et attend de démarrer. | Suivre la progression ou quitter la page et y revenir ultérieurement. |
| **En cours** | Glossia inspecte et met à jour le dépôt. | Suivre l’activité en direct. |
| **Terminée** | La base de localisation a été préparée et publiée pour révision. | Ouvrir, réviser et fusionner la pull request. |

Les projets sont provisoires tant que la configuration est **En attente** ou **En cours**. Si la configuration ne peut pas aboutir ou publier une modification exploitable, Glossia nettoie l’environnement de configuration et supprime le projet provisoire. Le dépôt redevient alors disponible dans le parcours **Nouveau projet** afin de permettre une nouvelle tentative de configuration.

## Progression visible

La carte de configuration reste disponible dans le parcours de création d’un projet et dans la vue d’ensemble du projet. Elle comprend :

- Un badge d’état et une barre de progression.
- Une brève explication de l’état actuel.
- Les activités récentes de préparation et d’inspection du dépôt, de modification des fichiers, de vérification et d’achèvement.
- Un message d’échec clair lorsque la configuration ne peut pas aboutir.

La progression est conservée tant que le projet provisoire existe. Un échec définitif supprime à la fois le projet et la progression visible de sa configuration.

## Résultat obtenu

La réussite de la configuration d’un dépôt connecté crée une branche dédiée et une pull request vers la branche par défaut du dépôt. La pull request contient la base de localisation générée, notamment le contexte `GLOSSIA.md`, ainsi que les modifications minimales nécessaires au chargement du contenu localisé.

La configuration ne publie pas de catalogues cibles contenant uniquement un en-tête. Lorsqu’un cadre logiciel de localisation exige des catalogues cibles avant la traduction, ceux-ci contiennent les entrées de messages extraites de la source avec des valeurs de traduction vides. Lorsque les catalogues cibles ne sont pas encore nécessaires, la configuration reporte leur création à la première exécution de traduction.

Glossia ne fusionne pas la pull request. Les responsables du dépôt la révisent et la fusionnent selon leur processus GitHub habituel.

La vue d’ensemble du projet affiche une notification de configuration tant que cette pull request est ouverte. La notification disparaît après la fusion de la pull request. Si la pull request est fermée sans être fusionnée, la vue d’ensemble indique qu’elle doit être rouverte avant que la configuration puisse être considérée comme terminée.