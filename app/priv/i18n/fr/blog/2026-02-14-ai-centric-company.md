%{
  title:
    "Construire une entreprise centrée sur l'IA pour défier un secteur qui ne peut pas se réinventer.",
  summary:
    "Les entreprises de localisation établies ont le capital mais pas la liberté d'innover. Nous concevons Glossia de toutes pièces autour de l'IA et des agents, non seulement dans le produit, mais dans la façon dont nous gérons l'ensemble de l'entreprise.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
Les LLM et les agents transforment tout. Non seulement ce que le logiciel peut faire, mais la manière dont les entreprises sont construites pour produire ce logiciel. À [Glossia](https://glossia.ai), nous voyons cela comme une opportunité d'envergure générationnelle pour repenser la façon dont le contenu atteint chaque langue. Mais nous savons aussi qu'avoir une bonne idée de produit ne suffit pas. Il faut une organisation capable de bouger assez vite pour compter.

La deuxième partie est ce dont il s'agit dans ce post.

## Le dilemme de l'innovateur, dont l'issue se joue en temps réel

L'industrie de la localisation est vaste et bien financée. Des entreprises comme Smartling, Phrase, Crowdin et Lokalise construisent des outils et des services depuis des années. Elles ont des clients, des revenus, des flux de travail établis et des équipes qui savent vendre et supporter leurs produits.

Alors pourquoi une petite équipe ciblée essaierait-elle même ?

En raison d'un concept que Clayton Christensen a décrit dans [Le Dilemme de l'innovateur](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): les entreprises établies peinent à adopter l'innovation disruptive, non pas parce qu'elles manquent de ressources, mais parce que leurs modèles d'affaires existants, les attentes de leurs clients et leurs structures organisationnelles les en empêchent.

Ces entreprises ont construit leurs produits autour de mémoires de traduction, de tarification au mot et de flux de travail des traducteurs humains. Leurs clients ont construit des modèles mentaux et des processus autour de ces briques de base. Changer les fondations signifie rompre les promesses faites aux clients existants, reformer les équipes et repenser les modèles de revenus. Même avec les meilleures intentions et le capital à investir, l'inertie organisationnelle est énorme.

Ils ont besoin d'une capacité d'innovation et d'un engagement de leur effectif pour embrasser de nouvelles idées. Mais c'est encore plus difficile; ils ont besoin que leurs clients existants les accompagnent. Et ces clients sont attachés au modèle précédent.

C'est l'ouverture que nous voyons. Non pas malgré de moins de ressources, mais à cause de cela. Nous n'avons aucun héritage à protéger, aucun flux de travail à préserver, aucun client à migrer. Nous pouvons tout concevoir à partir de zéro.

> \[\!NOTE\]
> Le dilemme de l'innovateur ne réside pas dans la technologie. Il réside dans les incitatifs. Les entreprises établies optimisent pour ce que veulent leurs clients actuels, ce qui rend quasi impossible de poursuivre quelque chose de fondamentalement différent.

## L'IA au centre, pas aux bords.

La plupart des entreprises adoptent l'IA en la greffant sur leurs processus existants. Ici un chatbot, là un moteur de suggestion. Nous allons dans l'autre direction : concevoir l'entreprise entière comme centrée sur l'IA dès le premier jour.

Cela signifie que l'IA n'est pas une fonctionnalité du produit. Elle façonne notre façon de construire, vendre, assister et opérer. Chaque décision que nous prenons commence par une question : un agent peut-il le faire ?

Le produit lui-même est un agent qui réside dans votre terminal, lit vos fichiers source, génère des traductions, exécute vos contrôles CI et itère jusqu'à ce que la sortie soit validée. C'est la partie que les gens voient. Mais derrière, la même philosophie anime l'entreprise.

## Une petite équipe, déléguant tout le reste aux agents

Nous choisissons de maintenir l'équipe petite et de continuer ainsi aussi longtemps que cela a du sens.

Il ne s'agit pas d'économiser de l'argent. Il s'agit d'éliminer une catégorie entière de travail qui ne produit pas de valeur pour les utilisateurs.

Plus vous ajoutez d'humains, plus vous avez besoin de coordination. Vous créez des systèmes de confiance, des modèles de permissions, des chaînes d'approbation. Vous gérez les conflits, alignez les priorités, planifiez des réunions. Tout cela est une énergie créative consacrée à maintenir une organisation humaine plutôt qu'à construire un produit.

La manière dont nous réalisons cela est de déléguer tout le reste aux agents. Analyse marketing, synthèse des retours clients, recherche concurrentielle, rédaction de contenu, surveillance opérationnelle : le travail de routine de l'entreprise est de plus en plus réalisé par des agents que nous façonnons, révisons et améliorons.

## Choix technologiques délibérés

Nous sommes très intentionnels concernant notre pile car cela affecte directement la vitesse à laquelle nous pouvons avancer et le comportement du logiciel pour les équipes qui l'auto-hébergent.

**Pour l'agent (CLI):** Nous avons choisi Rust. Il compile en binaires uniques et portables sur toutes les plateformes sans dépendances runtime pour l'utilisateur.

**Pour le serveur:** Nous avons choisi [Elixir](https://elixir-lang.org) et le [Erlang](https://www.erlang.org) runtime. La nature fonctionnelle d'Elixir en fait un excellent choix pour les charges de travail d'agents. La VM Erlang est éprouvée pour la concurrence et la tolérance aux pannes. Et voici un bonus : un agent IA peut introspecter le système Erlang en cours d'exécution pour comprendre ce qui se passe, recueillir des informations, et même corriger des problèmes en production.

**Pour distribution :** Glossia est open source sous la [O'Saasy Licence](https://github.com/glossia/glossia/blob/main/LICENSE.md). Les équipes souhaitant l'exécuter elles-mêmes peuvent installer le Helm chart dans le dépôt sur n'importe quel cluster Kubernetes.

> \[\!IMPORTANT\]
> Nous sommes résolus à éviter la complexité technique que les ingénieurs ont tendance à adopter trop tôt lorsqu'elle n'est pas justifiée. Chaque dépendance et chaque couche d'infrastructure doit justifier son poids.

## Ce que cela débloque

Gérer l'entreprise ainsi n'est pas seulement une question d'efficacité. Cela change ce que nous pouvons offrir et la rapidité avec laquelle nous pouvons apprendre.

**Accessible à plus d'équipes.** L'industrie de la localisation a rendu ses outils inaccessibles par une tarification complexe, des tarifs au mot et des cycles de vente d'entreprise. Si votre flux de travail de traduction nécessite de l'approvisionnement, des négociations de prix et un chef de projet, la plupart des petites équipes ne livreront simplement qu'en anglais. En construisant une organisation efficace et en diffusant le logiciel en open source pour que les équipes puissent l'auto-héberger, nous pouvons rendre Glossia véritablement accessible.

**Une innovation plus rapide.** Nous voulons explorer beaucoup d'idées. Nouvelles interfaces pour l'agent, meilleures boucles de rétroaction, nouvelles façons d'intégrer les linguistes dans le flux de travail. Une entreprise traditionnelle devrait renforcer ses effectifs, aligner les équipes et planifier des revues de roadmap. Nous essayons simplement. La distance entre une idée et une expérience déployée se mesure en heures, pas en trimestres.

## Remettre en question la façon dont nous travaillons, pas seulement ce que nous construisons

Nous ne sommes pas attachés émotionnellement aux anciennes façons de faire. Nous mettons activement en question le sens de la revue de code lorsqu'un agent rédige la plupart du code. Comment la collaboration fonctionne lorsque l'équipe humaine est petite et que les agents réalisent le travail de routine. Comment corriger un bug lorsque l'agent peut inspecter le système en cours d'exécution.

Nous faisons des erreurs. Nous allons continuer à en commettre. Mais en restant ouverts d'esprit quant à la façon dont nous concevons et dirigeons l'entreprise, nous continuons à découvrir des idées qui influencent le produit. La manière dont nous fonctionnons n'est pas séparée de ce que nous construisons. Ce sont la même chose.

[McKinsey a récemment décrit](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) ce qu'ils appellent "l'organisation agencée", un nouveau modèle opérationnel où les agents IA deviennent des participants à part entière dans le fonctionnement d'une entreprise. Nous ne pensons pas à cela comme à un modèle. C'est simplement la façon dont nous travaillons.

## Le pari

Nous parions qu'une petite équipe disposant des bons outils, de la bonne mentalité et sans bagage organisationnel peut devancer des entreprises comptant des centaines d'employés et des millions en fonds. Pas sur tous les fronts, mais sur celui qui compte : livrer une expérience de localisation fondamentalement meilleure.

L'industrie ne peut pas se réinventer. Nous pouvons.