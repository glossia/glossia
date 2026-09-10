%{
  title: "Configuration du projet",
  summary: "États, informations de progression et résultats de la configuration du dépôt.",
  category: "Référence",
  order: 2
}
---
La configuration du projet prépare un dépôt connecté pour Glossia. Elle commence après qu'un utilisateur sélectionne un dépôt et au moins une langue cible dans le **Nouveau projet** flux.

## Prérequis

- Le compte dispose d'au moins un modèle configuré.
- L'application GitHub de Glossia peut accéder au dépôt sélectionné.
- L'utilisateur peut créer des projets dans le compte.
- Au moins une langue cible est sélectionnée.

## États

| État | Signification | Action disponible |
|---|---|---|
| **En attente** | Le projet a été accepté et est en attente de démarrage. | Suivez la progression ou quittez la page pour y revenir plus tard. |
| **En cours** | Glossia inspecte et met à jour le dépôt. | Suivez l'activité en direct. |
| **Terminé** | La base de localisation a été préparée et publiée pour examen. | Ouvrez, révisez et fusionnez la demande de fusion. |

Les projets sont provisoires pendant que la configuration est **En attente** ou **En cours**Si la configuration ne peut pas se terminer ou publier un changement utilisable, Glossia nettoie l'environnement de configuration et supprime le projet provisoire. Le dépôt est ensuite disponible dans le **Nouveau projet** flux afin que la configuration puisse être réessayée.

## Progression visible

La carte de configuration reste disponible dans le flux nouveau-projet et dans l'aperçu du projet. Elle comprend :

- Un insigne d'état et une barre de progression.
- Une brève explication de l'état actuel.
- Activité récente de préparation, d'inspection, de modification de fichier, de vérification et de complétion du dépôt.
- Un message d'échec clair lorsque la configuration ne peut pas aboutir.

La progression est conservée tant que le projet provisoire existe. Un échec terminal efface à la fois le projet et sa progression de configuration visible.

## Résultat complété

Une configuration connectée réussie crée une branche dédiée et une demande de fusion visant la branche par défaut du dépôt. La demande de fusion contient la base de localisation générée, y compris `L10N.md` le contexte et les modifications pratiques minimales nécessaires pour charger le contenu localisé.

La configuration ne publie pas de catalogues cibles à en-tête uniquement. Lorsqu'un framework de localisation nécessite des catalogues cibles avant la traduction, les catalogues contiennent les entrées de messages sources extraites avec des valeurs de traduction vides. Lorsque les catalogues cibles ne sont pas encore requis, la configuration les conserve pour le premier lancement de traduction.

Glossia ne fusionne pas la demande de fusion. Les mainteneurs du dépôt l'examinent et la fusionnent selon leur processus GitHub habituel.

L'aperçu du projet affiche une notice de configuration tant que cette demande de fusion est ouverte. La notice est retirée après la fusion de la demande de fusion. Si la demande de fusion est fermée sans avoir été fusionnée, l'aperçu explique qu'elle doit être rouverte avant que la configuration soit considérée achevée.