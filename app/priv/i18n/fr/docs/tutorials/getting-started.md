%{
  title: "Prise en main",
  summary: "Connecter un dépôt et préparer sa première configuration de localisation.",
  category: "Tutoriels",
  order: 1
}
---
Ce tutoriel connecte un dépôt GitHub à Glossia, choisit ses premières langues cibles et prépare une base de localisation pour que votre équipe puisse l'examiner.

## AVANT DE COMMENCER

Vous avez besoin de :

- Un compte Glossia où vous pouvez gérer les paramètres et les projets.
- Un dépôt GitHub auquel vous attribuez à l'application GitHub de Glossia la permission de lecture et de mise à jour.
- Une clé de fournisseur pour un [modèle de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model) pris en charge.

## 1\. Configurer un modèle de compte

Ouvrez **Paramètres**, puis **Modèles**, et sélectionnez **Nouveau modèle**.

1. Donnez au modèle un identifiant court, tel que `translation-default`.
2. Ouvrez le sélecteur de modèle et tapez une partie du nom du fournisseur ou du modèle pour filtrer la liste.
3. Sélectionnez le modèle que vous souhaitez que Glossia utilise.
4. Saisissez la clé de fournisseur et enregistrez le modèle.

L'identifiant permet aux dépôts de référence ce modèle de compte sans placer les identifiants de fournisseur dans le contrôle de version. Consultez [Configurer un modèle de fournisseur](/docs/how-to/configure-a-model-provider) pour plus de détails.

## 2\. Démarrer un projet

Retournez à **Projets** et sélectionnez **Nouveau projet**.

Si Glossia demande l'accès au dépôt, suivez le lien vers GitHub et accordez à l'application GitHub de Glossia l'accès au dépôt. Après retour à Glossia, rouvrez **Nouveau projet** si nécessaire.

## 3\. Choisir un dépôt

Sélectionnez le dépôt que vous souhaitez localiser. Glossia ne liste que les dépôts disponibles via l'installation de l'application GitHub du compte actuel.

Continuez à l'étape des langues.

## 4\. Choisir les langues cibles

Sélectionnez une ou plusieurs langues qui doivent être produites à partir du contenu source du dépôt, puis lancez la configuration.

## 5\. Suivre la progression de la configuration

Gardez la page de configuration ouverte pendant que Glossia prépare le projet. La carte de progression affiche l'état actuel et les activités récentes, y compris la préparation du dépôt, l'examen des fichiers, les modifications, les vérifications et la terminaison.

Vous pouvez quitter la page et retourner à la vue d'ensemble du projet sans perdre l'état de configuration. Si la configuration échoue, la même carte explique ce qui demande de l'attention et propose **Retenter la configuration**.

## 6\. Examiner le résultat

Lorsque la configuration est terminée, ouvrez la vue d'ensemble du projet et examinez la pull request créée pour le dépôt. La base proposée comprend normalement :

- Un fichier racine `GLOSSIA.md` avec la langue source, les chemins source et les langues cibles.
- Les modifications d'application ou de contenu minimales nécessaires pour charger les fichiers localisés.
- Toute validation légère déjà disponible dans le dépôt.

Examinez et fusionnez la pull request via votre flux de travail GitHub normal. Les futures exécutions de traduction utilisent le contexte `GLOSSIA.md` fusionné.

La vue d'ensemble du projet conserve la pull request de configuration visible jusqu'à ce qu'elle soit fusionnée. Si elle est fermée sans être fusionnée, rouvrez-la depuis le lien dans le message de configuration.

## Prochaines étapes

- [Ajouter une nouvelle langue](/docs/how-to/add-a-new-language)
- [Comprendre les états de configuration du projet](/docs/reference/project-setup)
- [Apprendre le fonctionnement des modèles de compte](/docs/explanation/account-models)