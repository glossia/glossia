%{
  title: "Glossia contre Weblate",
  summary:
    "Choisissez Glossia pour des travaux linguistiques pilotés par les modèles qui respectent les livraisons de dépôt et réutilisent votre validation existante.",
  category: "explication",
  section: "translation",
  order: 23
}
---

**Choisissez Glossia lorsque vous souhaitez que l'automatisation linguistique fonctionne comme le reste de votre livraison de logiciels :** instructions sous contrôle de version, vos propres jetons de modèle, les vérifications natives du dépôt et les pull requests pour examen.

[Weblate](https://weblate.org/) est un système de localisation open-source avec une interface de traduction web, une intégration contrôle-de-version et des options auto-hébergement. Le code public et l'intégration Git ne sont pas exclusifs à Glossia. La raison de choisir Glossia est sa combinaison de livraison centrée sur le dépôt, de transformations pilotées par le modèle et de contexte linguistique réutilisable à la fois pour les humains et les agents.

## Pourquoi choisir Glossia

| Votre priorité | Avantage de Glossia |
|---|---|
| Gardez l'examen dans le flux de travail du produit | Examinez le résultat réel sous contrôle de version à travers les modifications du dépôt et les pull requests. |
| Suivez un référentiel source en évolution rapide | La détection de changement et la publication en lots soutiennent une boucle de localisation continue sans re-traduire à chaque fois des entrées inchangées. |
| Apportez vos propres jetons de modèle | Configurez les modèles pris en charge avec des identifiants de fournisseur à portée compte et sélectionnez-les avec des identifiants possédés par le dépôt. |
| Réutiliser la validation native | Exécutez la commande de validation native du dépôt sur un candidat à son véritable chemin cible. |
| Réutiliser le contexte au-delà de la traduction | La voix et la terminologie partagées peuvent orienter le nouveau contenu et les intégrations agents via les interfaces MCP et REST. |

## Gardez le dépôt comme surface de révision

Glossia est conçu pour une équipe qui utilise déjà Git pour décider ce qui est prêt à être livré. Sa configuration de localisation réside à côté du contenu, et ses sorties proposées peuvent être examinées par le même processus que le changement du produit.

Weblate s'intègre également au contrôle de version. Son interface web de traduction est peut-être exactement ce dont une communauté de contributeurs a besoin. L'accent de Glossia est différent : préserver la frontière de révision du dépôt et amener l'automatisation linguistique à celle-ci, plutôt que de faire d'une autre interface d'édition le centre du travail de l'équipe.

## Apportez vos propres jetons et expliciterez vos choix de modèle

Glossia utilise des modèles pris en charge configurés avec vos jetons API de fournisseur. La configuration du dépôt fait référence à des identifiants de modèle stables ; les secrets restent dans les paramètres du compte. Vous pouvez sélectionner différents modèles configurés selon l'étendue de contenu ou la cible locale et renouveler les identifiants sans modifier chaque dépôt.

Cela donne à votre équipe un emplacement explicite pour choisir les modèles qui génèrent son contenu. Elle ne promet pas qu'un jeton ou modèle donné soit pris en charge, ni que la génération élimine le besoin de révision humaine. Consultez [Configurer un fournisseur de modèle](/docs/how-to/configure-a-model-provider)

## Réutiliser les vérifications qui définissent un changement livrable

Les vérifications structurelles intégrées de Glossia ne constituent qu'une partie de la frontière qualité. Par `L10N.md`, il peut exécuter le script de validation natif du dépôt, son analyseur, son compilateur ou sa vérification de documentation sur le candidat à son véritable chemin cible.

Ceci est utile lorsque le contenu traduit inclut plus que des chaînes simples : des formats spécifiques à l'application, des composants Markdown, des métadonnées structurées et des contraintes que le projet sait déjà vérifier. La validation et la récupération restent connectées aux fichiers effectifs que votre pipeline publie.

L'environnement d'exécution nécessite toujours les dépendances du validateur, et la validation structurelle n'établit pas la précision linguistique. Consultez [L10N.md](/docs/reference/l10n-md) et [Récupération de traduction](./translation-recovery)

## Le code source public est une base, pas la comparaison entière

L'implémentation de Glossia est publique et peut être examinée, modifiée et auto-hébergée sous [O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). La licence restreint les services d'hébergement concurrents ; elle n'est pas la même que la licence open-source basée sur la GPL de Weblate.

Si une licence open-source sans restriction et une interface web de traduction établie sont vos critères primaires, Weblate mérite considération. Si l'objectif est **vos propres identifiants de modèle, les vérifications de dépôt existantes et un travail linguistique qui suit la livraison de logiciels**, Glossia rassemble ces choix dans un système d'exploitation linguistique.

Cette comparaison ne prétend pas que Weblate manque d'automatisation, de fonctionnalités de validation ou d'intégrations de fournisseur, et ne promet pas de migration automatique ou de parité fonctionnelle. Consultez [la documentation Weblate](https://docs.weblate.org/) pour les capacités actuelles.
