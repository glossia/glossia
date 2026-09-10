%{
  title: "Premiers pas",
  summary: "Connectez un dépôt et préparez sa première configuration de localisation.",
  category: "tutoriels",
  order: 1
}
---
Ce tutoriel connecte un dépôt GitHub à Glossia, choisit ses premières langues cibles et prépare une base de localisation pour que votre équipe puisse la réviser.

## Avant de commencer

Vous avez besoin de :

- Un compte Glossia où vous pouvez gérer les paramètres et les projets.
- Un dépôt GitHub où vous pouvez accorder à l'application Glossia GitHub les permissions de lecture et de mise à jour.
- Une clé de fournisseur pour un supporté [modèle de langage](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configurez un modèle de compte

Ouvrir **Paramètres**, puis **Modèles**, et sélectionnez **Nouveau modèle**.

1. Donnez au modèle un identifiant court, tel que `translation-default`.
2. Ouvrez le sélecteur de modèle et tapez une partie du nom du fournisseur ou du modèle pour filtrer la liste.
3. Sélectionnez le modèle que vous souhaitez que Glossia utilise.
4. Saisissez la clé du fournisseur et enregistrez le modèle.

L'identifiant permet aux dépôts de se référer à ce modèle de compte sans placer les identifiants du fournisseur dans le contrôle de source. Voir [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) pour plus de détails.

## 2\. Démarrer un projet

Retourner à **Projets** et sélectionner **Nouveau projet**.

Si Glossia demande un accès au référentiel, suivez le lien vers GitHub et accordez l'accès à l'application Glossia GitHub au référentiel. Après retour à Glossia, rouvrez **Nouveau projet** si nécessaire.

## 3\. Choisissez un dépôt

Sélectionnez le dépôt que vous souhaitez localiser. Glossia n'affiche que les dépôts disponibles via l'installation de l'application GitHub du compte actuel.

Continuez à l'étape de langue.

## 4\. Choisissez des langues cibles

Sélectionnez une ou plusieurs langues qui doivent être produites à partir du contenu source du dépôt, puis lancez la configuration.

## 5\. Suivez la progression de la configuration

Gardez la page de configuration ouverte pendant que Glossia prépare le projet. La carte de progression affiche l'état actuel et les activités récentes, y compris la préparation du dépôt, l'inspection des fichiers, les modifications, les vérifications et la finalisation.

Vous pouvez quitter la page et revenir à la vue d'ensemble du projet sans perdre l'état de configuration. Si la configuration échoue, la même carte explique ce qui nécessite une attention et propose **Réessayer la configuration**.

## 6\. Consulter le résultat

Lorsque la configuration est terminée, ouvrez la vue d'ensemble du projet et examinez le pull request créé pour le dépôt. La base proposée comprend normalement :

- Une racine `L10N.md` fichier avec langage source, chemins source et langages cibles.
- Les modifications les plus petites d'application ou de contenu nécessaires pour charger les fichiers localisés.
- Toute validation légère déjà disponible dans le dépôt.

Examinez et fusionnez la demande d'intégration via votre flux de travail GitHub habituel. Les exécutions futures de traduction utilisent la fusion `L10N.md` contexte.

L'aperçu du projet conserve la demande d'intégration de configuration visible jusqu'à sa fusion. Si elle est fermée sans être fusionnée, réouvrez-la à partir du lien dans l'avis de configuration.

## Prochaines étapes

- [Ajouter une nouvelle langue](/docs/how-to/add-a-new-language)
- [Comprendre les états de configuration du projet](/docs/reference/project-setup)
- [Découvrez comment fonctionnent les modèles de compte.](/docs/explanation/account-models)