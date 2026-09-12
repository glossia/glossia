%{
  title: "Configuration du projet",
  summary: "États, informations de progression et résultats de la configuration du dépôt.",
  category: "Référence",
  order: 2
}
---
La configuration du projet prépare un dépôt connecté pour Glossia. Elle commence après que l'utilisateur sélectionne un dépôt et au moins une langue cible dans le **Nouveau projet** flux.

## Prérequis

- Le compte dispose d'au moins un modèle configuré.
- L'application GitHub de Glossia peut accéder au dépôt sélectionné.
- L'utilisateur peut créer des projets dans le compte.
- Au moins une langue cible est sélectionnée.

## États

| État | Description | Action disponible |
|---|---|---|
| **En attente** | Le projet a été accepté et est en attente de démarrage. | Suivez la progression ou quittez la page et revenez plus tard. |
| **En cours** | Glossia est en inspection et met à jour le dépôt. | Suivez l'activité en direct. |
| **Terminé** | La base de référence de localisation a été préparée et publiée pour examen. | Ouvrir, réviser et fusionner la demande de pull. |

Les projets sont provisoires pendant que la configuration est **En attente** ou **En cours**. Si l'initialisation ne peut pas être achevée ou publier un changement utilisable, Glossia nettoie l'environnement d'initialisation et supprime le projet provisoire. Le dépôt devient ensuite disponible dans le **Nouveau projet** flux pour que l'initialisation puisse être tentée à nouveau.

## Progression visible

La carte d'initialisation reste disponible dans le flux de nouveau projet et sur la vue d'aperçu du projet. Elle comprend :

- Un badge d'état et une barre de progression.
- Une brève explication de l'état actuel.
- Une activité récente de préparation, d'inspection, de modification de fichier, de vérification et de finalisation du dépôt.
- Un message d'échec clair lorsque la configuration ne peut pas s'achever.

La progression est stockée tant que le projet provisoire existe. Un échec fatal supprime le projet et sa progression visible de configuration.

## Résultat final.

Une configuration connectée réussie crée une branche dédiée et une demande de fusion vers la branche par défaut du dépôt. La demande de fusion contient la base de localisation générée, incluant `L10N.md` le contexte et les modifications minimales nécessaires pour charger le contenu localisé.

La configuration ne publie pas de catalogues cibles ne contenant que des en-têtes. Lorsqu'un cadre de localisation requiert des catalogues cibles avant la traduction, ces derniers contiennent les entrées de messages source extraites avec des valeurs de traduction vides. Lorsque des catalogues cibles ne sont pas encore requis, la configuration les laisse disponibles pour la première exécution de traduction.

Glossia ne fusionne pas la demande de fusion. Les mainteneurs du dépôt la révisent et la fusionnent selon leur processus normal sur GitHub.

La vue d'ensemble du projet affiche une notification de configuration tant que cette demande de fusion est ouverte. La notification est retirée après la fusion de la demande. Si la demande de fusion est fermée sans être fusionnée, la vue d'ensemble explique qu'elle doit être réouverte avant que la configuration ne soit considérée comme terminée.