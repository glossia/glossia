%{
  title: "Pourquoi Glossia",
  summary:
    "Un OS de langue qui aligne le contenu, le contexte et la relecture avec la livraison continue.",
  category: "explication",
  section: "translation",
  order: 1
}
---

Un produit peut être déployé en continu tandis que sa traduction reste bloquée dans un cycle de release séparé. Le contenu source change dans Git, quelqu'un l'exporte vers un système de traduction, des éditeurs y travaillent, et quelqu'un importe le résultat. Le produit et ses versions linguistiques divergent.

Glossia est un OS linguistique construit sur une prémisse différente : le travail linguistique doit suivre la même boucle de livraison versionnée et révisable que le produit lui-même.

## ## Le problème est plus large que la traduction

Les équipes doivent préserver le sens, appliquer la terminologie, adapter le ton de l'audience et mettre à jour le contenu à mesure que le produit évolue. Ces décisions touchent la documentation, les chaînes d'utilisateurs d'interface utilisateur, les pages marketing et la rédaction générée par des agents de la même manière.

Un modèle peut produire un brouillon utile. Par lui-même, il ne connaît pas les décisions linguistiques de votre organisation, ne note pas pourquoi une phrase a changé, ne valide pas vos formats de fichier, ni ne synchronise la prochaine révision source. Répéter une requête n'est pas un système de livraison.

Glossia combine le contexte linguistique avec les mécanismes entourant la génération : la configuration, la détection des changements, la validation, la récupération en cas d'échec, l'historique des révisions et les revues.

## ## Le contenu reste attaché au produit

Le dépôt reste l'autorité sur le contenu publié. Les fichiers sources, la configuration, les traductions générées et les changements révisables peuvent voyager via Git et les pull requests. Les équipes n'ont pas besoin de faire de l'interface d'édition hébergée l'autorité pour chaque phrase avant de pouvoir livrer une release localisée.

Cela rend les modifications linguistiques visibles à côté de la modification du produit qui les a motivées. Un réviseur peut inspecter le diff, la CI peut valider la sortie, et le même pipeline de livraison peut la publier.

Lisez [Localisation continue](./continuous-localization) pour le modèle de livraison et [Propriété du contenu](./content-ownership) pour ses implications sur la portabilité.

## ## Le contexte est une entrée, pas une cage

Les directives de voix et la terminologie aident à la fois les humains et les agents à écrire de manière cohérente. Ce sont des décisions linguistiques réutilisables, pas seulement une propriété collection de paires de segments source-cible.

Les mémoires de traduction restent utiles pour les traductions établies et les contenus répétitifs. Il ne s'agit pas de les rejeter. Il s'agit d'éviter que le format de mémoire d'un seul fournisseur ou son flux de travail d'édition ne soit le seul endroit où les connaissances linguistiques d'une entreprise peuvent vivre.

## ## L'amélioration est une boucle

Le modèle d'amélioration progressive de Glossia utilise des hachages de contenu pour éviter des tâches redondantes, fait tourner des validations autour des transformations et expose les échecs pour qu'une exécution puisse se rétablir. Les corrections humaines peuvent éclairer la prochaine itération plutôt que de disparaître dans une génération isolée.

L'analyse de la localisation fournit une autre entrée : comprendre les langues et les lieux qu'une audience utilise peut aider une équipe à décider où investir. C'est une preuve pour la priorisation, pas une promesse qu'une traduction produira de la croissance.

## ## À qui cela convient

Glossia est particulièrement pertinent lorsque les développeurs, les linguistes et les équipes produit souhaitent collaborer sur un contenu géré par dépôt et le déployer en continu. Ce n'est pas une affirmation selon laquelle chaque organisation devrait abandonner son TMS existant. Une équipe dont le besoin central est un éditeur basé sur le navigateur mature, la coordination avec une agence de traduction ou une mémoire établie importante pourraitprefer un autre flux de travail.

## ## Mise en œuvre inspectable

Le code de Glossia est publiquement disponible, y compris son application Phoenix, son CLI Rust, son SDK web et son infrastructure de déploiement. Cela rend les mécanismes du travail linguistique inspectables plutôt qu'une boîte noire.

Glossia suit un modèle open-core. Le noyau utilise [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), ce qui permet l'utilisation commerciale, l'hébergement autonome et des services hébergés concurrents. Le répertoire `ee/` dispose d'une [Licence Entreprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) séparée exigeant un accord commercial écrit pour l'usage en production. Lisez la licence applicable avant de redistribuer ou de faire fonctionner les fonctionnalités d'entreprise.
