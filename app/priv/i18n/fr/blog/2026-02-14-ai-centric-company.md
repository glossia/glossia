%{
  title:
    "Construire une entreprise centrée sur l'IA pour défier un secteur incapable de se réinventer",
  summary:
    "Les entreprises de localisation établies ont le capital, mais pas la liberté d'innover. Nous concevons Glossia à partir de zéro autour de l'IA et des agents, pas seulement dans le produit, mais dans la manière dont nous gérons l'entreprise entière.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
Les LLM et les agents transforment tout. Non seulement ce que le logiciel peut faire, mais comment les entreprises sont construites pour créer ce logiciel. Chez [Glossia](https://glossia.ai), nous voyons cela comme une opportunité d'une génération pour repenser comment le contenu atteint chaque langue. Mais nous savons aussi qu'une bonne idée de produit ne suffit pas. Il vous faut une organisation capable d'agir assez vite pour compter.

C'est cette deuxième partie dont il est question dans ce post.

## Le dilemme de l'innovateur, se jouant en temps réel

L'industrie de la localisation est vaste et bien financée. Des entreprises comme Smartling, Phrase, Crowdin et Lokalise construisent des outils et services depuis des années. Elles ont des clients, des revenus, des processus établis et des équipes qui savent vendre et soutenir leurs produits.

Alors pourquoi une petite équipe axée essaierait-elle même ?

À cause de quelque chose que Clayton Christensen a décrit dans [Le Dilemme de l'innovateur](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): les entreprises établies peinent à adopter l'innovation de rupture, non pas parce qu'elles manquent de ressources, mais parce que leurs modèles commerciaux existants, les attentes de leurs clients et les structures organisationnelles les en empêchent.

Ces entreprises ont construit leurs produits autour de mémoires de traduction, de la tarification au mot et des flux de travail des traducteurs humains. Leurs clients ont construit des modèles mentaux et des processus autour de ces éléments de base. Changer les fondations signifie rompre les promesses faites aux clients existants, requalifier les équipes et repenser les modèles de revenus. Même avec les meilleures intentions et le capital à investir, l'inertie organisationnelle est énorme.

Ils ont besoin d'une capacité d'innovation et d'un engagement de leurs effectifs pour adopter de nouvelles idées. Mais c'est encore plus difficile : ils ont besoin que leurs clients existants participent. Et ces clients sont attachés à l'ancien modèle.

C'est l'ouverture que nous voyons. Non pas en dépit d'avoir moins de ressources, mais à cause de cela. Nous n'avons aucun héritage à protéger, aucun flux de travail à préserver, aucun client à migrer. Nous pouvons tout concevoir de zéro.

> \[\!NOTE\]
> Le dilemme de l'innovateur ne porte pas sur la technologie. Il s'agit de mécanismes d'incitation. Les entreprises établies optimisent pour ce que leurs clients actuels veulent, ce qui rend presque impossible de poursuivre quelque chose de fondamentalement différent.

## L'IA au centre, pas aux extrémités

La plupart des entreprises adoptent l'IA en la greffant sur leurs processus existants. Un chatbot ici, un moteur de suggestions là. Nous allons dans l'autre sens : concevoir toute l'entreprise pour être centrée sur l'IA dès le premier jour.

Cela signifie que l'IA n'est pas une fonctionnalité du produit. Elle façonne la façon dont nous créons, vendons, soutenons et exploitons. Chaque décision que nous prenons commence par une question : un agent peut-il le faire ?

Le produit lui-même est un agent qui réside dans votre terminal : il lit vos fichiers sources, génère des traductions, exécute vos contrôles CI, et itère jusqu'à ce que la sortie soit acceptée. C'est la partie que les gens voient. Mais derrière, cette même philosophie anime l'entreprise.

## Une petite équipe, déléguant tout le reste aux agents

Nous maintenons volontairement l'équipe petite et restons ainsi aussi longtemps que cela a du sens.

Il ne s'agit pas de faire des économies d'argent. Il s'agit d'éliminer une catégorie entière de travail qui ne produit pas de valeur pour les utilisateurs.

Plus vous ajoutez de personnes, plus vous avez besoin de coordination. Vous construisez des systèmes de confiance, des modèles de permissions, des chaînes d'approbation. Vous gérez les conflits, alignez les priorités, planifiez des réunions. Tout cela représente de l'énergie créative consacrée au maintien d'une organisation humaine plutôt qu'à la création d'un produit.

La façon dont nous faisons fonctionner cela, c'est en déléguant tout le reste aux agents. Analyse marketing, synthèse des retours clients, recherche concurrentielle, rédaction de contenu, surveillance opérationnelle : le travail de routine de gestion de l'entreprise est de plus en plus réalisé par des agents que nous façonnons, examinons et améliorons.

## Des choix technologiques réfléchis

Nous y attachons une grande importance car cela affecte directement la rapidité à laquelle nous pouvons avancer et le comportement du logiciel pour les équipes qui l'auto-hébergent.

**Pour l'agent (CLI) :** Nous avons choisi Rust. Il compile en binaires uniques et portables sur toutes les plateformes sans aucune dépendance runtime pour l'utilisateur.

**Pour le serveur :** Nous avons choisi [Elixir](https://elixir-lang.org) et le [Erlang](https://www.erlang.org) runtime. La nature fonctionnelle d'Elixir en fait un excellent choix pour les charges de travail agentiques. La VM Erlang est éprouvée pour la concurrence et la tolérance aux pannes. Et voici un bonus : un agent IA peut introspecter le système Erlang en cours d'exécution pour comprendre ce qui se passe, recueillir des insights, et même corriger des problèmes en production.

**Pour distribution :** Glossia est open source sous la [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Les équipes souhaitant le faire elles-mêmes peuvent installer le Helm chart dans le dépôt sur n'importe quel cluster Kubernetes. Le même code alimente le service hébergé sur glossia.ai et n'importe quel déploiement auto-hébergé.

> \[\!IMPORTANT\]
> Nous évitons délibérément toute complexité technique que les ingénieurs ont tendance à intégrer trop tôt, avant qu'elle ne soit justifiée. Chaque dépendance et chaque couche d'infrastructure doit justifier son poids.

## Ce que cela débloque

Gérer l'entreprise ainsi n'est pas seulement une stratégie d'efficacité. Cela transforme ce que nous pouvons offrir et la vitesse à laquelle nous apprenons.

**Accessible à plus d'équipes.** L'industrie de la localisation a rendu ses outils inaccessibles par des tarifs complexes, des frais au mot et des cycles de vente d'entreprise. Si votre flux de traduction nécessite des démarches d'approvisionnement, des négociations de prix et un chef de projet, la plupart des petites équipes se contenteront de livrer en anglais. En construisant une organisation efficace et en diffusant le logiciel en open source afin que les équipes puissent auto-héberger, nous pouvons rendre Glossia véritablement accessible.

**Innovation plus rapide.** Nous voulons explorer beaucoup d'idées. De nouvelles interfaces pour l'agent, de meilleures boucles de rétroaction, de nouveaux moyens d'inclure les linguistes dans le flux de travail. Une entreprise traditionnelle aurait besoin de recruter, d'aligner les équipes et de programmer des revues de feuille de route. Nous essayons simplement des choses. La distance entre une idée et une expérimentation déployée est mesurée en heures, pas en trimestres.

## Remettre en question comment nous travaillons, pas seulement ce que nous construisons.

Nous ne sommes pas attachés émotionnellement aux anciennes façons de faire les choses. Nous questionnons activement la signification de la revue de code quand un agent écrit la majeure partie du code. Comment fonctionne la collaboration quand l'équipe humaine est petite et que les agents s'occupent des tâches routinières. Commentcorriger un bug quand l'agent peut inspecter le système en cours d'exécution.

Nous faisons des erreurs. Nous continuerons à en faire. Mais en restant ouvert d'esprit sur la conception et la gestion de l'entreprise, nous découvrons continuellement des idées qui influencent le produit. La façon dont nous opérons n'est pas distincte de ce que nous construisons. Elles sont la même chose.

[McKinsey l'a récemment décrit.](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) ce qu'ils appellent "l'organisation agentic," un nouveau modèle de fonctionnement où les agents d'IA deviennent des acteurs à part entière dans la façon dont une entreprise fonctionne. Nous ne le concevons pas comme un modèle. C'est simplement comment nous travaillons.

## Le pari

Nous parions qu'une petite équipe, dotée des bons outils, de la bonne mentalité et sans bagage organisationnel, pourra surpasser les entreprises comptant des centaines d'employés et des millions de fonds. Pas sur tous les fronts, mais sur celui qui compte : offrir une expérience de localisation fondamentalement meilleure.

L'industrie ne peut pas se réinventer. Nous pouvons.