%{
  title: "Configuration du projet",
  summary: "États, informations de progression et résultats de la configuration du dépôt.",
  category: "Référence",
  section: "translation",
  order: 2
}
---
La configuration du projet prépare un dépôt connecté pour Glossia. Après qu'un utilisateur sélectionne un dépôt dans le **Nouveau projet** flux, ils choisissent l'un des deux modes de configuration.

## Modes de configuration

| Mode | Ce que Glossia fait | Quand le choisir |
|---|---|---|
| **Configuration automatisée** | Inspecte le dépôt et ouvre une Pull Request avec la `L10N.md` configuration générée pour les langues cibles sélectionnées. | Le dépôt n'a pas encore de configuration de localisation. |
| **Configuration manuelle** | Crée le projet immédiatement. Il ne l'inspecte pas, ne le modifie pas, ni n'ouvre de Pull Request. | Le dépôt possède déjà un `L10N.md` fichier, ou un mainteneur l'écrira. |

Les états, les informations de progression et la Pull Request décrites ci-dessous s'appliquent uniquement à la configuration automatique.

## Configuration manuelle

Un projet configuré manuellement n'a pas d'état de configuration. Il est utilisable dès sa création et n'est jamais supprimé suite à un échec de configuration.

Glossia lance une exécution de traduction au prochain push vers la branche par défaut du dépôt. L'exécution traduit vers chaque cible déclarée dans le dépôt [`L10N.md`](/docs/reference/l10n-md) fichiers, car aucune langue cible n'est sélectionnée dans le **Nouveau projet** flux.

Jusqu'à la première exécution de traduction, l'aperçu du projet affiche un avis expliquant que Glossia est en attente d'un push incluant un `L10N.md` fichier.

## Prérequis

- Le compte dispose au moins d'un modèle configuré.
- L'application GitHub de Glossia peut accéder au dépôt sélectionné.
- L'utilisateur peut créer des projets dans le compte.
- Pour la configuration automatisée, au moins une langue cible est sélectionnée.

## États

| État | Signification | Action disponible |
|---|---|---|
| **En attente** | Le projet a été accepté et est en attente de démarrage. | Suivez les progrès ou quittez la page pour revenir plus tard.
| **En cours** | Glossia examine et met à jour le dépôt. | Suivez l'activité en direct.
| **Complété** | La référence de localisation a été préparée et publiée pour révision. | Ouvrez, révisez et fusionnez la demande d'intégration.

Les projets sont provisoires tant que la mise en place est **en attente** ou **en cours**. Si la mise en place ne peut pas se terminer ou publier un changement utilisable, Glossia nettoie l'environnement de mise en place et supprime le projet provisoire. Le dépôt devient alors disponible dans le **Nouveau projet** flux pour pouvoir réessayer la mise en place.

## Progression visible

La carte de mise en place reste disponible dans le flux de nouveau projet et sur la vue d'ensemble du projet. Elle comprend :

- Un badge d'état et une barre de progression.
- Une courte explication de l'état actuel.
- Activité récente de préparation du dépôt, d'inspection, de modification de fichiers, de vérification et de complétion.
- Un message d'échec clair lorsque la mise en place ne peut pas se terminer.

La progression est stockée tant que le projet provisoire existe. Un échec terminal supprime à la fois le projet et sa progression de mise en place visible.

## Résultat complété

Une mise en place connectée réussie crée une branche dédiée et une pull request sur la branche par défaut du dépôt. La pull request contient la base de localisation générée, incluant `L10N.md` contexte et les plus petits changements pratiques nécessaires pour charger du contenu localisé.

La configuration ne publie pas de catalogues cibles à en-têtes uniquement. Lorsqu'un framework de localisation nécessite des catalogues cibles avant la traduction, les catalogues contiennent les entrées de messages source extraites avec des valeurs de traduction vides. Lorsque les catalogues cibles ne sont pas encore requis, la configuration les conserve pour la première exécution de traduction.

Glossia ne fusionne pas la demande de fusion. Les mainteneurs du dépôt la révisent et la fusionnent via leur processus normal GitHub.

L'aperçu du projet affiche un avis de configuration pendant que cette demande de fusion est ouverte. L'avis est supprimé après la fusion de la demande. Si la demande de fusion est fermée sans être fusionnée, l'aperçu indique qu'elle doit être reouverte avant que la configuration ne soit considérée achevée.