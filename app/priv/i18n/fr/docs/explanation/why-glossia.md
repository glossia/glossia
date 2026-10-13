%{
  title: "Pourquoi Glossia",
  summary:
    "Un OS linguistique qui maintient le contenu, le contexte et les révisions alignés avec la livraison continue.",
  category: "Explication",
  section: "translation",
  order: 1
}
---

Un produit peut être diffusé en continu tandis que ses traductions restent coincées dans un cycle de version séparé. Le contenu source change dans Git, quelqu'un l'exporte vers un système de traduction, des éditeurs y travaillent, et quelqu'un importe le résultat. Le produit et ses versions linguistiques divergent.

Glossia est un OS linguistique construit autour d'une autre prémisse : le travail linguistique doit suivre le même boucle de livraison versionnée et soumise à revue que le produit lui-même.

## Le problème dépasse la traduction

Les équipes doivent préserver le sens, appliquer la terminologie, adapter le ton à l'audience et mettre à jour le contenu à mesure que le produit évolue. Ces décisions affectent la documentation, les chaînes d'interface utilisateur, les pages marketing et la rédaction générée par des agents.

Un modèle peut produire un brouillon utile. À lui seul, il ne connaît pas les décisions linguistiques de votre organisation, ne recense pas pourquoi une phrase a changé, ne valide pas vos formats de fichier, ne synchronise pas la prochaine révision source. Répéter une invite n'est pas un système de livraison.

Glossia combine le contexte linguistique avec les mécanismes entourant la génération : la configuration, la détection des changements, la validation, la récupération d'échec, l'historique des révisions et la revue.

## Le contenu reste associé au produit

Le dépôt demeure l'autorité pour le contenu publié. Les fichiers source, la configuration, les traductions générées et les modifications révisables peuvent transiter par Git et les pull requests. Les équipes n'ont pas besoin de confier la validation de chaque phrase à une interface d'édition hébergée avant de livrer une version localisée.

Cela rend les évolutions linguistiques visibles à côté du changement de produit qui les a motivées. Un réviseur peut inspecter le diff, la CI peut valider le résultat, et le même flux de livraison peut le publier.

Lisez [Localisation continue](./continuous-localization) pour le modèle de livraison et [Propriété du contenu](./content-ownership) pour ses implications de portabilité.

## Le contexte est une entrée, pas une cage

La guidance de la voix et la terminologie aident à la fois les humains et les agents à écrire de manière cohérente. Ce sont des décisions linguistiques réutilisables, pas simplement une collection propriétaire de segments source-cible.

Les mémoires de traduction restent utiles pour les traductions établies et les contenus répétitifs. L'objectif n'est pas de les jeter à la corbeille. L'objectif est d'éviter que le format mémoire ou le flux de travail d'un fournisseur ne deviennent l'unique endroit où les connaissances linguistiques d'une entreprise peuvent exister.

Voir [Mémoire linguistique et mémoire de traduction](./language-memory-and-translation-memory).

## L'amélioration est une boucle

Le modèle d'affinement progressif de Glossia utilise des hachages de contenu pour éviter un travail redondant, lance des validations autour des transformations et signale les échecs afin qu'une exécution puisse se rétablir. Les corrections humaines peuvent informer la prochaine itération plutôt que de disparaître dans une génération isolée.

L'analyse de localisation fournit une autre donnée : la compréhension des langues et des lieux qu'une audience utilise peut aider une équipe à décider où investir. C'est une base de preuve pour la priorisation, pas une promesse qu'une traduction produira de la croissance.

## Pour qui cela convient

Glossia est particulièrement pertinent lorsque les développeurs, les linguistes et les équipes produit souhaitent collaborer sur du contenu géré par dépôt et le livrer en continu. Ce n'est pas une affirmation selon laquelle chaque organisation devrait abandonner son TMS. Une équipe dont le critère central est un éditeur basé sur le navigateur mature, une coordination agence-traduction ou un mémoire établi important peut préférer un autre flux de travail.

Les comparaisons [Crowdin](./glossia-vs-crowdin), [Lokalise](./glossia-vs-lokalise), [Phrase](./glossia-vs-phrase) et [Weblate](./glossia-vs-weblate) expliquent ces compromis.

## Implémentation inspectable

Le code de Glossia est publiquement disponible, incluant son application Phoenix, la CLI Rust, le SDK web et l'infrastructure de déploiement. Cela rend les mécanismes du travail linguistique inspectables plutôt que d'être une boîte noire.

Le dépôt utilise actuellement la [licence O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md), qui permet l'utilisation et la modification mais restreint les services hébergés concurrents. La disponibilité publique des sources et les libertés de licence sont distinctes ; lisez la licence avant de redistribuer ou d'exploiter un service.
