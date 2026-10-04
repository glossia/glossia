%{
  title: "Premiers pas",
  summary: "Connecter un dépôt et préparer sa première configuration de localisation.",
  category: "Tutoriels",
  order: 1
}
---
Ce tutoriel connecte un dépôt GitHub à Glossia, choisit ses premières langues cibles, et prépare une base de localisation pour la revue de votre équipe.

## Avant de commencer

Il vous faut :

- Un compte Glossia où vous pouvez gérer les paramètres et les projets.
- Un dépôt GitHub sur lequel vous pouvez accorder au Glossia GitHub App la permission de lire et de modifier.
- Une clé de fournisseur pour un supporté [modèle de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model).

## 1\. Configurez un modèle de compte

Ouvrir **Paramètres**, puis **Modèles**, et sélectionnez **Nouveau modèle**.

1. Donnez au modèle un identifiant court, tel que `translation-default`.
2. Ouvrez le sélecteur de modèles et tapez une partie du nom d'un fournisseur ou d'un modèle pour filtrer la liste.
3. Sélectionnez le modèle que vous souhaitez que Glossia utilise.
4. Saisissez la clé du fournisseur et enregistrez le modèle.

L'identifiant permet aux dépôts de se référer à ce modèle de compte sans placer les identifiants du fournisseur dans le contrôle de source. Voir [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) pour plus de détails.

## 2\. Commencer un projet

Retournez à **Projets** et sélectionnez **Nouveau projet**.

Si Glossia demande l'accès au dépôt, suivez le lien vers GitHub et accordez à l'application GitHub Glossia l'accès au dépôt. Après votre retour à Glossia, rouvrez **Nouveau projet** si nécessaire.

## 3\. Choisir un dépôt

Sélectionnez le dépôt que vous souhaitez localiser. Glossia n'affiche que les dépôts disponibles via l'installation de l'application GitHub du compte actuel.

## 4\. Choisir comment configurer le projet

Sélectionner **Configuration automatisée** pour laisser Glossia examiner le dépôt et proposer la configuration de localisation dans une demande de fusion. Ce tutoriel suit cette option.

Si le dépôt possède déjà un `L10N.md` fichier, ou si vous préférez le rédiger vous-même, sélectionnez **Configuration manuelle** au lieu de cela. Glossia crée le projet immédiatement et vous pouvez sauter les étapes restantes. Voir [Mise en place du projet](/docs/reference/project-setup) pour ce que fait chaque mode.

## 5\. Choisissez les langues cibles

Sélectionnez une ou plusieurs langues à générer à partir du contenu source du référentiel, puis commencez la mise en place.

## 6\. Suivez l'avancement de la mise en place

Gardez la page de configuration ouverte pendant que Glossia prépare le projet. La carte de progression affiche l'état actuel et l'activité récente, y compris la préparation du dépôt, l'inspection des fichiers, les modifications, les contrôles et la finalisation.

Vous pouvez quitter la page et revenir à la vue d'ensemble du projet sans perdre l'état de configuration. Si la configuration échoue, lisez le message d'échec. Glossia rejette le projet provisoire ; corrigez le prérequis et recommencez via **Nouveau projet**. Voir [Réessayer la configuration du projet](/docs/how-to/retry-project-setup).

## 7\. Examinez le résultat

Lorsque la configuration est terminée, ouvrez la vue d'ensemble du projet et examinez la demande de fusion créée pour le dépôt. La base de référence proposée comprend normalement :

- Une racine `L10N.md` fichier contenant la langue source, les chemins sources et les langues cibles.
- Les modifications d'application ou de contenu minimales nécessaires pour charger les fichiers localisés.
- Toute validation légère déjà disponible dans le référentiel.

Examinez et fusionnez la demande d'intégration via votre flux de travail GitHub habituel. Les exécutions futures de traduction utilisent le fusionné `L10N.md` contexte.

L'aperçu du projet conserve la demande d'intégration de configuration visible jusqu'à ce qu'elle soit fusionnée. Si elle est fermée sans être fusionnée, réouvrez-la depuis le lien dans l'avis de configuration.

## Prochaines étapes

- [Ajouter une nouvelle langue](/docs/how-to/add-a-new-language)
- [Comprendre les états de configuration du projet](/docs/reference/project-setup)
- [Apprendre comment fonctionnent les modèles de compte](/docs/explanation/account-models)