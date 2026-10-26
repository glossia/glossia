%{
  title: "Glossia contre Weblate",
  summary:
    "Choisissez Glossia pour des travaux linguistiques guidés par le modèle, alignés sur la livraison du dépôt et réutilisant votre validation existante.",
  category: "explication",
  markdown_only: true,
  section: "translation",
  order: 23
}
---

**Choisissez Glossia lorsque vous souhaitez que l'automatisation linguistique fonctionne comme le reste de votre livraison de logiciels :** des instructions contrôlées par source, vos propres jetons de modèle, des vérifications natives au dépôt, et des pull requests pour la revue.

[Weblate](https://weblate.org/) est un système de localisation open-source doté d'une interface de traduction web, d'une intégration avec le contrôle de version et d'options d'hébergement autonome. Le code public et l'intégration Git ne sont pas exclusifs à Glossia. La raison de choisir Glossia réside dans sa combinaison de livraison centrée sur le dépôt, de transformations pilotées par le modèle, et d'un contexte linguistique réutilisable pour les humains et les agents.

## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Conserver la revue dans le flux de travail du produit | Reviser la sortie réelle contrôlée par source via les modifications du dépôt et les pull requests. |
| Accompagner un dépôt de source en mouvement rapide | La détection de modifications et la publication en lot soutiennent une boucle de localisation continue sans traduire à nouveau les entrées non modifiées. |
| Apportez vos propres jetons de modèle | Configurez les modèles pris en charge avec des identifiants de fournisseur à portée de compte et sélectionnez-les avec des identifiants détenus par le dépôt. |
| Réutiliser la validation native | Exécutez la commande de validation propre au dépôt sur un candidat à son véritable chemin cible. |
| Réutiliser le contexte au-delà de la traduction | La voix et la terminologie partagées peuvent orienter les nouveaux contenus et les intégrations d'agents grâce aux interfaces MCP et REST. |

## Considérez le dépôt comme la surface de revue

Glossia est conçu pour une équipe qui utilise déjà Git pour décider ce qui est prêt à être livré. La configuration de sa localisation se trouve à côté du contenu, et ses sorties proposées peuvent être révisées selon le même processus que le changement de produit.

Weblate intègre également le contrôle de version. Son interface de traduction basée sur le navigateur pourrait être exactement ce dont une communauté de contributeurs a besoin. L'accent de Glossia est différent : préservez la frontière de la revue du dépôt et apportez l'automatisation linguistique à celle-ci, plutôt que de faire d'une autre interface de modification le centre des travaux de l'équipe.

## Apportez vos propres jetons et devenez explicites dans le choix des modèles

Glossia utilise des modèles pris en charge configurés avec les jetons d'API de votre fournisseur. La configuration du dépôt fait référence à des identifiants de modèle stables ; les secrets restent dans les paramètres du compte. Vous pouvez sélectionner différents modèles configurés par périmètre de contenu ou localisation cible et renouveler les identifiants sans modifier chaque dépôt.

Cela donne à votre équipe un lieu explicite pour choisir les modèles qui créent son contenu. Elle ne promet pas qu'un jeton ou un modèle soit pris en charge, ni que la génération élimine le besoin d'une revue humaine. Consultez [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider).

## Réutilisez les vérifications qui définissent un changement livrable

Les vérifications structurelles intégrées de Glossia ne constituent qu'une partie de la limite de qualité. À travers `L10N.md`, il peut exécuter un script de validation natif du dépôt, un analyseur, un compilateur ou une vérification de documentation sur le candidat à son véritable chemin cible.

Cela est utile lorsque le contenu traduit inclut plus que de simples chaînes : des formats spécifiques à une application, des composants Markdown, des métadonnées structurées, et des contraintes que le projet sait déjà vérifier. La validation et la récupération restent connectées aux vrais fichiers que votre pipeline publiera.

L'environnement d'exécution a toujours besoin des dépendances du validateur, et la validation structurelle n'établit pas l'exactitude linguistique. Consultez [L10N.md](/docs/reference/l10n-md) et [Récupération de la traduction](./translation-recovery).

## Une source publique est une base de référence, pas la comparaison entière

Le cœur de Glossia utilise [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), qui autorise l'utilisation commerciale, la modification, la distribution, l'auto-hébergement et les services hébergés concurrents selon ses conditions. Le code de `ee/` relève d'une [licence Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) distincte et son utilisation en production nécessite un accord commercial écrit. Ce modèle open core diffère des licences basées sur la GPL de Weblate.

Si la licence open-source sans restriction et une interface de traduction web établie sont vos critères principaux, Weblate mérite d'être considéré. Si l'objectif est **votre propre authentification de modèle, les vérifications de dépôt existantes et les travaux linguistiques qui suivent la livraison de logiciels**, Glossia rassemble ces choix dans un système linguistique.

Cette comparaison ne prétend pas que Weblate manque d'automatisation, de fonctionnalités de validation ou d'intégrations de fournisseurs, et ne promet pas de migration automatique ou une parité fonctionnelle. Consultez [la documentation de Weblate](https://docs.weblate.org/) pour les capacités actuelles.
