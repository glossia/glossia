%{
  title: "Bien démarrer",
  summary: "Connectez un dépôt et préparez sa première configuration de localisation.",
  category: "tutorials",
  order: 1
}
---
Ce tutoriel connecte un dépôt GitHub à Glossia, sélectionne ses premières langues cibles et prépare une base de localisation que votre équipe pourra examiner.

## Avant de commencer

Vous avez besoin des éléments suivants :

- Un compte Glossia sur lequel vous pouvez gérer les paramètres et les projets.
- Un dépôt GitHub pour lequel vous pouvez autoriser l’application GitHub de Glossia à lire et à effectuer des mises à jour.
- Une clé de fournisseur pour un [grand modèle de langage](https://en.wikipedia.org/wiki/Large_language_model) pris en charge.

## 1. Configurer un modèle de compte

Ouvrez **Paramètres**, puis **Modèles**, et sélectionnez **Nouveau modèle**.

1. Attribuez au modèle un identifiant court, tel que `translation-default`.
2. Ouvrez le sélecteur de modèle et saisissez une partie du nom d’un fournisseur ou d’un modèle pour filtrer la liste.
3. Sélectionnez le modèle que Glossia doit utiliser.
4. Saisissez la clé du fournisseur et enregistrez le modèle.

L’identifiant permet aux dépôts de faire référence à ce modèle de compte sans placer les identifiants d’accès du fournisseur dans le contrôle de version. Consultez [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) pour plus de détails.

## 2. Créer un projet

Revenez à **Projets** et sélectionnez **Nouveau projet**.

Si Glossia demande l’accès au dépôt, suivez le lien vers GitHub et accordez à l’application GitHub de Glossia l’accès au dépôt. Après votre retour dans Glossia, rouvrez **Nouveau projet** si nécessaire.

## 3. Choisir un dépôt

Sélectionnez le dépôt que vous souhaitez localiser. Glossia répertorie uniquement les dépôts accessibles par l’intermédiaire de l’installation actuelle de l’application GitHub du compte.

Passez à l’étape de sélection des langues.

## 4. Choisir les langues cibles

Sélectionnez une ou plusieurs langues à produire à partir du contenu source du dépôt, puis lancez la configuration.

## 5. Suivre la progression de la configuration

Gardez la page de configuration ouverte pendant que Glossia prépare le projet. La carte de progression affiche l’état actuel et l’activité récente, notamment la préparation du dépôt, l’inspection des fichiers, les modifications, les vérifications et l’achèvement.

Vous pouvez quitter la page et revenir à la vue d’ensemble du projet sans perdre l’état de la configuration. Si la configuration échoue, la même carte indique les éléments qui nécessitent votre attention et propose l’action **Réessayer la configuration**.

## 6. Examiner le résultat

Une fois la configuration terminée, ouvrez la vue d’ensemble du projet et examinez la demande de fusion créée pour le dépôt. La base proposée comprend généralement :

- Un fichier `GLOSSIA.md` à la racine, contenant la langue source, les chemins sources et les langues cibles.
- Les modifications minimales de l’application ou du contenu nécessaires au chargement des fichiers localisés.
- Toute validation légère déjà disponible dans le dépôt.

Examinez et fusionnez la demande de fusion selon votre processus GitHub habituel. Les prochaines exécutions de traduction utiliseront le contexte `GLOSSIA.md` fusionné.

La vue d’ensemble du projet conserve la demande de fusion de configuration visible jusqu’à sa fusion. Si elle est fermée sans être fusionnée, rouvrez-la à l’aide du lien figurant dans l’avis de configuration.

## Étapes suivantes

- [Ajouter une nouvelle langue](/docs/how-to/add-a-new-language)
- [Comprendre les états de configuration d’un projet](/docs/reference/project-setup)
- [Comprendre le fonctionnement des modèles de compte](/docs/explanation/account-models)