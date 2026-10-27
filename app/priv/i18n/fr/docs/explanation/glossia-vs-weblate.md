%{
  title: "Glossia contre Weblate",
  summary:
    "Choisissez Glossia pour des travaux linguistiques pilotés par modèle qui suivent la livraison du dépôt et réutilisent vos validations existantes.",
  category: "Explication",
  markdown_only: true,
  section: "translation",
  order: 23
}
---

**Choisissez Glossia lorsque vous souhaitez que l'automatisation linguistique fonctionne comme le reste de votre livraison logicielle :** instructions contrôlées par la source, vos propres jetons de modèle, des contrôles natifs du dépôt, et des pull requests pour révision.

[Weblate](https://weblate.org/) est un système de localisation open source avec une interface de traduction web, une intégration au contrôle de version et des options d'hébergement autonome. Le code public et l'intégration Git ne sont pas exclusifs à Glossia. La raison de choisir Glossia réside dans sa combinaison de livraison centrée sur le dépôt, de transformations pilotées par le modèle et de contexte linguistique réutilisable à la fois pour les humains et les agents.

## Pourquoi choisir Glossia

| Votre priorité | L'avantage de Glossia |
|---|---|
| Conserver la révision dans le flux de travail du produit | Réviser la sortie source réellement contrôlée par le dépôt à travers les modifications de dépôt et les pull requests. |
| S'aligner avec un dépôt source en évolution rapide | La détection de changements et la publication en lot soutiennent une boucle de localisation continue sans traduire à nouveau les entrées inchangées. |
| Emportez vos propres jetons de modèle | Configurez les modèles pris en charge avec des identifiants de fournisseur à portée du compte et sélectionnez-les avec des gestionnaires appartenant au dépôt. |
| Réutiliser la validation native | Exécutez la commande de validation propre au dépôt sur un candidat à sa véritable destination de fichier. |
| Réutiliser le contexte au-delà de la traduction | La voix partagée et la terminologie peuvent orienter le nouveau contenu et les intégrations d'agents via les interfaces MCP et REST. |

## Conserver le dépôt comme surface de révision

Glossia est conçu pour une équipe qui utilise déjà Git pour décider de ce qui est prêt à être envoyé. Sa configuration de localisation se trouve à côté du contenu, et ses sorties proposées peuvent être révisées via le même processus que le changement de produit.

Weblate s'intègre également au contrôle de version. Son interface de traduction basée sur le navigateur peut être exactement ce dont une communauté de contributeurs a besoin. L'accent de Glossia diffère : préserver le périmètre de révision du dépôt et amener l'automatisation linguistique à celui-ci, plutôt que de faire d'une autre interface de modification le centre du travail de l'équipe.

## Emportez vos propres jetons et clarifiez les choix de modèle

Glossia utilise des modèles pris en charge configurés avec vos jetons d'API fournisseur. La configuration du dépôt se réfère à des gestionnaires de modèle stables ; les secrets restent dans les paramètres de compte. Vous pouvez sélectionner différents modèles configurés selon la portée du contenu ou la cible locale et faire la rotation des jetons sans modifier chaque dépôt.

Voir [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider).

## Réutiliser les contrôles qui définissent un changement livrable

Les contrôles structurels intégrés à Glossia ne constituent qu'une partie de la frontière de qualité. À travers `L10N.md`, il peut exécuter un script de validation natif du dépôt, un analyseur, un compilateur ou une vérification de documentation sur le candidat à son chemin de cible réel.

Ceci est utile lorsque le contenu traduit inclut plus que de simples chaînes : formats spécifiques à l'application, composants Markdown, métadonnées structurées et contraintes que le projet sait déjà vérifier. La validation et la récupération restent connectées aux fichiers réels que votre pipeline publiera.

L'environnement d'exécution a toujours besoin des dépendances du validateur, et la validation structurelle ne découle pas l'exactitude linguistique. Voir [L10N.md](/docs/reference/l10n-md) et [Récupération de traduction](./translation-recovery).

## La source publique est une référence, pas toute la comparaison

Le noyau de Glossia est public et peut être inspecté, modifié, distribué et auto-hébergé sous [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), ce qui permet des services hébergés compétitifs. Le code d'entreprise sous `ee/` dispose d'une [licence](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) distincte exigeant un accord commercial écrit pour une utilisation en production. Ce modèle open-core diffère du licensing basé sur la GPL de Weblate.

Si le choix du licensing GPL et une interface de traduction web établie sont vos critères principaux, Weblate mérite d'être pris en compte. Si l'objectif est **vos propres identifiants de modèle, les vérifications de dépôt existantes et les travaux linguistiques qui suivent la livraison logicielle**, Glossia rassemble ces choix ensemble dans un OS linguistique.

Cette comparaison ne prétend pas que Weblate manque d'automatisation, de fonctionnalités de validation ou d'intégrations de fournisseurs, et ne promet ni migration automatique ni correspondance fonctionnelle. Pour les capacités actuelles, voir [la documentation de Weblate](https://docs.weblate.org/).
