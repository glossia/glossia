%{
  title:
    "Construire une entreprise axée sur l'IA pour défier une industrie incapable de se réinventer.",
  summary:
    "Les sociétés de localisation établies ont le capital mais pas la liberté d'innover. Nous concevons Glossia de toutes pièces autour de l'IA et des agents, non seulement dans le produit, mais dans la manière dont nous gérons l'ensemble de l'entreprise.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
Les LLM et les agents transforment tout. Non seulement ce que les logiciels peuvent faire, mais comment les entreprises sont construites pour créer ces logiciels. Chez [Glossia](https://glossia.ai), nous percevons cela comme une opportunité unique en une génération pour repenser la façon dont le contenu atteint chaque langue. Mais nous savons également qu'une bonne idée de produit ne suffit pas. Il vous faut une organisation capable d'agir assez rapidement pour faire la différence.

Cette deuxième partie est le sujet de ce post.

## Le dilemme de l'innovateur, qui se joue en temps réel

L'industrie de la localisation est vaste et bien financée. Des entreprises comme Smartling, Phrase, Crowdin et Lokalise développent des outils et des services depuis des années. Elles disposent de clients, de revenus, de flux de travail établis et d'équipes qui savent vendre et soutenir leurs produits.

Alors pourquoi une petite équipe ciblée essaierait-elle même ?

En raison de quelque chose que Clayton Christensen a décrit dans [Le Dilemme de l'Innovateur](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): les entreprises établies peinent à adopter l'innovation disruptive, non parce qu'elles manquent de ressources, mais parce que leurs modèles commerciaux existants, leurs attentes clients et leurs structures organisationnelles les en empêchent.

Ces entreprises ont construit leurs produits autour des mémoires de traduction, de la tarification au mot et des flux de travail des traducteurs humains. Leurs clients ont construit des modèles mentaux et des processus autour de ces briques. Changer les fondations signifie rompre les promesses faites aux clients existants, requalifier les équipes et repenser les modèles de revenus. Même avec les meilleures intentions et le capital à investir, l'inertie organisationnelle est immense.

Elles ont besoin de capacités d'innovation et de l'engagement de leur effectif pour embrasser de nouvelles idées. Mais encore plus difficile, elles doivent emmener leurs clients existants à passer le pas avec elles. Et ces clients sont investis dans l'ancien modèle.

Voici l'opportunité que nous voyons. Non pas malgré d'avoir moins de ressources, mais à cause de cela. Nous n'avons aucun système legacy à protéger, aucun flux de travail à conserver, aucun client à migrer. Nous pouvons tout concevoir de toutes pièces.

> \[\!NOTE\]
> Le dilemme de l'innovateur ne concerne pas la technologie. Il porte sur les incitations. Les entreprises établies optimisent pour ce que leurs clients actuels veulent, ce qui rend presque impossible de s'engager dans quelque chose de fondamentalement différent.

## L'IA au centre, pas en périphérie

La plupart des entreprises adoptent l'IA en la greffant à leurs processus existants. Un chatbot ici, un moteur de suggestions là. Nous allons dans le sens inverse : concevoir l'entreprise entière pour être centrée sur l'IA dès le premier jour.

Cela signifie que l'IA n'est pas une fonctionnalité du produit. Elle façonne la manière dont nous construisons, vendons, supportons et gérons. Chaque décision que nous prenons commence par une question : un agent peut-il faire cela ?

Le produit lui-même est un agent qui réside dans votre terminal, lit vos fichiers sources, génère des traductions, lance vos vérifications CI, et itère jusqu'à ce que la sortie soit valide. C'est la partie que les gens voient. Mais derrière cela, la même philosophie anime l'entreprise.

## Une petite équipe, déléguant tout le reste aux agents

Nous choisissons délibérément de maintenir l'équipe petite et de rester ainsi tant que cela a du sens.

Il ne s'agit pas de faire des économies. Il s'agit d'éliminer une catégorie entière de travail qui ne produit pas de valeur pour les utilisateurs.

Plus vous ajoutez d'humains, plus vous avez besoin de coordination. Vous construisez des systèmes de confiance, des modèles d'autorisations, des chaînes d'approbation. Vous gérez les conflits, alignez les priorités, planifiez des réunions. Tout cela est une énergie créative investie dans le maintien d'une organisation humaine plutôt que dans la construction d'un produit.

La manière dont nous rendons cela possible est de déléguer tout le reste aux agents. Analyse marketing, synthèse des retours clients, recherche concurrentielle, rédaction de contenu, surveillance opérationnelle : le travail routinier de faire fonctionner l'entreprise est de plus en plus réalisé par des agents que nous façonnons, évaluons et améliorons.

## Choix technologiques délibérés

Nous accordons une attention particulière à notre pile technique, car elle affecte directement la rapidité à laquelle nous pouvons avancer et le comportement du logiciel pour les équipes qui l'auto-hébergent.

**Pour l'agent (CLI):** Nous avons choisi Rust. Il compile en binaire unique et portable sur toutes les plateformes sans dépendances runtime pour l'utilisateur.

**Pour le serveur:** Nous avons choisi [Elixir](https://elixir-lang.org) et le [Erlang](https://www.erlang.org) runtime. La nature fonctionnelle d'Elixir en fait un excellent choix pour les charges de travail agentiques. La VM Erlang est éprouvée pour la concurrence et la tolérance aux pannes. Et voici un bonus : un agent IA peut introspecter le système Erlang en cours d'exécution pour comprendre ce qui se passe, recueillir des informations, et même corriger les problèmes en production.

**Pour la distribution :** Glossia fonctionne en tant que service hébergé à [glossia.ai](https://glossia.ai). Un seul chemin de code, un seul déploiement, un seul point de raisonnement - aucune séparation entre un build on-prem et un build hébergé, sans infrastructure par tenant à coordonner.

> \[\!IMPORTANT\]
> Nous agissons avec intention en évitant la complexité technique que les ingénieurs ont tendance à chercher dès le début même si ce n'est pas justifié. Chaque dépendance et chaque couche d'infrastructure doit justifier son poids.

## Ce que cela débloque

Diriger l'entreprise ainsi n'est pas seulement une question d'efficacité. Cela change ce que nous pouvons offrir et à quelle vitesse nous pouvons apprendre.

**Accessible à plus d'équipes.** Le secteur de la localisation a rendu ses outils inaccessibles via des tarifs complexes, des frais au mot et des cycles de vente d'entreprise. Si votre flux de travail de traduction nécessite des achats, des négociations de prix et un chef de projet, la plupart des petites équipes se contenteront de déployer en anglais. En construisant une organisation efficace, nous pouvons tarifier Glossia de sorte que le déploiement dans une langue seconde soit une décision que tout le monde dans l'équipe peut prendre, et non un projet d'approvisionnement.

**Une innovation plus rapide.** Nous souhaitons explorer beaucoup d'idées. Nouvelles interfaces pour l'agent, meilleures boucles de rétroaction, nouveaux moyens d'intégrer les linguistes dans le flux de travail. Une entreprise traditionnelle aurait besoin de renforcer l'équipe, d'aligner les équipes et de programmer des revues de feuille de route. Nous essayons simplement des choses. La distance entre une idée et une expérience déployée se mesure en heures, non en trimestres.

## Remettre en question la façon dont nous travaillons, pas seulement ce que nous construisons

Nous ne sommes pas attachés émotionnellement aux méthodes traditionnelles. Nous interrogeons activement ce que signifie la révision de code lorsque l'agent rédige la majeure partie du code. Comment fonctionne la collaboration lorsque l'équipe humaine est petite et que les agents font le travail courant. Comment vous corrigez un bug lorsque l'agent peut inspecter le système en cours d'exécution.

Nous faisons des erreurs. Nous continuerons à les faire. Mais en restant ouverts d'esprit sur la manière dont nous concevons et gérons l'entreprise, nous continuons de découvrir des idées qui influencent le produit. La façon dont nous opérationnons n'est pas séparée de ce que nous construisons. Ce sont la même chose.

[McKinsey a récemment décrit](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) ce qu'ils appellent « l'organisation agentic », un nouveau modèle opérationnel où les agents d'IA deviennent des participants à part entière du fonctionnement d'une entreprise. Nous ne le considérons pas comme un modèle. C'est simplement la façon dont nous travaillons.

## Le pari

Nous parions qu'une petite équipe équipée des bons outils, de la bonne mentalité et sans bagage organisationnel puisse dépasser des entreprises comptant des centaines d'employés et des millions de financements. Pas sur tous les fronts, mais sur celui qui compte : offrir une expérience de localisation fondamentalement meilleure.

L'industrie ne peut pas se réinventer. Nous pouvons.