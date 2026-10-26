%{
  title: "Pourquoi Glossia",
  summary:
    "Un système d'exploitation linguistique qui maintient le contenu, le contexte et la relecture alignés avec la livraison continue.",
  category: "Explication",
  section: "translation",
  order: 1
}
---

Un produit peut être publié en continu tandis que ses traductions restent bloquées dans un cycle de mise à jour distinct. Le contenu source change dans Git, quelqu'un l'exporte vers un système de traduction, des éditeurs y travaillent, et quelqu'un importe le résultat. Le produit et ses versions linguistiques divergent.

Glossia est un OS de langue construit autour d'un principe différent : le travail linguistique doit suivre le même cycle de livraison versionné et révisable que le produit lui-même.

## Le problème dépasse la traduction

Les équipes doivent préserver le sens, appliquer la terminologie, adapter le ton à l'audience et mettre à jour le contenu à mesure que le produit évolue. Ces décisions affectent autant la documentation, les chaînes d'interface utilisateur, les pages marketing que les textes générés par des agents.

Un modèle peut produire un brouillon utile. Seul, il ne connaît pas les décisions linguistiques de votre organisation, n'enregistre pas pourquoi une phrase a changé, ne valide pas vos formats de fichier, ni ne synchronise la prochaine révision source. Répéter un prompt n'est pas un système de livraison.

Glossia combine le contexte linguistique avec les mécanismes entourant la génération : configuration, détection des changements, validation, reprise après erreur, historique des révisions et revue.

## Le contenu reste avec le produit

Le dépôt reste l'autorité pour le contenu publié. Les fichiers source, la configuration, les traductions générées et les modifications révisables peuvent voyager via Git et les pull requests. Les équipes n'ont pas besoin de désigner une interface d'édition hébergée comme autorité pour chaque phrase avant de pouvoir livrer une version localisée.

Cela rend les changements linguistiques visibles aux côtés du changement de produit qui les a motivés. Un réviseur peut inspecter le diff, la CI peut valider la sortie et le même pipeline de livraison peut le publier.

Lire [Localisation continue](./continuous-localization) pour le modèle de livraison et [Propriété du contenu](./content-ownership) pour ses implications en matière de portabilité.

## Le contexte est une entrée, pas une cage

Les conseils de Voix et la terminologie aident les humains et les agents à écrire de manière cohérente. Ce sont des décisions linguistiques réutilisables, et non pas simplement une collection exclusive de paires de segments source-cible.

Les mémoires de traduction restent utiles pour les traductions établies et le contenu répétitif. Il ne s'agit pas de les éliminer. Il s'agit d'éviter de faire du format de mémoire d'un fournisseur ou de son flux de travail d'édition le seul endroit où la connaissance linguistique d'une entreprise peut résider.

## L'amélioration est une boucle

Le modèle d'affinement progressif de Glossia utilise des hachages de contenu pour éviter le travail redondant, réalise des validations autour des transformations et expose les échecs afin qu'une exécution puisse récupérer. Les corrections humaines peuvent inspirer la prochaine itération plutôt que de disparaître dans une génération isolée.

L'analytique de localisation fournit une autre donnée : comprendre les langues et les espaces qu'une audience utilise peut aider une équipe à décider où investir. C'est un élément de preuve pour la priorisation, pas une promesse qu'une traduction produira de la croissance.

## À qui cela convient

Glossia est particulièrement pertinent lorsque les développeurs, les linguistes et les équipes produit souhaitent collaborer sur du contenu géré par dépôt et le publier en continu. Ce n'est pas une incitation à ce que chaque organisation abandonne son TMS actuel. Une équipe dont le besoin central est un éditeur web, la coordination d'une agence de traduction ou une mémoire établie importante peut préférer un autre flux de travail.

## Implémentation inspectable

Le code de Glossia est disponible publiquement, y compris son application Phoenix, son CLI Rust, son SDK web et son infrastructure de déploiement. Cela rend les mécaniques du travail linguistique inspectables plutôt qu'une boîte noire.

Glossia suit un modèle open core. Le cœur utilise [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), qui autorise l'utilisation commerciale, la modification, la distribution, l'auto-hébergement et les services hébergés concurrents selon ses conditions. Le code de `ee/` est consultable, mais n'est pas open source. Il relève d'une [licence Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) distincte et son utilisation en production nécessite un accord commercial écrit.
