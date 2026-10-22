%{
  title: "Bien démarrer",
  summary: "Connecter un dépôt et préparer sa première configuration de localisation.",
  category: "tutoriels",
  order: 1
}
---

Ce tutoriel connecte un dépôt GitHub à Glossia, choisit ses premières langues cibles et prépare une base de localisation pour votre équipe à examiner.

## Avant de commencer

Vous devez :

- Un compte Glossia où vous pouvez gérer les paramètres et les projets.
- Un dépôt GitHub auquel vous pouvez accorder les autorisations de lecture et de modification à l'application GitHub de Glossia.
- Une clé de fournisseur pour un [modèle de langage à grande échelle](https://en.wikipedia.org/wiki/Large_language_model) pris en charge.

## 1. Configurer un modèle de compte

Ouvrez **Paramètres**, puis **Modèles**, et sélectionnez **Nouveau modèle**.

1. Donnez au modèle un identifiant court, tel que `translation-default`.
2. Ouvrez le sélecteur de modèle et tapez une partie du nom d'un fournisseur ou d'un modèle pour filtrer la liste.
3. Sélectionnez le modèle que Glossia doit utiliser.
4. Entrez la clé du fournisseur et enregistrez le modèle.

L'identifiant permet aux dépôts de faire référence à ce modèle de compte sans placer les identifiants du fournisseur dans le contrôle de code. Voir [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider) pour plus de détails.

## 2. Lancer un projet

Revenez à **Projets** et sélectionnez **Nouveau projet**.

Si Glossia demande l'accès au dépôt, suivez le lien vers GitHub et accordez à l'application GitHub de Glossia l'accès au dépôt. Une fois de retour chez Glossia, rouvrez **Nouveau projet** si nécessaire.

## 3. Choisir un dépôt

Sélectionnez le dépôt que vous souhaitez localiser. Glossia ne liste uniquement les dépôts disponibles via l'installation de l'application GitHub du compte actuel.

## 4. Choisir comment configurer le projet

Sélectionnez **Configuration automatisée** pour permettre à Glossia d'inspecter le dépôt et de proposer la configuration de localisation via une demande de fusion. Ce tutoriel suit ce chemin.

Si le dépôt possède déjà un fichier `L10N.md` ou vous préférez l'écrire vous-même, sélectionnez **Configuration manuelle** à la place. Glossia crée le projet immédiatement et vous pouvez sauter les étapes restantes. Voir [Mise en place d'un projet](/docs/reference/project-setup) pour ce que fait chaque mode.

## 5. Choisir les langues cibles

Sélectionnez une ou plusieurs langues qui doivent être produites à partir du contenu source du dépôt, puis lancez la configuration.

## 6. Suivre la progression de la configuration

Gardez la page de configuration ouverte pendant que Glossia prépare le projet. La carte de progression affiche l'état actuel et les activités récentes, y compris la préparation du dépôt, l'inspection des fichiers, les modifications, les contrôles et la finalisation.

Vous pouvez quitter la page et revenir à l'aperçu du projet sans perdre l'état de configuration. Si la configuration échoue, lisez le message d'échec. Glossia révoque le projet provisoire ; réparez la condition préalable et recommencez via **Nouveau projet**. Voir [Réessayer la configuration du projet](/docs/how-to/retry-project-setup).

## 7. Examiner le résultat

Lorsque la configuration est terminée, ouvrez l'aperçu du projet et examinez la demande de fusion créée pour le dépôt. La base de référence proposée inclut normalement :

- Un fichier `L10N.md` racine avec la langue source, les chemins source et les langues cibles.
- Les plus petites modifications de l'application ou du contenu nécessaires pour charger les fichiers localisés.
- Toute validation légère déjà disponible dans le dépôt.

Examinez et fusionnez la demande de fusion via votre flux normal GitHub. Les futures exécutions de traduction utilisent le contexte `L10N.md` fusionné.

L'aperçu du projet maintient la demande de fusion de la configuration visible jusqu'à ce qu'elle soit fusionnée. Si elle est fermée sans être fusionnée, rouvrez-la via le lien dans le message de configuration.

## Prochaines étapes

- [Ajouter une nouvelle langue](/docs/how-to/add-a-new-language)
- [Comprendre les états de mise en place du projet](/docs/reference/project-setup)
- [Apprendre comment les modèles de compte fonctionnent](/docs/explanation/account-models)
