%{
  title: "Propriété et portabilité du contenu",
  summary:
    "Pourquoi le contenu du dépôt est important, et quelles dépendances la source publique retire ou conserve.",
  category: "explication",
  section: "translation",
  order: 3
}
---

Une entreprise devrait pouvoir modifier ses outils linguistiques sans perdre le contenu déjà produit ni la capacité de distribuer ce contenu.

## La propriété est plus qu'un bouton d'exportation

L'exportation de fichiers traduits est utile, mais la portabilité inclut également l'historique des relectures, les directives linguistiques, la terminologie et la configuration nécessaires pour poursuivre le travail. Si elles résident uniquement dans un espace de travail propriétaire, l'entreprise peut conserver son résultat tout en perdant le processus qui l'a généré.

Le workflow de dépôt de Glossia conserve les sources publiées et les fichiers traduits dans Git. L'historique des demandes de fusion reste dans le dépôt, et la configuration basée sur des fichiers décrit la transformation indépendamment d'une session d'édition dans un navigateur.

## Les décisions linguistiques doivent être réutilisables

Le ton et les directives du glossaire capturent l'intention organisationnelle. Glossia rend ce contexte disponible pour les humains et les intégrations, y compris des agents via MCP. Il s'agit d'une forme de réutilisation différente de la recherche d'un segment précédemment traduit : cela peut orienter le nouveau contenu même lorsqu'il n'existe aucune phrase correspondante dans la mémoire.

Cela ne rend pas les mémoires de traduction segmentées obsolètes. Les équipes peuvent disposer de traductions validées précieuses et de workflows spécialisés qu'elles souhaitent préserver. La position de Glossia est que de telles ressources devraient compléter le processus de livraison d'une entreprise plutôt que de devenir une autorité propriétaire obligatoire à son sujet.

## Le code source public aide, mais n'est pas un plan de sortie magique

La capacité d'examiner et de modifier l'implémentation aide les équipes à comprendre comment leur contenu est traité. Cela ne signifie pas que chaque dépendance opérationnelle disparaît. Une instance Glossia déployée nécessite toujours des bases de données, un accès au fournisseur modèle pour les workflows pertinents, des identifiants et une infrastructure. Le contexte linguistique géré par le tableau de bord a également besoin d'un plan de migration explicite si une équipe change de système.

Glossia suit un modèle open core. Le cœur utilise Apache-2.0, qui autorise l'utilisation commerciale, la modification, la distribution, l'auto-hébergement et les services hébergés concurrents selon ses conditions. Le code de `ee/` est consultable, mais n'est pas open source. Il relève d'une licence Enterprise distincte et son utilisation en production nécessite un accord commercial écrit. Consultez la [notice de licence](https://github.com/glossia/glossia/blob/main/LICENSE.md).

## Un test de portabilité utile

Vérifiez si l'équipe peut toujours inspecter, valider et publier le contenu traduit existant si le service linguistique n'est pas disponible. Avec des productions du dépôt, la publication ne nécessite pas de rouvrir un éditeur propriétaire uniquement pour récupérer le dernier fichier.

Ensuite, demandez comment les directives linguistiques, les identifiants et l'automatisation pourraient migrer vers un autre système. Ce sont des questions distinctes, et les rendre explicites est plus utile que de garantir « sans verrouillage » sans réserve.
