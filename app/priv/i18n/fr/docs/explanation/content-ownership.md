%{
  title: "Propriété du contenu et portabilité",
  summary:
    "Pourquoi le contenu du dépôt est important, et quelles dépendances la source publique retire et conserve.",
  category: "explication",
  section: "translation",
  order: 3
}
---

Une entreprise devrait pouvoir changer ses outils linguistiques sans perdre le contenu qu'elle a déjà produit ni la capacité de diffuser ce contenu.

## ## La propriété est plus qu'un bouton d'exportation

L'exportation de fichiers traduits est utile, mais la portabilité inclut également l'historique des relectures, les directives linguistiques, la terminologie et la configuration nécessaires pour continuer le travail. Si celles-ci résident uniquement dans un environnement propriétaire, l'entreprise peut conserver son résultat tout en perdant le processus qui l'a généré.

Le flux de travail du dépôt Glossia conserve les sources publiées et les fichiers traduits dans Git. L'historique des pull requests reste avec le dépôt, et la configuration basée sur les fichiers décrit la transformation indépendamment d'une session d'édition dans le navigateur.

## ## Les décisions linguistiques devraient être réutilisables

Le ton et les directives de glossaire capturent l'intention organisationnelle. Glossia rend ce contexte disponible pour les humains et les intégrations, y compris les agents via MCP. Il s'agit d'une forme de réutilisation différente de la recherche d'un segment auparavant traduit : elle peut orienter de nouveaux contenus même lorsqu'il n'y a aucune phrase correspondante dans une mémoire.

Cela ne rend pas obsolètes les mémoires de traduction basées sur les segments. Les équipes peuvent disposer de traductions revues et de workflows spécialisés précieux qu'elles souhaitent conserver. La position de Glossia est que ces ressources devraient compléter le processus de livraison d'une entreprise plutôt que de devenir une autorité propriétaire obligatoire sur celui-ci.

## ## Le code source public aide, mais n'est pas un plan de sortie magique

La capacité d'examiner et de modifier l'implémentation aide les équipes à comprendre comment leur contenu est traité. Cela ne signifie pas que chaque dépendance opérationnelle disparaît. Une instance Glossia déployée nécessite toujours des bases de données, un accès aux fournisseurs de modèles pour les workflows pertinents, des identifiants et une infrastructure. Le contexte linguistique géré par le tableau de bord nécessite également un plan de migration explicite si une équipe change de systèmes.

Le cœur de Glossia est open source sous Apache-2.0, ce qui permet l'hébergement auto-géré et des services hébergés concurrents selon ses termes. Le code entreprise sous `ee/` est disponible en source sous une licence séparée et nécessite un accord commercial écrit pour une utilisation en production. Consultez la [notice de licence](https://github.com/glossia/glossia/blob/main/LICENSE.md) du dépôt lors de la planification d'un déploiement de remplacement.

## ## Un test utile de portabilité

Demandez si l'équipe peut toujours examiner, revoir et publier son contenu traduit existant si le service linguistique est indisponible. Avec des sorties appartenant au dépôt, la publication ne nécessite pas de rouvrir un éditeur propriétaire simplement pour récupérer le fichier le plus récent.

Demandez ensuite comment les directives linguistiques, les identifiants et l'automatisation se déplaceraient vers un autre système. Ce sont des questions distinctes, et les maintenir explicites est plus utile que de promettre « aucun verrouillage » sans qualification.
