%{
  title: "Propriété et portabilité du contenu",
  summary:
    "Pourquoi le contenu appartenant au dépôt compte, et quelles dépendances la source publique retire et ne retire pas.",
  category: "explication",
  section: "translation",
  order: 3
}
---

Une entreprise devrait pouvoir changer ses outils linguistiques sans perdre le contenu qu’elle a déjà ni la capacité de distribuer ce contenu.

## La propriété est davantage qu’un bouton d’exportation

L’exportation de fichiers traduits est utile, mais la portabilité inclut également l’historique des revues, les directives linguistiques, la terminologie et la configuration nécessaires pour poursuivre le travail. Si celles-ci vivent uniquement dans un espace de travail propriétaire, l’entreprise peut conserver son produit tout en perdant le processus qui l’a produit.

Le flux de travail du dépôt de Glossia conserve les sources publiées et les fichiers traduits dans Git. L’historique des pull requests subsiste au dépôt, et la configuration basée sur les fichiers décrit la transformation indépendamment d’une session d’édition dans un navigateur.

## Les décisions linguistiques devraient être réutilisables

La voix et les directives du glossaire capturent l’intention organisationnelle. Glossia rend ce contexte disponible pour les humains et les intégrations, y compris les agents via MCP. Il s’agit d’une réutilisation différente de la recherche d’un segment traduit précédemment : elle peut orienter le nouveau contenu même en l’absence de phrase correspondante dans une mémoire.

Cela ne rend pas les mémoires de traduction basées sur les segments obsolètes. Les équipes peuvent avoir des traductions revues précieuses et des flux de travail spécialisés qu’elles souhaitent conserver. La position de Glossia est que ces ressources devraient compléter le processus de livraison d’une entreprise plutôt que de devenir une autorité propriétaire obligatoire à son encontre.

## La source publique aide, mais n’est pas un plan de sortie magique

Pouvoir inspecter et modifier l’implémentation aide les équipes à comprendre comment leur contenu est traité. Cela ne signifie pas que chaque dépendance opérationnelle disparaît. Une instance de Glossia déployée a toujours besoin de bases de données, d’accès aux fournisseurs de modèles pour les flux de travail pertinents, d’identifiants et d’infrastructure. Le contexte linguistique géré par le tableau de bord a également besoin d’un plan de migration explicite si une équipe change de systèmes.

La licence O’Saasy actuelle restreint les services hébergés concurrents. La disponibilité de la source publique n’equivalent pas à une licence open-source sans restriction ni l’assurance qu’un service de remplacement pourra être exploité selon tout modèle économique. Consultez la [licence](https://github.com/glossia/glossia/blob/main/LICENSE.md) du dépôt.

## Un test de portabilité utile

Demandez si l’équipe peut toujours inspecter, revoir et publier le contenu traduit existant si le service linguistique est indisponible. Avec des sorties possédées par le dépôt, la publication ne nécessite pas de rouvrir un éditeur propriétaire juste pour récupérer le fichier le plus récent.

Ensuite, demandez comment les directives linguistiques, les identifiants et l’automatisation se déplaceraient vers un autre système. Ce sont des questions séparées, et les garder explicites est plus utile que de promettre « pas de verrouillage » sans qualification.
