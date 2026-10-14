%{
  title: "Mise en place du projet",
  summary: "États, informations de progression et résultats de la mise en place du dépôt.",
  category: "référence",
  section: "translation",
  order: 2
}
---

La configuration du projet prépare un dépôt connecté pour Glossia. Après qu'un utilisateur sélectionne un dépôt dans le flux **Nouveau projet**, il choisit l'un des deux modes de configuration.

## Modes de configuration

| Mode | Ce que Glossia fait | Quand le choisir |
|---|---|---|
| **Configuration automatisée** | Inspecte le dépôt et ouvre une pull request avec la configuration générée `L10N.md` pour les langues cibles sélectionnées. | Le dépôt ne possède pas encore de configuration de localisation. |
| **Configuration manuelle** | Il crée le projet immédiatement. Il n'inspecte pas le dépôt, ne lemodifie pas, n'ouvre pas une pull request. | Le dépôt possède déjà un fichier `L10N.md`. Un mainteneur l'écrira. |

Les états, les informations de progression et la pull request décrites ci-dessous ne s'appliquent qu'à la configuration automatisée.

## Configuration manuelle

Un projet configuré manuellement n'a pas d'état de configuration. Il est utilisable dès sa création et n'est jamais supprimé par un échec de configuration.

Glossia lance une exécution de traduction sur la prochaine push vers la branche par défaut du dépôt. L'exécution traduit vers toutes les cibles déclarées dans les fichiers [`L10N.md`](/docs/reference/l10n-md) du dépôt, car aucune langue cible n'est sélectionnée dans le flux **Nouveau projet**.

Jusqu'à la première exécution de traduction, l'aperçu du projet affiche un avis expliquant que Glossia attend une push incluant un fichier `L10N.md`.

## Prérequis

- Le compte dispose d'au moins un modèle configuré.
- L'application GitHub Glossia peut accéder au dépôt sélectionné.
- L'utilisateur peut créer des projets dans le compte.
- Pour la configuration automatisée, au moins une langues cible est sélectionnée.

## États

| État | Signification | Action disponible |
|---|---|---|
| **En attente** | Le projet a été accepté et attend de commencer. | Suivez la progression ou quittez la page et revenez plus tard. |
| **En cours** | Glossia inspecte et met à jour le dépôt. | Suivez l'activité en direct. |
| **Terminé** | L'ensemble de référence de localisation a été préparé et publié pour revue. | Ouvrez, révisez et fusionnez la pull request. |

Les projets sont provisoires tant que la configuration est **En attente** ou **En cours**. Si la configuration ne peut pas être terminée ou publier un changement utilisable, Glossia nettoie l'environnement de configuration et supprime le projet provisoire. Le dépôt devient ensuite disponible dans le flux **Nouveau projet** afin que la configuration puisse être tentée à nouveau.

## Progression visible

La carte de configuration reste disponible dans le flux Nouveau projet et sur l'aperçu du projet. Elle comprend :

- Un badge d'état et une barre de progression.
- Une explication brève de l'état actuel.
- Activités récentes de préparation, d'inspection, de modification de fichier, de vérification et d'achèvement du dépôt.
- Un message d'échec clair lorsque la configuration ne peut pas être terminée.

La progression est stockée tant que le projet provisoire existe. Un échec terminal supprime le projet et sa progression de configuration visible.

## Résultat final

Une configuration connectée réussie crée une branche dédiée et une pull request contre la branche par défaut du dépôt. La pull request contient l'ensemble de référence de localisation généré, incluant le contexte `L10N.md` et les modifications pratiques minimales nécessaires pour charger le contenu localisé.

La configuration ne publie pas de catalogues cibles contenant uniquement les en-têtes. Lorsqu'un framework de localisation requiert les catalogues cibles avant la traduction, les catalogues contiennent les entrées de messages d'origine extraites avec des valeurs de traduction vides. Lorsque les catalogues cibles ne sont pas encore requis, la configuration les laisse pour la première exécution de traduction.

Glossia ne fusionne pas la pull request. Les mainteneurs du dépôt la rév et fusionnent via leur processus GitHub habituel.

L'aperçu du projet affiche un avis de configuration tant que cette pull request est ouverte. L'avis est supprimé après la fusion de la pull request. Si la pull request est fermée sans avoir été fusionnée, l'aperçu explique qu'elle doit être rouvrite avant que la configuration ne soit considérée terminée.
