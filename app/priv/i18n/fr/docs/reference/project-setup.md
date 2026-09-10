%{
  title: "Mise en place du projet",
  summary: "États, informations sur l'avancement et résultats de la mise en place du dépôt.",
  category: "Référence",
  order: 2
}
---
La configuration du projet prépare un dépôt connecté pour Glossia. Elle commence après qu'un utilisateur ait sélectionné un dépôt et au moins une langue cible dans le **Nouveau projet** flux.

## Prérequis

- Le compte dispose d'au moins un modèle configuré.
- L'application GitHub de Glossia peut accéder au dépôt sélectionné.
- L'utilisateur peut créer des projets dans le compte.
- Au moins une langue cible est sélectionnée.

## États

| État | Signification | Action disponible |
|---|---|---|
| **En attente** | Le projet a été accepté et est en attente de démarrage. | Suivez la progression ou quittez la page et revenez plus tard. |
| **En cours** | Glossia vérifie et met à jour le référentiel. | Suivez l'activité en direct. |
| **Complété** | La base de localisation a été préparée et publiée pour examen. | Ouvrez, révisez et fusionnez la demande de fusion. |

Les projets sont provisoires tant que la mise en place est **En attente** ou **En cours**. Si l'installation ne peut pas se terminer ou publier un changement utilisable, Glossia nettoie l'environnement d'installation et supprime le projet provisoire. Le dépôt devient ensuite disponible dans le **Nouveau projet** flux afin que l'installation puisse être tentée à nouveau.

## Progression visible

La carte de configuration reste disponible dans le flux de nouveau projet et sur la vue d'ensemble du projet. Elle comprend :

- Un badge d'état et une barre de progression.
- Une brève explication de l'état actuel.
- Activités récentes de préparation de dépôt, inspection, modification de fichier, vérification et finalisation.
- Un message d'erreur clair lorsque la configuration ne peut pas se terminer.

Le progrès est conservé tant que le projet provisoire existe. Un échec terminal supprime le projet et son progrès de configuration visible.

## Résultat complété

Une configuration connectée réussie crée une branche dédiée et une demande de fusion sur la branche par défaut du référentiel. La demande de fusion contient la base de localisation générée, y compris `L10N.md` le contexte et les modifications pratiques minimales nécessaires pour charger du contenu localisé.

La configuration ne publie pas de catalogues cibles ne contenant que des en-têtes. Lorsqu'un framework de localisation exige des catalogues cibles avant la traduction, ces catalogues contiennent les entrées de messages de source extraites avec des valeurs de traduction vides. Lorsque les catalogues cibles ne sont pas encore requis, la configuration les laisse pour la première exécution de traduction.

Glossia ne fusionne pas la demande de fusion. Les mainteneurs du référentiel examinent et fusionnent la demande selon leur processus GitHub habituel.

L'aperçu du projet affiche un avis de configuration tant que cette demande de fusion est ouverte. L'avis est supprimé après que la demande de fusion ait été fusionnée. Si la demande de fusion est fermée sans être fusionnée, l'aperçu explique qu'elle doit être rouverte avant que la configuration ne soit considérée comme terminée.