%{
  title: "Propriété et portabilité du contenu",
  summary:
    "Pourquoi le contenu du dépôt est important, et quelles dépendances la source publique supprime et ne supprime pas.",
  category: "Explication",
  section: "translation",
  order: 3
}
---

Une entreprise doit pouvoir changer ses outils linguistiques sans perdre le contenu qu'elle a déjà produit ni la capacité de diffuser ce contenu.

## La propriété est plus qu'un bouton d'exportation

L'exportation de fichiers traduits est utile, mais la portabilité inclut également l'historique des révisions, les directives linguistiques, la terminologie et la configuration nécessaires pour poursuivre le travail. Si tout cela réside uniquement dans un seul espace de travail propriétaire, l'entreprise peut conserver sa production tout en perdant le processus qui l'a générée.

Le workflow de dépôt de Glossia conserve les sources publiées et les fichiers traduits dans Git. L'historique des pull requests reste avec le dépôt, et la configuration basée sur les fichiers décrit la transformation indépendamment d'une session d'édition dans un navigateur.

## Les décisions linguistiques doivent être réutilisables

La voix et les directives de glossaire capturent l'intention organisationnelle. Glossia rend ce contexte disponible aux humains et aux intégrations, y compris aux agents via MCP. Il s'agit d'une forme de réutilisation différente de la recherche d'un segment déjà traduit : elle peut guider de nouveaux contenus même lorsqu'il n'y a pas de phrase correspondante dans une mémoire.

Cela ne rend pas les mémoires de traduction basées sur des segments obsolètes. Les équipes peuvent avoir des traductions révisées précieuses et des flux de travail spécialisés qu'elles souhaitent conserver. La position de Glossia est que ces ressources doivent compléter le processus de livraison d'une entreprise plutôt que de devenir une autorité propriétaire obligatoire sur celui-ci.

## La source publique aide, mais ce n'est pas un plan magique de sortie

La capacité d'inspecter et de modifier l'implémentation aide les équipes à comprendre comment leur contenu est traité. Cela ne signifie pas que chaque dépendance opérationnelle disparaît. Une instance de Glossia déployée nécessite toujours des bases de données, un accès aux fournisseurs de modèles pour les workflows pertinents, des identifiants et une infrastructure. Le contexte linguistique géré par le tableau de bord nécessite également un plan de migration explicite si une équipe change de systèmes.

Glossia suit un modèle open core. Le cœur utilise [Apache-2.0](https://github.com/glossia/glossia/blob/main/LICENSE-APACHE), qui autorise l'utilisation commerciale, la modification, la distribution, l'auto-hébergement et les services hébergés concurrents selon ses conditions. Le code de `ee/` est consultable, mais n'est pas open source. Il relève d'une [licence Enterprise](https://github.com/glossia/glossia/blob/main/ee/LICENSE.md) distincte et son utilisation en production nécessite un accord commercial écrit.

## Un test de portabilité utile

Demandez si l'équipe peut toujours inspecter, réviser et publier son contenu traduit existant si le service linguistique n'est pas disponible. Avec des sorties appartenant au dépôt, la publication ne nécessite pas de rouvrir un éditeur propriétaire uniquement pour récupérer le dernier fichier.

Ensuite, demandez comment les directives linguistiques, les identifiants et l'automatisation se déplaceraient vers un autre système. Ce sont des questions séparées, et les garder explicites est plus utile que promettre « sans verrouillage » sans réserve.
