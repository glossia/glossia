%{
  title: "Glossia contre Weblate",
  summary:
    "Choisissez Glossia pour des travaux linguistiques pilotés par modèle qui suivent le flux de livraison du dépôt et réutilisent votre validation existante.",
  category: "explication",
  markdown_only: true,
  section: "translation",
  order: 23
}
---

**Choisissez Glossia lorsque vous souhaitez que l'automatisation linguistique fonctionne comme le reste de votre chaîne de livraison logicielle :** directives sous contrôle source, vos propres jetons de modèle, vérifications natives du dépôt et des pull requests pour revue.

[Weblate](https://weblate.org/) est un système de localisation open source avec une interface web de traduction, une intégration au contrôle de version et des options d'auto-hébergement. Le code public et l'intégration Git ne sont pas exclusifs à Glossia. Le motif pour choisir Glossia réside dans sa combinaison de livraison centrée sur le dépôt, de transformations pilotées par le modèle et de contexte linguistique réutilisable tant pour les humains que pour les agents.

## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Maintenir la révision dans le flux de travail du produit | Examiner la sortie réelle sous contrôle source à travers les modifications du dépôt et les pull requests. |
| Correspondre à un dépôt source en évolution rapide | La détection de changements et la publication par lots soutiennent un cycle de localisation continu sans traduire à nouveau les entrées inchangées. |
| Apportez vos propres jetons de modèle | Configurez les modèles pris en charge avec des identifiants de fournisseur à portée du compte et sélectionnez-les avec des gestionnaires appartenant au dépôt. |
| Réutiliser la validation native | Exécutez la commande de validation native du dépôt sur un candidat à sa véritable destination. |
| Réutiliser le contexte au-delà de la traduction | La voix partagée et la terminologie peuvent orienter le nouveau contenu et les intégrations d'agents via les interfaces MCP et REST. |

## Maintenir le dépôt comme surface de révision

Glossia est conçu pour une équipe qui utilise déjà Git pour décider ce qui est prêt à être déployé. La configuration de localisation réside à côté du contenu, et ses sorties proposées peuvent être révisées via le même processus que le changement de produit.

Weblate s'intègre également au contrôle de version. Son interface de traduction basée sur le navigateur peut être exactement ce dont une communauté de contributeurs a besoin. L'accent de Glossia est différent : préserver la frontière de révision du dépôt et apporter l'automatisation linguistique, plutôt que de faire d'une autre interface d'édition le centre des travaux de l'équipe.

## Apportez vos propres jetons et clarifiez les choix de modèle

Glossia utilise des modèles pris en charge configurés avec vos jetons API de fournisseur. La configuration du dépôt fait référence à des gestionnaires de modèle stables ; les secrets restent dans les paramètres du compte. Vous pouvez sélectionner différents modèles configurés par portée de contenu ou locale cible et renouveler les identifiants sans modifier chaque dépôt.

Cela donne à votre équipe un lieu explicite pour choisir les modèles qui produisent son contenu. Elle ne garantit pas qu'un jeton ou un modèle est pris en charge, ni que la génération élimine le besoin de contrôle humain. Consultez [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider).

## Réutiliser les contrôles qui définissent un changement de livraison

Les vérifications structurelles intégrées à Glossia ne constituent qu'une partie de la frontière de qualité. À travers `L10N.md`,

Utile lorsque le contenu traduit inclut plus que des chaînes simples : formats spécifiques à l'application, composants Markdown, métadonnées structurées et contraintes que le projet sait déjà vérifier. Validation et récupération restent connectées aux fichiers que votre pipeline publiera.

L'environnement d'exécution nécessite toujours les dépendances du validateur et la validation structurelle n'établit pas l'exactitude linguistique. Consultez [L10N.md](/docs/reference/l10n-md) et [Récupération des traductions](./translation-recovery).

## Une source publique est une base, pas une comparaison totale

Le cœur de Glossia utilise [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), qui autorise l'utilisation commerciale, la modification, la distribution, l'auto-hébergement et les services hébergés concurrents selon ses conditions. Le code de `ee/` relève d'une [licence Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) distincte et son utilisation en production nécessite un accord commercial écrit. Ce modèle open core diffère des licences basées sur la GPL de Weblate.

Si la licence open-source non restrictive et une interface web de traduction établies sont vos principaux critères, Weblate mérite d'être considéré. Si l'objectif est **vos propres identifiants de modèle, les vérifications existantes du dépôt et les travaux linguistiques qui suivent la livraison de logiciels**, Glossia rassemble ces choix dans un système d'exploitation linguistique.

Cette comparaison ne prétend pas que Weblate manque d'automatisation, de fonctionnalités de validation ou d'intégrations de fournisseur, et ne promet pas de migration automatique ou de parité fonctionnelle. Consultez [la documentation de Weblate](https://docs.weblate.org/) pour les capacités actuelles.
