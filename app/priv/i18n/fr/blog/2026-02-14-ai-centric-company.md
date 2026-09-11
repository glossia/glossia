%{
  title:
    "Construire une entreprise axée sur l'IA pour défier une industrie incapable de se réinventer elle-même.",
  summary:
    "Les entreprises de localisation établies ont le capital, mais pas la liberté d'innover. Nous concevons Glossia de toutes pièces autour de l'IA et des agents, non seulement dans le produit, mais dans la manière dont nous gérons l'entreprise entière.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
Les LLMs et les agents transforment tout. Pas seulement ce que le logiciel peut faire, mais comment les entreprises sont construites pour produire ce logiciel. À [Glossia](https://glossia.ai), nous le voyons comme une opportunité unique en génération pour repenser la manière dont le contenu atteint chaque langue. Mais nous savons aussi qu'une bonne idée de produit ne suffit pas. Il vous faut une organisation capable de bouger assez vite pour qu'elle compte.

Cette seconde partie est ce dont traite ce post.

## Le dilemme de l'innovateur, se jouant en temps réel

L'industrie de la localisation est vaste et bien financée. Des entreprises comme Smartling, Phrase, Crowdin et Lokalise construisent des outils et des services depuis des années. Elles disposent de clients, de revenus, de flux de travail établis et d'équipes qui savent vender et soutenir leurs produits.

Alors pourquoi une petite équipe ciblée essaierait-elle même ?

À cause de quelque chose que Clayton Christensen a décrit dans [Le Dilemme de l'Innovateur](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): les entreprises établies ont du mal à adopter l'innovation disruptive, non pas parce qu'elles manquent de ressources, mais parce que leurs modèles d'affaires existants, les attentes de leurs clients et leurs structures organisationnelles les empêchent de le faire.

Ces entreprises ont construit leurs produits autour des mémoires de traduction, de la tarification au mot et des flux de travail de traducteurs humains. Leurs clients ont construit des modèles mentaux et des processus autour de ces briques. Changer les fondations signifie rompre des promesses faites aux clients existants, requalifier les équipes et repenser les modèles de revenus. Même avec les meilleures intentions et le capital à investir, l'inertie organisationnelle est énorme.

Ils ont besoin d'une capacité d'innovation et de l'engagement de leur main-d'œuvre pour embrasser de nouvelles idées. Mais le plus difficile, c'est encore de faire en sorte que leurs clients existants s'engagent avec eux. Et ces clients sont investis dans le modèle ancien.

C'est l'opportunité que nous voyons. Non pas en dépit d'avoir moins de ressources, mais grâce à cela. Nous n'avons aucun héritage à protéger, aucun flux de travail à préserver, aucun client à migrer. Nous pouvons tout concevoir de toutes pièces.

> \[\!NOTE\]
> Le dilemme de l'innovateur ne concerne pas la technologie. Il s'agit d'incitations. Les entreprises établies optimisent pour ce que leurs clients actuels veulent, ce qui rend la poursuite de quelque chose de fondamentalement différent presque impossible.

## IA au centre, pas en périphérie

La plupart des entreprises adoptent l'IA en la greffant sur leurs processus existants. Un chatbot ici, un moteur de suggestions là. Nous allons dans le sens inverse : concevoir toute l'entreprise pour être centrée sur l'IA dès le premier jour.

Cela signifie que l'IA n'est pas une fonctionnalité du produit. Elle façonne la manière dont nous Construisons, commercialisons, soutenons et opérons. Chaque décision que nous prenons commence par une question : un agent peut-il le faire ?

Le produit lui-même est un agent qui réside dans votre terminal, lit vos fichiers sources, génère des traductions, lance vos vérifications CI et itère tant que le résultat n'est pas validé. C'est la partie que les gens voient. Mais derrière, c'est la même philosophie qui anime l'entreprise.

## Une petite équipe, déléguant tout le reste aux agents

Nous gardons délibérément l'équipe petite et nous y tenons tant que cela a du sens.

Ce n'est pas une question d'économiser de l'argent. Il s'agit d'éliminer une catégorie entière de travail qui ne génère pas de valeur pour les utilisateurs.

Plus vous ajoutez d'humains, plus vous avez besoin de coordination. Vous mettez en place des systèmes de confiance, des modèles d'autorisation et des chaînes d'approbation. Vous gérez les conflits, alignez les priorités, planifiez des réunions. Tout cela consomme une énergie créative destinée au maintien d'une organisation humaine plutôt qu'à la construction d'un produit.

La manière dont nous parvenons à faire fonctionner cela réside dans la délégation de tout le reste aux agents. Analyse marketing, synthèse des retours clients, recherche concurrentielle, rédaction de contenu, surveillance opérationnelle : le travail de routine de la gestion de l'entreprise est de plus en plus réalisé par des agents que nous façonnons, examinons et améliorons.

## Choix technologiques réfléchis

Nous sommes très intentionnels quant à notre stack, car cela affecte directement la rapidité à laquelle nous avançons et le comportement du logiciel pour les équipes qui l'hébergent elles-mêmes.

**Pour l'agent (CLI) :** Nous avons choisi Rust. Il compile en binaire unique et portable sur toutes les plateformes, sans dépendances d'exécution pour l'utilisateur.

**Pour le serveur :** Nous avons choisi [Elixir](https://elixir-lang.org) et le [Erlang](https://www.erlang.org) runtime. La nature fonctionnelle d'Elixir le rend parfaitement adapté aux charges de travail agentic. La VM Erlang est éprouvée pour la concurrence et la tolérance aux pannes. Et voici un bonus : un agent IA peut introspecter le système Erlang en cours d'exécution pour comprendre ce qui se passe, recueillir des informations et même résoudre des problèmes en production.

**Pour distribution :** Glossia est open source sous la [O'Saasy Licence](https://github.com/glossia/glossia/blob/main/LICENSE.md). Les équipes qui souhaitent l'exécuter elles-mêmes peuvent installer le Helm chart dans le dépôt sur n'importe quel cluster Kubernetes. Le même code alimente le service hébergé à glossia.ai et n'importe quel déploiement auto-hébergé.

> \[\!IMPORTANT\]
> Nous évitons volontairement la complexité technique que les ingénieurs ont tendance à recourir au début lorsque celle-ci n'est pas justifiée. Chaque dépendance et chaque couche d'infrastructure doit justifier son poids.

## Ce que cela débloque

Gérer la société de cette façon ne se limite pas à une simple question d'efficacité. Cela modifie ce que nous pouvons offrir et la vitesse à laquelle nous apprenons.

**Accessible à plus d'équipes.** L'industrie de la localisation a rendu ses outils inaccessibles par une tarification complexe, des frais par mot et des cycles de vente d'entreprise. Si votre flux de travail de traduction nécessite de l'approvisionnement, des négociations de prix et un chef de projet, la plupart des petites équipes ne font que déployer en anglais. En construisant une organisation efficace et en publiant le logiciel en accès libre pour que les équipes puissent l'auto-héberger, nous pouvons rendre Glossia véritablement accessible.

**Une innovation plus rapide.** Nous voulons explorer beaucoup d'idées. De nouvelles interfaces pour l'agent, de meilleures boucles de rétroaction, de nouveaux moyens d'intégrer les linguistes dans le flux de travail. Une entreprise traditionnelle aurait besoin de renforcer l'équipe, d'aligner les équipes et d'organiser des revues de feuille de route. Nous essayons simplement les choses. La distance entre une idée et une expérience déployée se mesure en heures, pas en trimestres.

## Remettre en question comment nous travaillons, pas seulement ce que nous construisons

Nous ne sommes pas émotionnellement attachés aux vieilles façons de faire. Nous questionnons activement ce que signifie la revue de code lorsqu'un agent écrit la plupart du code. Comment fonctionne la collaboration lorsque l'équipe humaine est petite et que les agents effectuent le travail de routine. Comment corriger un bug lorsque l'agent peut inspecter le système en cours d'exécution.

Nous faisons des erreurs. Nous continuerons à les commettre. Mais en restant ouverts sur la manière dont nous concevons et dirigeons l'entreprise, nous continuons à découvrir des idées qui influencent le produit. La manière dont nous fonctionnons n'est pas séparée de ce que nous construisons. C'est la même chose.

[McKinsey l'a récemment décrit](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) ce qu'ils appellent "l'organisation agentique", un nouveau modèle de fonctionnement où les agents IA deviennent des participants à part entière dans la façon dont une entreprise fonctionne. Nous ne le considérons pas comme un modèle. C'est simplement la façon dont nous travaillons.

## Le pari

Nous parions qu'une petite équipe,dotée des bons outils,de la bonne mentalité et sans bagage organisationnel,peut surpasser des entreprises avec des centaines d'employés et des millions en capitaux.Pas sur tous les fronts,mais sur celui qui compte : offrir une expérience de localisation fondamentalement meilleure.

L'industrie ne peut pas se réinventer.Nous pouvons.