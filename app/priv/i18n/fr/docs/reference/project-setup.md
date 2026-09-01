%{
  title: "Configuration du projet",
  summary: "États, informations de progression et résultats de la configuration du dépôt.",
  category: "référence",
  order: 2
}
---
La configuration de projet prépare un dépôt connecté pour Glossia. Elle commence après qu'un utilisateur sélectionne un dépôt et au moins une langue cible dans le**Nouveau projet** flux.

## Prérequis

- Le compte dispose d'au moins un modèle configuré.
- L'application GitHub Glossia peut accéder au dépôt sélectionné.
- L'utilisateur peut créer des projets dans le compte.
- Au moins une langue cible est sélectionnée.

## États

| État | Signification | Action disponible |
|---|---|---|
| **En attente** | Le projet a été accepté et en attente de démarrage. | Suivez les progrès ou quittez la page pour y revenir plus tard. |
| **En cours** | Glossia examine et met à jour le dépôt. | Suivez l'activité en direct. |
| **Terminé** | La base de localisation a été préparée et publiée pour examens. | Ouvrez, examinez et fusionnez la demande d'intégration. |

Les projets sont provisoires pendant la configuration **En attente** ou **En cours**. Si la configuration ne peut pas se terminer ou publier un changement utilisable, Glossia nettoie l'environnement de configuration et supprime le projet provisoire. Le dépôt est ensuite disponible dans le **Nouveau projet** flux pour permettre de recommencer la configuration.

## Progrès visible

La carte de configuration reste disponible dans le flux Nouveau projet et sur l'aperçu du projet. Elle comprend:

- Un badge d'état et une barre d'avancement.
- Une courte explication de l'état actuel.
- Activités récentes de préparation, d'inspection, de modification de fichiers, de contrôle et d'achèvement du dépôt.
- Un message d'échec clair lorsque la configuration ne peut pas se terminer.

Le progrès est stocké aussi longtemps que le projet provisoire existe. Un échec terminal rejette à la fois le projet et son progrès de configuration visible.

## Résultat terminé

Une configuration connectée réussie crée une branche dédiée et une demande d'intégration contre la branche par défaut du dépôt. La demande d'intégration contient la base de localisation générée, incluant`GLOSSIA.md` contexte et les modifications les plus pratiques nécessaires pour charger le contenu localisé.

La configuration ne publie pas de catalogues cibles en-tête seulement. Lorsqu'un framework de localisation exige des catalogues cibles avant la traduction, les catalogues contiennent les entrées extraites de l'avec des valeurs de traduction vides. Si les catalogues cibles ne sont pas requis, la configuration les laisse pour la première exécution de la traduction.

Glossia ne fusionne pas la demande d'intégration. Les contributeurs du dépôt examinent et fusionnent la demande selon leur processus normal GitHub.

L'aperçu du projet affiche un avis de configuration pendant que cette demande d'intégration est ouverte. L'avis est supprimé après la fusion de la demande d'intégration. Si la demande d'intégration est fermée sans fusion, l'aperçu explique qu'elle doit être rouverte avant que la configuration ne soit considérée terminée.