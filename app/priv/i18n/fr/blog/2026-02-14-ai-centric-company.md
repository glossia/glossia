%{
  title:
    "Construire une entreprise axée sur l'IA pour défier une industrie incapable de se réinventer.",
  summary:
    "Les entreprises de localisation établies disposent des capitaux, mais pas de la liberté d'innover. Nous concevons Glossia de toutes pièces autour de l'IA et des agents, non seulement dans le produit, mais dans la manière dont nous gérons l'entreprise dans son ensemble.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
Les LLMs et les agents transforment tout. Non seulement ce que le logiciel peut faire, mais comment les entreprises sont construites pour créer ce logiciel. Chez [Glossia](https://glossia.ai), nous voyons cela comme une opportunité pour générer une fois par génération pour repenser la façon dont le contenu atteint chaque langue. Mais nous savons aussi qu'avoir une bonne idée de produit ne suffit pas. Vous avez besoin d'une organisation capable d'avancer assez vite pour faire la différence.

C'est de cette deuxième partie que parle ce post.

## Le dilemme de l'innovateur, qui se joue en temps réel

L'industrie de la localisation est vaste et bien financée. Des entreprises comme Smartling, Phrase, Crowdin et Lokalise construisent des outils et des services depuis des années. Elles ont des clients, des revenus, des flux de travail établis et des équipes qui savent vendre et supporter leurs produits.

Alors pourquoi une équipe de deux personnes essaierait-elle même ?

C'est à cause d'une chose que Clayton Christensen a décrite dans [Le dilemme de l'innovateur](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma) : les entreprises établies ont du mal à adopter l'innovation disruptive, non par manque de ressources, mais parce que leurs modèles commerciaux existants, les attentes de leurs clients et leurs structures organisationnelles empêchent de le faire.

Ces entreprises ont construit leurs produits autour de mémoires de traduction, de tarification au mot et de flux de travail de traducteurs humains. Leurs clients ont construit des modèles mentaux et des processus autour de ces éléments de base. Changer les fondations signifie rompre des promesses envers les clients existants, reformatrer des équipes et repenser les modèles de revenus. Même avec les meilleures intentions et le capital à investir, l'inertie organisationnelle est énorme.

Elles ont besoin de capacité d'innovation et d'engagement de leur main-d'œuvre pour embrasser de nouvelles idées. Mais encore plus difficile, elles ont besoin que leurs clients existants venent pour balot. Et ces clients sont investis dans le modèle ancien.

C'est l'ouverture que nous voyons. Non malgré avoir moins de ressources, mais à cause de celle-ci. Nous n'avons pas d'héritage à protéger, pas de flux de travail à préserver, pas de clients à migrer. Nous pouvons tout concevoir de zéro.

> \[\!NOTE\]
> Le dilemme de l'innovateur ne concerne pas la technologie. Il concerne les incitations. Les entreprises établies optimisent pour ce que leurs clients actuels veulent, ce qui rend presque impossible la poursuite de quelque chose de fondamentalement différent.

## L'IA au centre, pas aux bords

La plupart des entreprises adoptent l'IA en la greffant sur des processus existants. Un chatbot ici, un moteur de suggestions là. Nous allons dans la direction opposée : concevoir toute l'entreprise pour qu'elle soit centrée sur l'IA dès le premier jour.

Cela signifie que l'IA n'est pas une fonctionnalité du produit. Elle façonne la manière dont nous concevons, vendons, supportons et gérons. Chaque décision que nous prenons commence par une question : un agent peut-il le faire ?

Le produit lui-même est un agent qui réside dans votre terminal, lit vos fichiers sources, génère des traductions, exécute vos contrôles CI et itère jusqu'à ce que la sortie passe. C'est ce que les gens voient. Mais derrière, la même philosophie dirige l'entreprise.

## Deux personnes, zéro surcharge organisationnelle

Nous maintenons volontairement l'équipe aussi petite que possible. Pour l'instant, il n'y a que nous deux. Notre objectif est de rester à deux ou trois personnes le plus longtemps possible.

Cela ne concerne pas l'économie d'argent (bien que cela aide). C'est éliminer toute une catégorie de travaux qui ne produit pas de valeur pour les utilisateurs.

Plus vous ajoutez de humains, plus vous avez besoin de coordination. Vous construisez des systèmes de confiance, des modèles de permissions, des chaînes d'approbation. Vous gérez les conflits, alignez les priorités, planifiez des réunions. Tout cela est de l'énergie créative consacrée au maintien d'une organisation humaine plutôt qu'à la construction d'un produit.

Avec deux personnes, nous sautons tout cela. Nous nous faisons totalement confiance. Nous avons accès à tout. Il n'y a pas de surcharge, pas de politique, pas de processus pour la forme du processus.

La façon dont nous faisons tenir cela à l'échelle est en déléguant tout le reste aux agents.

## Discord, un agent IA et une seule ligne de commande

Voici quelque chose qui peut sembler inhabituel : notre interface principale d'entreprise est un serveur [Discord](https://discord.com).

Nous avons un agent IA connecté à cela, alimenté par [OpenAI](https://openai.com), avec accès à tous les outils dont nous avons besoin pour faire fonctionner l'entreprise. Au lieu de basculer entre les tableaux de bord web, les plateformes d'analyse et les panneaux d'administration, nous parlons à l'agent. Le texte et la voix sont l'unité d'interaction.

Grâce à l'agent, l'un de nous peut :

- Interroger les analyses marketing et produits
- Inspecter les serveurs de production
- Mener des études de marché
- Recueillir les retours clients
- Effectuer des analyses concurrentielles via la navigation web
- Rédiger du contenu, relire et publier

Aucun de nous deux ne dépend de l'autre pour faire cela. L'agent a accès à nos APIs, bases de données et outils de surveillance. Il peut naviguer sur le web, lire la documentation et synthétiser les informations. C'est un serveur Discord, une instance OpenAI et une clé LLM. C'est le système d'exploitation de l'entreprise.

> \[\!TIP\]
> Si vous construisez une petite équipe et que vous souhaitez réduire les frais de coordination, envisagez de faire du texte et de la voix votre interface principale pour les opérations commerciales. Un agent partagé dans un canal de chat peut remplacer des dizaines de tableaux de bord et éliminer le besoin du plus grand outillage interne.

## Choix technologiques réflexion

Nous sommes très intentionnels quant à notre pile technique car cela affecte directement la vitesse à laquelle nous pouvons avancer et le coût de nos opérations.

**Pour l'agent (CLI) :** Nous avons choisi Go. Il se compile en binaires uniques et portables sur toutes les plateformes sans dépendances d'exécution pour l'utilisateur.

**Pour le serveur :** Nous avons choisi [Elixir](https://elixir-lang.org) et le runtime [Erlang](https://www.erlang.org). La nature fonctionnelle d'Elixir en fait un excellent choix pour les charges de travail agentiques. La VM Erlang est éprouvée pour la concurrence et la tolérance aux pannes. Et voici un bonus : un agent IA peut s'inspecter le système Erlang en cours d'exécution pour comprendre ce qui se passe, recueillir des informations et même corriger les problèmes en production.

**Pour l'infrastructure :** Tout tourne sur un VPS unique. Pas seulement le serveur de production Glossia, mais tous les services périphériques aussi : [PostgreSQL](https://www.postgresql.org/) pour la base de données, [Plausible](https://plausible.io) pour les analyses respectueuses de la vie privée, [Grafana](https://grafana.com) pour la télémétrie et l'observabilité. Tout est déployé à partir de définitions d'infrastructure gérées par version qui décrivent ce qui va où.

Cela maintient les coûts extrêmement bas. Nous ne dépendons pas de services cloud tiers, de bases de données gérées ou de fournisseurs de plateformes en tant que service. Nous avons quelques dépendances externes, mais uniquement pour les choses qui prendraient du temps à reproduire et où les coûts sont justifiés.

Lorsqu'il sera temps de mettre à l'échelle sur plusieurs serveurs, nous ferons évoluer le modèle. Mais nous croyons que nous pouvons aller très loin avec cette configuration. Et aller vite compte plus que créer grand pour l'instant.

> \[\!IMPORTANT\]
> Nous sommes très intentionnels à éviter la complexité technique que les ingénieurs ont tendance à adopter dès le début. Kubernetes, microservices, déploiements multi-régions. Tout cela n'est pas nécessaire à cette étape et ralentirait notre progression.

## Ce que cela libère

Gérer l'entreprise ainsi n'est pas seulement une question d'efficacité. Cela change ce que nous pouvons offrir et la vitesse à laquelle nous pouvons apprendre.

**Moins cher pour les utilisateurs.** L'industrie de la localisation a rendu ses outils inaccessibles via une tarification complexe, des frais au mot et des cycles de vente d'entreprise. Si votre flux de travail de localisation nécessite l'approvisionnement, des négociations de tarification et un chef de projet, la plupart des petites équipes déploieront en anglais. En maintenant nos coûts d'exploitation près de zéro, nous pouvons ofrecer quelque chose de vraiment accessible.

**Une innovation plus rapide.** Nous voulons explorer beaucoup d'idées. Nouvelléristiques pour l'agent, de meilleurs cycles de rétroaction, de nouvelles façons d'intégrer les traducteurs dans le flux de travail. Une entreprise traditionnelle aurait besoin de personneliser les équipes et planifier des revues de roadmap. Nous essayons simplement. La distance entre une idée et une expérience déployée est mesurée en heures, pas en trimestres.

## Remettre en question notre façon de travailler, pas seulement ce que nous construisons

Nous ne sommes pas attachés émotionnellement aux anciennes façons de faire. Nous interrogeons activement le sens de la revue de code lorsqu'un agent rédige la majeure partie du code. Comment fonctionne la collaboration avec seulement deux humains. Comment corriger un bug si l'agent peut inspecter le système en cours d'exécution.

Nous faisons des erreurs. Nous les continuerons de faire. Mais en restant ouverts d'esprit sur la façon dont nous concevons et pilotons l'entreprise, nous continuons de découvrir des idées qui influencent le produit. La manière dont nous fonctionnons n'est pas séparée de ce que nous construisons. C'est la même chose.

[McKinsey a récemment décrit](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) ce qu'ils appellent « l'organisation agentique », un nouveau modèle opérationnel où les agents d'IA deviennent des participants de premier plan dans la manière dont une entreprise fonctionne. Nous ne le concevons pas comme un modèle. C'est tout simplement la façon dont nous travaillons.

## Le pari

Nous parions qu'une équipe de deux personnes, dotée des bons outils, de la bonne mentalité et sans bagages organisationnels, peut surpasser les entreprises ayant des centaines d'employés et des millions en financements. Pas sur tous les fronts, mais sur celui qui compte : proposer une expérience de localisation fondamentalement meilleure.

L'industrie ne peut pas se réinventer. Nous le pouvons.