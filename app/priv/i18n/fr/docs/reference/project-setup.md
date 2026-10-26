%{
  title: "Configuration du projet",
  summary: "États, informations de progression et résultats de la configuration du référentiel.",
  category: "Référence",
  section: "translation",
  order: 2
}
---

La configuration du projet prépare un dépôt connecté pour Glossia. Après avoir sélectionné un dépôt dans le flux **Nouveau projet**, l'utilisateur choisit l'un des deux modes de configuration.

## Modes de configuration

| Mode | Ce que fait Glossia | Quand le choisir |
|---|---|---|
| **Configuration automatisée** | Inspecte le dépôt et ouvre une pull request avec la configuration `L10N.md` générée pour les langues cibles sélectionnées. | Le dépôt n'a aucune configuration de localisation. |
| **Configuration manuelle** | Crée le projet immédiatement. Il n'inspecte pas le dépôt, ne le modifie pas et n'ouvre pas de pull request. | Le dépôt contient déjà un fichier `L10N.md` |

Les états, les informations de progression et la pull request décrites ci-dessous s'appliquent uniquement à la configuration automatisée.

## Configuration manuelle

Un projet configuré manuellement n'a pas d'état de configuration. Il est utilisable dès sa création et n'est jamais supprimé en cas d'échec de configuration.

Glossia lance une exécution de traduction à la prochaine poussée vers la branche par défaut du dépôt. L'exécution traduit dans chaque cible déclarée dans les fichiers [`L10N.md`](/docs/reference/l10n-md) du dépôt, car aucune langue cible n'est sélectionnée dans le flux **Nouveau projet**.

Jusqu'à la première exécution de traduction, la vue d'ensemble du projet affiche un message expliquant que Glossia attend une poussée incluant un fichier `L10N.md`.

## Prérequis

- Le compte dispose d'au moins un modèle configuré.
- L'application GitHub Glossia peut accéder au dépôt sélectionné.
- L'utilisateur peut créer des projets dans le compte.
- Pour la configuration automatisée, au moins une langue cible est sélectionnée.

## États

| État | Signification | Action disponible |
|---|---|---|
| **En attente** | Le projet a été accepté et attend de commencer. | Suivre la progression ou quitter la page pour revenir plus tard. |
| **En cours** | Glossia inspecte et met à jour le dépôt. | Suivre l'activité en direct. |
| **Terminée** | La base de localisation a été préparée et publiée pour examen. | Ouvrir, consulter et fusionner la demand de fusion. |

Les projets sont provisoires tant que la configuration est **En attente** ou **En cours**. Si la configuration ne peut pas se terminer ou publier un changement fonctionnel, Glossia nettoie l'environnement de configuration et supprime le projet provisoire. Le dépôt devient alors disponible dans le flux **Nouveau projet** afin que la configuration puisse être réessayée.

## Progression visible

La carte de configuration reste disponible dans le flux de nouveau projet et sur la vue d'ensemble du projet. Elle comprend :

- Un badge d'état et une barre de progression.
- Une brève explication de l'état actuel.
- Activité récente de préparation du dépôt, d'inspection, de modification du fichier, de vérification et d'achèvement.
- Un message d'échec clair lorsque la configuration ne peut pas se terminer.

La progression est conservée pendant que le projet provisoire existe. Un échec terminal élimine à la fois le projet et sa progression de configuration visible.

## Résultat à l'achèvement

Une configuration connectée réussie crée une branche dédiée et une demande de fusion sur la branche par défaut du dépôt. La demande de fusion contient la base de localisation générée, incluant le contexte `L10N.md` et les modifications les plus minimes nécessaires pour charger le contenu localisé.

La configuration ne publie pas de catalogues cibles à en-tête uniquement. Lorsqu'un framework de localisation exige des catalogues cibles avant la traduction, ceux-ci contiennent les entrées de messages sources extraites avec des valeurs de traduction vides. Lorsqu'ils ne sont pas encore requis, la configuration les laisse pour la première exécution de traduction.

Glossia ne fusionne pas la demande de fusion. Les mainteneurs du dépôt la consultent et la fusionnent selon leur processus normal GitHub.

La vue d'ensemble du projet affiche un message de configuration tant que cette demande de fusion est ouverte. Le message est supprimé après la fusion de la demande de fusion. Si la demande de fusion est fermée sans être fusionnée, la vue d'ensemble explique qu'elle doit être réouverte avant que la configuration ne soit considérée terminée.
