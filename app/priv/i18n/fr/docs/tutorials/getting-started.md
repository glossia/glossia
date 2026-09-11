%{
  title: "Bien démarrer",
  summary: "Connecter un dépôt et préparer sa première configuration de localisation.",
  category: "Tutoriels",
  order: 1
}
---
Ce tutoriel connecte un dépôt GitHub à Glossia, choisit ses premières langues cibles et prépare une base de localisation pour examen par votre équipe.

## Avant de commencer

Vous avez besoin de :

- Un compte Glossia où vous pouvez gérer les paramètres et les projets.
- Un dépôt GitHub que vous pouvez autoriser l'application GitHub de Glossia à lire et à mettre à jour.
- Une clé de fournisseur pour un pris en charge [modèle de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configurer un modèle de compte

Ouvrir **Paramètres**, puis **Modèles**, et sélectionner **Nouveau modèle**.

1. Donnez au modèle un alias court, comme `translation-default`.
2. Ouvrez le sélecteur de modèle et saisissez une partie du nom du fournisseur ou du modèle pour filtrer la liste.
3. Sélectionnez le modèle que vous souhaitez que Glossia utilise.
4. Entrez la clé du fournisseur et enregistrez le modèle.

L'alias permet aux dépôts de se référer à ce modèle de compte sans placer les identifiants du fournisseur dans le contrôle de version. Consultez [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) pour plus de détails.

## 2\. Créer un projet

Retour à **Projets** et sélectionner **Nouveau projet**.

Si Glossia demande un accès au dépôt, suivez le lien vers GitHub et accordez à l'application GitHub de Glossia l'accès au dépôt. Une fois de retour sur Glossia, rouvrez **Nouveau projet** si nécessaire.

## 3\. Choisir un dépôt

Sélectionnez le dépôt que vous souhaitez localiser. Glossia n'affiche que les dépôts disponibles via l'installation de l'application GitHub du compte actuel.

Continuer à l'étape des langues.

## 4\. Choisir les langues cibles

Sélectionnez une ou plusieurs langues à générer à partir du contenu source du dépôt, puis lancez la configuration.

## 5\. Suivre la progression de la configuration

Gardez la page de configuration ouverte pendant que Glossia prépare le projet. La carte de progression affiche l'état actuel et l'activité récente, y compris la préparation du dépôt, l'inspection des fichiers, les modifications, les vérifications et la finalisation.

Vous pouvez quitter la page et revenir à la vue d'ensemble du projet sans perdre l'état de la mise en place. Si la mise en place échoue, la même carte explique ce qui nécessite attention et propose **Réessayer la mise en place**.

## 6\. Consulter le résultat

Une fois la mise en place terminée, ouvrez la vue d'ensemble du projet et examinez la demande de fusion créée pour le dépôt. La base proposée comprend normalement :

- Une racine `L10N.md` fichier avec la langue source, les chemins de source et les langues cibles.
- Les plus petites modifications d'application ou de contenu nécessaires pour charger les fichiers localisés.
- Toute validation légère déjà disponible dans le dépôt.

Revuez et fusionnez la demande d'intégration via votre workflow GitHub normal. Les futures exécutions de traduction utilisent le fusionné `L10N.md` contexte.

La vue d'ensemble du projet maintient la demande d'intégration de configuration visible jusqu'à ce qu'elle soit fusionnée. Si elle est fermée sans être fusionnée, rouvrez-la via le lien dans l'avis de configuration.

## Prochaines étapes

- [Ajouter une nouvelle langue](/docs/how-to/add-a-new-language)
- [Comprendre les états de configuration du projet](/docs/reference/project-setup)
- [Comprendre comment les modèles de compte fonctionnent](/docs/explanation/account-models)