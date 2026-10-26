%{
  title: "La propriété et la portabilité du contenu",
  summary:
    "Pourquoi le contenu appartenant au dépôt compte, et quelles dépendances la source publique supprime ou conserve.",
  category: "explication",
  section: "translation",
  order: 3
}
---

Une entreprise doit pouvoir modifier ses outils linguistiques sans perdre le contenu qu'elle a déjà produit ni la capacité de publier ce contenu.

## La propriété est plus qu'un bouton d'exportation

L'exportation de fichiers traduits est utile, mais la portabilité inclut également l'historique des révisions, les directives linguistiques, la terminologie et la configuration nécessaires pour poursuivre le travail. Si celles-ci résident uniquement au sein d'un seul environnement de travail propriétaire, l'entreprise peut conserver sa production tout en perdant le processus qui l'a produite.

Le workflow du dépôt de Glossia conserve les sources publiées et les fichiers traduits dans Git. L'historique des demandes de tirage reste dans le dépôt, et la configuration basée sur les fichiers décrit la transformation indépendamment d'une session d'édition dans un navigateur.

## Les décisions linguistiques doivent être réutilisables

Les directives de voix et de glossaire capturent l'intention organisationnelle. Glossia rend ce contexte disponible pour les humains et les intégrations, y compris les agents via MCP. Il s'agit d'une forme de réutilisation différente de la recherche d'un segment déjà traduit : elle peut orienter un nouveau contenu même s'il n'y a aucune phrase correspondante dans une mémoire.

Cela ne rend pas les mémoires de traduction par segment obsolètes. Les équipes peuvent avoir des traductions révisées précieuses et des workflows spécialisés qu'elles souhaitent conserver. La position de Glossia est que de telles ressources devraient compléter le processus de livraison d'une entreprise plutôt que d'en devenir une autorité propriétaire obligatoire.

## La source publique aide, mais ce n'est pas un plan de sortie magique

La capacité à inspecter et modifier l'implémentation aide les équipes à comprendre comment leur contenu est traité. Cela ne signifie pas que chaque dépendance opérationnelle disparaît. Une instance déployée de Glossia a toujours besoin de bases de données, d'un accès au fournisseur de modèle pour les workflows pertinents, d'identifiants et d'infrastructure. Le contexte linguistique géré par le tableau de bord a également besoin d'un plan de migration explicite si une équipe change de systèmes.

La licence O'Saasy actuelle limite les services hébergés concurrents. La disponibilité de la source publique n'est pas la même qu'une licence open-source illimitée ou une garantie qu'un service de remplacement peut être exploité selon n'importe quel modèle économique. Consultez la [licence](https://github.com/glossia/glossia/blob/main/LICENSE.md) du dépôt.

## Un test de portabilité utile

Demandez-vous si l'équipe peut toujours inspecter, examiner et publier son contenu traduit existant si le service de langue n'est pas disponible. Avec des sorties appartenant au dépôt, la publication ne nécessite pas de rouvrir un éditeur propriétaire juste pour récupérer le dernier fichier.

Ensuite, demandez comment les directives linguistiques, les identifiants et l'automatisation passeraient à un autre système. Ce sont des questions séparées, et les garder explicites est plus utile que de promettre "sans verrouillage" sans réserve.
