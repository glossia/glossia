%{
  title: "Configuration du projet",
  summary: "États, informations de progression et résultats de la configuration du dépôt.",
  category: "référence",
  order: 2
}
---
La configuration du projet prépare un dépôt connecté pour Glossia. Elle commence après qu'un utilisateur sélectionne un dépôt et au moins une langue cible dans le flux **Nouveau projet**.

## Prérequis

- Le compte possède au moins un modèle configuré.
- L'Application GitHub Glossia peut accéder au dépôt sélectionné.
- L'utilisateur peut créer des projets dans le compte.
- Au moins une langue cible est sélectionnée.

## États

| État | Signification | Action disponible |
|---|---|---|
| **En attente** | Le projet a été validé et est en attente de démarrage. | Suivre la progression ou quitter la page pour revenir plus tard. |
| **En cours** | Glossia examine et met à jour le dépôt. | Suivre l'activité en direct. |
| **Terminée** | La base de référence de localisation a été préparée et publiée pour révision. | Ouvrir, examiner et fusionner la demande de fusion. |

Les projets sont provisoires tant que la configuration est **En attente** ou **En cours**. Si la configuration ne peut pas se terminer ou publier une modification utilisable, Glossia nettoie l'environnement de configuration et supprime le projet provisoire. Le dépôt devient alors disponible dans le flux **Nouveau projet** afin d'essayer à nouveau la configuration.

## Progression visible

La carte de configuration reste disponible dans le flux Nouveau projet et dans l'aperçu du projet. Elle inclut :

- Une mention d'état et une barre de progression.
- Une brève explication de l'état actuel.
- Des activités récentes de préparation du dépôt, d'inspection, de modifications de fichiers, de vérification et de finalisation.
- Un message d'échec clair lorsque la configuration ne peut pas se terminer.

La progression est conservée tant que le projet provisoire existe. Un échec fatal met fin à la fois au projet et à sa progression visible de configuration.

## Résultat final

Une configuration connectée réussie crée une branche dédiée et une demande de fusion contre la branche par défaut du dépôt. La demande de fusion contient la base de référence de localisation générée, y compris le contexte `L10N.md` et les changements pratiques minimaux nécessaires pour charger le contenu localisé.

La configuration ne publie pas de catalogues cibles à en-têtes uniquement. Lorsqu'un cadre de localisation exige des catalogues cibles avant la traduction, ceux-ci contiennent les entrées de messages source extraits avec des valeurs de traduction vides. Lorsque les catalogues cibles ne sont pas requis encore, la configuration les laisse pour la première exécution de traduction.

Glossia ne fusionne pas la demande de fusion. Les mainteneurs du dépôt révisent et fusionnent celle-ci via leur processus GitHub normal.

L'aperçu du projet affiche un avis de configuration tant que cette demande de fusion est ouverte. L'avis est retiré après la fusion de la demande de fusion. Si la demande de fusion est fermée sans avoir été fusionnée, l'aperçu explique qu'elle doit être rouvrite avant que la configuration ne soit considérée comme terminée.