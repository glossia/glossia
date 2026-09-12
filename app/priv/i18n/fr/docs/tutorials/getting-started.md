%{
  title: "Introduction",
  summary: "Connecter un dépôt et préparer sa première configuration de localisation.",
  category: "tutoriels",
  order: 1
}
---
Ce tutoriel connecte un dépôt GitHub à Glossia, choisit ses premières langues cibles et prépare une base de localisation pour votre équipe à valider.

## Avant de commencer

Vous avez besoin de :

- Un compte Glossia où vous pouvez gérer les paramètres et les projets.
- Un dépôt GitHub auquel vous pouvez accorder à l'application GitHub App de Glossia la permission de lire et mettre à jour.
- Une clé de fournisseur pour un supporté [modèle de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configurez un modèle de compte

Ouvrez **Paramètres**, puis **Modèles**, et sélectionnez **Nouveau modèle**.

1. Donnez au modèle un nom court, par exemple `translation-default`.
2. Ouvrez le sélecteur de modèles et tapez une partie du nom d'un fournisseur ou d'un modèle pour filtrer la liste.
3. Sélectionnez le modèle que vous souhaitez que Glossia utilise.
4. Entrez la clé du fournisseur et enregistrez le modèle.

Le nom court permet aux dépôts de se référer à ce modèle de compte sans placer les identifiants du fournisseur dans le contrôle de source. Voir [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) pour plus de détails.

## 2\. Démarrer un projet

Retour à **Projets** et sélectionnez **Nouveau projet**.

Si Glossia demande un accès au dépôt, suivez le lien vers GitHub et accordez l'accès au dépôt à l'application GitHub de Glossia. Après retour à Glossia, rouvrez **Nouveau projet** si nécessaire.

## 3\. Choisir un dépôt

Sélectionnez le dépôt que vous souhaitez localiser. Glossia ne liste que les dépôts disponibles via l'installation de l'application GitHub du compte actuel.

Continuer à l'étape des langues.

## 4\. Choisir les langues cibles

Sélectionnez une ou plusieurs langues à générer à partir du contenu source du dépôt, puis lancez la configuration.

## 5\. Suivre la progression de la configuration

Gardez la page de configuration ouverte tant que Glossia prépare le projet. La carte de progression affiche l'état actuel et les activités récentes, y compris la préparation des dépôts, l'inspection des fichiers, les modifications, les vérifications et l'achèvement.

Vous pouvez quitter la page et revenir à la vue du projet sans perdre l'état de configuration. En cas d'échec de la configuration, la même carte explique ce qui nécessite attention et propose **Réessayer la configuration**.

## 6\. Examiner le résultat

Lorsque la configuration est terminée, ouvrez la vue du projet et examinez la demande de fusion créée pour le dépôt. La base de référence proposée comprend normalement :

- Une racine `L10N.md` un fichier avec langue source, chemins source, et langues cibles.
- Les plus petites modifications d'application ou de contenu nécessaires pour charger les fichiers localisés.
- Toute validation légère déjà disponible dans le dépôt.

Examinez et fusionnez la pull request via votre flux de travail GitHub habituel. Les futures exécutions de traduction utilisent le fusionné `L10N.md` contexte.

L'aperçu du projet conserve la pull request de configuration visible jusqu'à sa fusion. Si elle est fermée sans être fusionnée, rouvrez-la via le lien dans le notice de configuration.

## Prochaines étapes

- [Ajouter une nouvelle langue](/docs/how-to/add-a-new-language)
- [Comprendre les états de configuration du projet](/docs/reference/project-setup)
- [Apprendre comment fonctionnent les modèles de compte](/docs/explanation/account-models)