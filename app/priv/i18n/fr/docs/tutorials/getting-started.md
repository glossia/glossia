%{
  title: "Démarrage",
  summary: "Connectez un dépôt et préparez son premier paramétrage de localisation.",
  category: "Tutoriels",
  order: 1
}
---
Ce tutoriel connecte un dépôt GitHub à Glossia, choisit ses premières langues cibles et prépare une base de localisation pour que votre équipe puisse la réviser.

## Avant de commencer

Ce dont vous avez besoin :

- Un compte Glossia sur lequel vous pouvez gérer les paramètres et les projets.
- Un dépôt GitHub pour lequel vous pouvez accorder à l'application GitHub de Glossia les permissions de lecture et de mise à jour.
- Une clé de fournisseur pour un supporté [modèle de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configurez un modèle de compte

Ouvrez **Paramètres**, puis **Modèles**, et sélectionnez **Nouveau modèle**.

1. Donnez au modèle un identifiant court, tel que `translation-default`.
2. Ouvrez le sélecteur de modèle et tapez une partie du nom du fournisseur ou du modèle pour filtrer la liste.
3. Sélectionnez le modèle que vous souhaitez que Glossia utilise.
4. Entrez la clé du fournisseur et enregistrez le modèle.

Cet identifiant permet aux dépôts de faire référence à ce modèle de compte sans placer les identifiants du fournisseur dans le contrôle de version. Voir [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) pour plus de détails.

## 2\. Commencez un projet

Revenez à **Projets** et sélectionnez **Nouveau projet**.

Si Glossia demande un accès au dépôt, suivez le lien vers GitHub et accordez l'accès à l'application Glossia GitHub au dépôt. Une fois de retour à Glossia, réouvrez **Nouveau projet** si nécessaire.

## 3\. Choisir un dépôt

Sélectionnez le dépôt que vous souhaitez traduire. Glossia affiche uniquement les dépôts disponibles via l'installation de l'application GitHub du compte actuel.

Passer à l'étape de la langue.

## 4\. Choisir les langues cibles

Sélectionnez une ou plusieurs langues à générer à partir du contenu source du dépôt, puis lancez la configuration.

## 5\. Suivre les étapes de configuration

Gardez la page de configuration ouverte pendant que Glossia prépare le projet. La carte de progression affiche l'état actuel et les activités récentes, y compris la préparation du dépôt, l'inspection des fichiers, les modifications, les contrôles et la fin.

Vous pouvez quitter la page et revenir à l'aperçu du projet sans perdre l'état de configuration. Si la configuration échoue, la même carte explique ce qui nécessite une attention et offre **Réessayer la configuration**.

## 6\. Examiner le résultat

Lorsque la configuration est terminée, ouvrez l'aperçu du projet et examinez la demande de tirage de code créée pour le dépôt. La ligne de base proposée comprend habituellement :

- Une racine `L10N.md` fichier avec langue source, chemins de source et langues cibles.
- Les plus petites modifications d'application ou de contenu nécessaires pour charger les fichiers localisés.
- Toute validation légère qui était déjà disponible dans le référentiel.

Revuez et fusionnez la demande d'extraction via votre flux de travail GitHub habituel. Les exécutions de traduction futures utilisent le fusionné `L10N.md` contexte.

L'aperçu du projet maintient la demande d'extraction de configuration visible tant qu'elle n'est pas fusionnée. Si elle est fermée sans être fusionnée, réouvrez-la depuis le lien dans l'avis de configuration.

## Prochaines étapes

- [Ajouter une nouvelle langue](/docs/how-to/add-a-new-language)
- [Comprendre les états de configuration du projet](/docs/reference/project-setup)
- [Apprendre comment les modèles de compte fonctionnent](/docs/explanation/account-models)