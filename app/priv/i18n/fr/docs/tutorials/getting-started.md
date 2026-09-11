%{
  title: "Démarrage",
  summary: "Connecter un dépôt et préparer sa première configuration de localisation.",
  category: "Tutoriels",
  order: 1
}
---
Ce tutoriel connecte un dépôt GitHub à Glossia, choisit ses premières langues cibles et prépare une base de traduction pour que votre équipe puisse l'examiner.

## Avant de commencer

Ce dont vous avez besoin :

- Un compte Glossia où vous pouvez gérer les paramètres et les projets.
- Un dépôt GitHub pour lequel vous pouvez accorder à l'application GitHub de Glossia les permissions de lecture et de mise à jour.
- Une clé de fournisseur pour un compatible [modèle de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configurez un modèle de compte

Ouvrez **Paramètres**, puis **Modèles**, et sélectionnez **Nouveau modèle**.

1. Donnez un court identifiant au modèle, par exemple `translation-default`.
2. Ouvrez le sélecteur de modèles et tapez une partie du nom du fournisseur ou du modèle pour filtrer la liste.
3. Sélectionnez le modèle que vous souhaitez que Glossia utilise.
4. Entrez la clé du fournisseur et enregistrez le modèle.

L'identifiant permet aux dépôts de faire référence à ce modèle de compte sans placer les identifiants du fournisseur dans le contrôle de source. Voir [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) pour plus de détails.

## 2\. Démarrer un projet

Retour à **Projets** et sélectionnez **Nouveau projet**.

Si Glossia vous demande l'accès au dépôt, suivez le lien vers GitHub et autorisez l'accès à l'application GitHub de Glossia au dépôt. Après retour à Glossia, réouvrez **Nouveau projet** Si nécessaire.

## 3\. Choisir un dépôt

Sélectionnez le dépôt que vous souhaitez traduire. Glossia ne liste que les dépôts disponibles via l'installation de l'application GitHub du compte actuel.

Continuer à l'étape des langues.

## 4\. Choisir les langues cibles

Sélectionnez une ou plusieurs langues cibles à partir du contenu source du dépôt, puis lancez la configuration.

## 5\. Suivre la progression de la configuration

Gardez la page de configuration ouverte pendant que Glossia prépare le projet. La carte de progression affiche l'état actuel et les activités récentes, y compris la préparation du dépôt, l'inspection des fichiers, les modifications, les vérifications et la finalisation.

Vous pouvez quitter la page et revenir à la vue d'ensemble du projet sans perdre l'état de configuration. En cas d'échec de la configuration, la même carte explique ce qu'il faut faire et propose **Réessayer la configuration**.

## 6\. Examiner le résultat

Une fois la configuration terminée, ouvrez la vue d'ensemble du projet et examinez le pull request créé pour le dépôt. La base proposée comprend normalement :

- Un fichier racine `L10N.md` contenant le langage d'origine, les chemins source et les langues cibles.
- Les modifications d'application ou de contenu minimales nécessaires pour charger les fichiers localisés.
- Toute validation légère qui était déjà disponible dans le dépôt.

Examinez et fusionnez la demande de pull via votre flux de travail GitHub habituel. Les futures exécutions de traduction utilisent le fusionné `L10N.md` contexte.

La vue d'ensemble du projet maintient la demande de pull de configuration visible jusqu'à ce qu'elle soit fusionnée. Si elle est fermée sans être fusionnée, réouvrez-la depuis le lien dans l'avis de configuration.

## Étapes suivantes

- [Ajouter une nouvelle langue](/docs/how-to/add-a-new-language)
- [Comprendre les états de configuration du projet](/docs/reference/project-setup)
- [Apprendre comment fonctionnent les modèles de compte](/docs/explanation/account-models)