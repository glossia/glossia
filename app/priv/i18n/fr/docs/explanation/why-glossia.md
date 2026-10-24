%{
  title: "Pourquoi Glossia",
  summary:
    "Un OS linguistique qui maintient le contenu, le contexte et la révision alignés avec la livraison continue.",
  category: "explication",
  section: "translation",
  order: 1
}
---

Un produit peut être diffusé en continu tandis que ses traductions restent bloquées dans un cycle de release séparé. Le contenu source change dans Git, quelqu'un l'exporte vers un système de traduction, les éditeurs travaillent dessus, et quelqu'un importe le résultat. Le produit et ses versions linguistiques s'éloignent l'un de l'autre.

Glossia est un système d'exploitation linguistique construit autour d'une prémisse différente : le travail linguistique doit suivre le même cycle de livraison versionné et revu que celui du produit lui-même.

## ## Le problème est plus vaste que la traduction

Les équipes doivent préserver le sens, appliquer la terminologie, adapter le ton aux attentes du public et mettre à jour le contenu au fur et à mesure que le produit évolue. Ces décisions affectent la documentation, les chaînes d'interface utilisateur, les pages marketing et les textes générés par les agents également.

Un modèle peut produire un brouillon utile. Toutefois, il ne sait pas, tout seul, connaître les décisions linguistiques de votre organisation, enregistrer pourquoi une phrase a changé, valider vos formats de fichiers ou synchroniser la révision source suivante. Répéter une instruction n'est pas un système de livraison.

Glossia combine le contexte linguistique avec les mécanismes entourant la génération : configuration, détection des changements, validation, récupération en cas d'échec, historique des révisions et revue.

## ## Le contenu reste attaché au produit

Le dépôt reste l'autorité pour le contenu publié. Les fichiers sources, la configuration, les traductions générées et les modifications revuables peuvent voyager grâce à Git et aux pull requests. Les équipes n'ont pas besoin de rendre une interface d'édition hébergée l'autorité pour chaque phrase avant de pouvoir diffuser une version localisée.

Cela rend les modifications linguistiques visibles à côté de la modification du produit qui les a motivées. Un réviseur peut examiner le diff, le CI peut valider la sortie, et le même pipeline de livraison peut le publier.

Consultez [La localisation continue](./continuous-localization) pour le modèle de livraison et [La propriété du contenu](./content-ownership) pour ses implications de portabilité.

## ## Le contexte est une entrée, pas une cage

Les directives de ton et la terminologie aident à la fois les humains et les agents à écrire de manière cohérente. Ce sont des décisions linguistiques réutilisables, et non une simple collection exclusive de paires de segments source-cible.

Les mémoires de traduction restent utiles pour les traductions établies et le contenu répétitif. L'objectif n'est pas de les rejeter. L'objectif est d'éviter de faire du format de mémoire d'un fournisseur unique ou du flux de travail d'édition le seul lieu où la connaissance linguistique d'une entreprise peut résider.

## ## L'amélioration est un cycle

Le modèle de raffinement progressif de Glossia utilise des hachages de contenu pour éviter les travaux redondants, exécute une validation autour des transformations et expose les échecs afin qu'une exécution puisse récupérer. Les corrections humaines peuvent informer l'itération suivante plutôt que de disparaître dans une génération isolée.

L'analyse de la localisation fournit une autre entrée : comprendre les langues et les marchés sollicités par un public peut aider une équipe à décider où investir. C'est un élément de preuve pour la priorisation, pas une promesse qu'une traduction génère de la croissance.

## ## À qui cela s'adresse

Glossia est particulièrement pertinent lorsque des développeurs, linguistes et équipes produit souhaitent collaborer sur un contenu géré par dépôt et le diffusent en continu. Ce n'est pas une affirmation que chaque organisation devrait abandonner son TMS actuel. Une équipe dont le besoin central est un éditeur basé sur navigateur mature, la coordination avec une agence de traduction, ou une mémoire établie importante pourrait préférer un autre flux de travail.

## ## Implémentation inspectable

Le code de Glossia est disponible publiquement, incluant son application Phoenix, Rust CLI, SDK web et infrastructure de déploiement. Cela rend les mécanismes du travail linguistique inspectables plutôt qu'une boîte noire.

Glossia suit un modèle open core. Le cœur utilise [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), qui autorise l'utilisation commerciale, la modification, la distribution, l'auto-hébergement et les services hébergés concurrents selon ses conditions. Le code de `ee/` est consultable, mais n'est pas open source. Il relève d'une [licence Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) distincte et son utilisation en production nécessite un accord commercial écrit.
