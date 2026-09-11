%{
  title: "Configuration du projet",
  summary: "États, informations de progression et résultats de la configuration du dépôt.",
  category: "Référence",
  order: 2
}
---
La configuration du projet prépare un dépôt connecté pour Glossia. Elle commence après qu'un utilisateur ait sélectionné un dépôt et au moins une langue cible dans le **Nouveau projet** flux.

## Prérequis

- Le compte dispose d'au moins un modèle configuré.
- L'application GitHub Glossia peut accéder au dépôt sélectionné.
- L'utilisateur peut créer des projets dans le compte.
- Au moins une langue cible a été sélectionnée.

## États

| État | Description | Action disponible |
|---|---|---|
| **En attente** | Le projet a été accepté et attend de commencer. | Suivez les progrès ou quittez la page pour revenir plus tard. |
| **En cours** | Glossia inspecte et met à jour le dépôt. | Suivez l'activité en direct. |
| **Terminé** | La base de localisation a été préparée et publiée pour examen. | Ouvrez, révisez et fusionnez le pull request. |

Les projets sont provisoires pendant que la configuration est **En attente** ou **En cours**. Si la configuration ne peut pas se terminer ou publier un changement utilisable, Glossia nettoie l'environnement de configuration et supprime le projet provisoire. Le dépôt devient ensuite disponible dans le **Nouveau projet** flux afin que la configuration puisse être réessayée.

## Progrès visible

La carte de configuration reste disponible dans le flux de nouveau-projet et dans la vue d'ensemble du projet. Elle comprend :

- Un badge d'état et une barre de progression.
- Une brève explication de l'état actuel.
- Activités récentes de préparation, d'inspection, de modification de fichiers, de vérification et de finalisation du dépôt.
- Un message d'erreur clair en cas d'échec de la configuration.

La progression est stockée tant que le projet provisoire existe. Un échec final élimine à la fois le projet et sa progression de configuration visible.

## Résultat complété.

Une configuration connectée réussie crée une branche dédiée et une demande de fusion sur la branche par défaut du dépôt. La demande de fusion contient la base de localisation générée, y compris `L10N.md` le contexte et les modifications pratiques minimales nécessaires pour charger le contenu localisé.

La configuration ne publie pas les catalogues-cibles à en-têtes uniquement. Lorsqu'un framework de localisation exige des catalogues-cibles avant la traduction, les catalogues contiennent les entrées de messages source extraites avec des valeurs de traduction vides. Lorsque les catalogues-cibles ne sont pas encore requis, la configuration les laisse pour la première exécution de traduction.

Glossia ne fusionne pas la demande de fusion. Les mainteneurs du dépôt la révisent et la fusionnent selon leur processus normal de GitHub.

L'aperçu du projet affiche un avis de configuration tant que cette demande de fusion est ouverte. L'avis est retiré après la fusion de la demande de fusion. Si la demande de fusion est fermée sans avoir été fusionnée, l'aperçu explique qu'elle doit être rouverte avant que la configuration ne soit considérée comme terminée.