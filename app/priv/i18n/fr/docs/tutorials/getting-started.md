%{
  title: "Démarrage",
  summary: "Connectez un dépôt et préparez sa première configuration de localisation.",
  category: "Tutoriels",
  order: 1
}
---

Ce tutoriel connecte un dépôt GitHub à Glossia, sélectionne ses premières langues cibles et prépare une base de traduction pour votre équipe à examiner.

## Avant de commencer

Il vous faut :

- Un compte Glossia où vous pouvez gérer les paramètres et les projets.
- Un dépôt GitHub vers lequel vous pouvez accorder à l'application GitHub de Glossia les permissions de lecture et de mise à jour.
- Une clé de fournisseur pour un [modèle de langage](https://en.wikipedia.org/wiki/Large_language_model) supporté.

## 1. Configurer un modèle de compte

Ouvrez **Paramètres**, puis **Modèles**, et sélectionnez **Nouveau modèle**.

1. Donnez un nom court au modèle, par exemple `translation-default`.
2. Ouvrez le sélecteur de modèle et tapez une partie du nom du fournisseur ou du modèle pour filtrer la liste.
3. Sélectionnez le modèle que vous souhaitez que Glossia utilise.
4. Entrez la clé de fournisseur et enregistrez le modèle.

Ce nom permet aux dépôts de faire référence à ce modèle de compte sans placer les identifiants du fournisseur dans le contrôle de source. Consultez [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) pour plus de détails.

## 2. Démarrer un projet

Retournez à **Projets** et sélectionnez **Nouveau projet**.

Si Glossia demande un accès au dépôt, suivez le lien vers GitHub et accordez à l'application GitHub de Glossia l'accès au dépôt. Après être revenu sur Glossia, rouvrez **Nouveau projet** si nécessaire.

## 3. Choisir un dépôt

Sélectionnez le dépôt que vous souhaitez traduire. Glossia ne liste que les dépôts disponibles via l'installation de l'application GitHub du compte actuel.

## 4. Choisir la méthode de configuration du projet

Sélectionnez **Configuration automatisée** pour laisser Glossia inspecter le dépôt et proposer la configuration de la localisation dans une pull request. Ce tutoriel suit cette voie.

Si le dépôt contient déjà un fichier `L10N.md` ou si vous préférez le rédiger vous-même, sélectionnez **Configuration manuelle** à la place. Glossia crée le projet immédiatement et vous pouvez sauter les étapes restantes. Consultez [Configuration du projet](/docs/reference/project-setup) pour voir ce que fait chaque mode.

## 5. Choisir les langues cibles

Sélectionnez une ou plusieurs langues à produire à partir du contenu source du dépôt, puis lancez la configuration.

## 6. Suivre la progression de la configuration

Gardez la page de configuration ouverte pendant que Glossia prépare le projet. La carte de progression affiche l'état actuel et les activités récentes, y compris la préparation du dépôt, l'inspection de fichiers, les modifications, les vérifications et la finalisation.

Vous pouvez quitter la page et revenir à la vue d'ensemble du projet sans perdre l'état de configuration. Si la configuration échoue, lisez le message d'échec. Glossia annule le projet provisoire ; réparez le prérequis et recommencez via **Nouveau projet**. Veuillez consulter [Retenter la configuration du projet](/docs/how-to/retry-project-setup).

## 7. Examiner le résultat

Lorsque la configuration est terminée, ouvrez la vue d'ensemble du projet et examinez la pull request créée pour le dépôt. La base proposée contient normalement :

- Un fichier `L10N.md` de racine avec le langue source, les chemins source et les langues cibles.
- Les modifications d'application ou de contenu minimales nécessaires pour charger les fichiers localisés.
- Tout vérification légère déjà disponible dans le dépôt.

Examinez et fusionnez cette pull request via votre flux de travail GitHub habituel. Les exécutions futures de traduction utilisent le contexte `L10N.md` fusionné.

La vue d'ensemble du projet garde la pull request de configuration visible tant qu'elle n'est pas fusionnée. Si elle est fermée sans être fusionnée, rouvrez-la depuis le lien dans le notice de configuration.

## Prochaines étapes

- [Ajouter une nouvelle langue](/docs/how-to/add-a-new-language)
- [Comprendre les états de configuration du projet](/docs/reference/project-setup)
- [Apprendre comment les modèles de compte fonctionnent](/docs/explanation/account-models)
