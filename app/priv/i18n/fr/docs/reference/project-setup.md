%{
  title: "Mise en place du projet",
  summary: "États, informations de progression, et résultats de la mise en place du dépôt.",
  category: "référence",
  order: 2
}
---
La configuration du projet prépare un dépôt connecté pour Glossia. Elle commence après que l'utilisateur sélectionne un dépôt et au moins une langue cible dans le **Nouveau projet** flux.

## Prérequis

- Le compte dispose d'au moins un modèle configuré.
- L'application GitHub Glossia peut accéder au dépôt sélectionné.
- L'utilisateur peut créer des projets sur le compte.
- Au moins une langue cible est sélectionnée.

## États

| État | Description | Action disponible |
|---|---|---|
| **En attente** | Le projet a été accepté et est en attente de démarrage. | Suivez l'avancement ou quittez la page pour revenir plus tard. |
| **En cours** | Glossia examine et met à jour le référentiel. | Suivez l'activité en direct. |
| **Terminé** | La base de localisation a été préparée et publiée pour révision. | Ouvrir, examiner et fusionner la pull request. |

Les projets sont provisoires tandis que la configuration est **En attente** ou **En cours**. Si la configuration ne parvient pas à se terminer ou à publier un changement utilisable, Glossia nettoie l'environnement de configuration et supprime le projet provisoire. Le dépôt est ensuite disponible dans le **Nouveau projet** flux afin que la configuration puisse être réessayée.

## Avancement visible

La carte de configuration reste disponible dans le flux du nouveau projet et dans la vue d'ensemble du projet. Elle comprend:

- Un badge d'état et une barre de progression.
- Une brève explication de l'état actuel.
- Activités récentes de préparation du dépôt, d'inspection, de modification de fichiers, de vérification et de finalisation.
- Un message d'erreur clair lorsque la mise en place ne peut pas se terminer.

L'avancement est stocké tant que le projet provisoire existe. Un échec terminal supprime à la fois le projet et son avancement de mise en place visible.

## Résultat complété

Une mise en place connectée réussie crée une branche dédiée et une demande de fusion sur la branche par défaut du dépôt. La demande de fusion contient la base de localisation générée, y compris `L10N.md` le contexte et les modifications minimales nécessaires pour charger le contenu localisé.

La mise en place ne publie pas les catalogues cibles contenant uniquement des en-têtes. Lorsqu'un framework de localisation nécessite des catalogues cibles avant traduction, les catalogues contiennent les entrées de messages sources extraites avec des valeurs de traduction vides. Lorsque les catalogues cibles ne sont pas requis pour le moment, la mise en place les laisse pour la première exécution de traduction.

Glossia ne fusionne pas la demande de fusion. Les gestionnaires du dépôt la examinent et la fusionnent via leur processus habituel sur GitHub.

La vue d'ensemble du projet affiche une notification de mise en place tant que cette demande de fusion est ouverte. La notification est retirée après que la demande de fusion est fusionnée. Si la demande de fusion est fermée sans être fusionnée, la vue d'ensemble explique qu'elle doit être rouverte avant que la mise en place soit considérée comme terminée.