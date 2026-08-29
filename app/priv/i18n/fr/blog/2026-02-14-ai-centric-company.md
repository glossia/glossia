%{
  title: "Construire une entreprise axée sur l'IA pour défier un secteur qui ne peut pas se réinventer",
  summary: "Les entreprises de localisation établies disposent de capitaux, mais pas de la liberté d'innover. Nous concevons Glossia de zéro autour de l'IA et des agents, non seulement dans le produit, mais dans la façon dont nous gérons l'entreprise dans son ensemble.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
Les LLM et les agents transforment tout. Pas seulement ce que le logiciel peut faire, mais comment les entreprises sont construites pour créer ce logiciel. Chez [Glossia](https://glossia.ai), c'est une opportunité d'une génération pour repenser la façon dont le contenu atteint chaque langue. Mais nous savons également qu'une bonne idée de produit ne suffit pas. Vous avez besoin d'une organisation capable d'agir assez vite pour compter.

C'est de cette deuxième partie dont il est question dans ce billet.

## Le dilemme de l'innovateur, se jouant en temps réel

L'industrie de la localisation est vaste et bien financée. Des entreprises comme Smartling, Phrase, Crowdin et Lokalise construisent des outils et des services depuis des années. Elles disposent de clients, de revenus, des flux de travail établis et d'équipes qui savent vendre et supporter leurs produits.

Alors pourquoi une équipe de deux personnes essaierait-elle même ?

À cause de quelque chose que Clayton Christensen a décrit dans [The Innovator's Dilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma) : les entreprises établies peinent à adopter l'innovation disruptive, non pas parce qu'elles manquent de ressources, mais parce que leurs modèles d'affaires existants, les attentes des clients et leurs structures organisationnelles les empêchent d'y parvenir.

Ces entreprises ont construit leurs produits autour des mémoires de traduction, de la tarification au mot et des flux de travail des traducteurs humains. Leurs clients ont construit des modèles mentaux et des processus autour de ces briques de base. Changer les fondations signifie rompre les promesses envers les clients existants, reconstruire les équipes et repenser les modèles de revenus. Même avec les meilleures intentions et le capital pour investir, l'inertie organisationnelle est énorme.

Ils ont besoin d'une capacité d'innovation et d'un engagement de la main-d'œuvre pour accueillir de nouvelles idées. Mais encore plus exigeant, ils doivent réussir à amener leurs clients existants dans la danse. Et ces clients sont investis dans le vieux modèle.

C'est l'ouverture que nous voyons. Non pas malgré des ressources limitées, mais à cause de cela. Nous n'avons aucun héritage à protéger, aucun flux de travail à préserver, aucun client à migrer. Nous pouvons tout concevoir à partir de zéro.

> \[\!NOTE\]
> Le dilemme de l'innovateur ne concerne pas la technologie. Il s'agit d'incitations. Les entreprises établies optimisent pour ce que leurs clients actuels veulent, ce qui rend quasi impossible de poursuivre quelque chose d'radicalement différent.

## L'IA au centre, pas aux bords

La plupart des entreprises adoptent l'IA en la greffant sur leurs processus existants. Un chatbot ici, un moteur de suggestions là. Nous allons dans la direction opposée : concevoir toute l'entreprise pour être centrée sur l'IA dès le premier jour.

Cela signifie que l'IA n'est pas une fonctionnalité du produit. Elle façonne la façon dont nous construisons, vendons, supportons et gérons. Chaque décision que nous prenons commence avec une question : un agent peut-il le faire ?

Le produit lui-même est un agent qui réside dans votre terminal, lit vos fichiers sources, génère des traductions, exécute vos vérifications CI et itère jusqu'à ce que le résultat passe. C'est la partie que les gens voient. Mais derrière, la même philosophie dirige l'entreprise.

## Deux personnes, zéro surcoût organisationnel

Nous gardons volontairement l'équipe au plus petit. Pour l'instant, c'est juste nous deux. Notre objectif est de rester à deux ou trois personnes aussi longtemps que possible.

Cela ne sert pas à économiser de l'argent (bien que cela aide). Il s'agit d'éliminer une catégorie complète de travail qui ne produit pas de valeur pour les utilisateurs.

Plus vous ajoutez de personnes humaines, plus vous avez besoin de coordination. Vous construisez des systèmes de confiance, des modèles d'autorisation, des chaînes de validation. Vous gérez les conflits, alignez les priorités, planifiez des réunions. Tout cela est une énergie créative qui sert à maintenir une organisation humaine plutôt qu'à construire un produit.

Avec deux personnes, nous sautons tout cela. Nous nous faisons pleinement confiance. Nous avons accès à tout. Il n'y a pas de surcoût, pas de politique, pas de processus pour un processus.

La manière dont nous rendons cela fonctionnel à grande échelle est en déléguant tout le reste aux agents.

## Discord, un agent d'IA, et une seule ligne de commande

Voici quelque chose qui peut sembler inhabituel : notre interface principale d'affaires est un serveur [Discord](https://discord.com).

Nous avons un agent IA connecté à celui-ci, alimenté par [OpenAI](https://openai.com), avec accès à tous les outils dont nous avons besoin pour faire fonctionner l'entreprise. Au lieu de basculer entre des tableaux de bord web, des plateformes analytiques et des panneaux d'administration, nous parlons à l'agent. Le texte et la voix sont l'unité d'interaction.

À travers l'agent, l'un ou l'autre de nous peut :

- Interroger les analytics marketing et produit
- Examiner les serveurs de production
- Lancer des recherches de marché
- Recevoir les retours clients
- Réaliser une analyse concurrentielle via la navigation web
- Rédiger du contenu, relire les textes et publier

Ni l'un ni l'autre ne dépend de l'autre pour effectuer cela. L'agent a accès à nos API, bases de données et outils de surveillance. Il peut naviguer sur le web, lire la documentation et synthétiser les informations. C'est un serveur Discord, une instance OpenAI et une clé LLM. C'est le système d'exploitation de l'entreprise.

> \[\!TIP\]
> Si vous construisez une petite équipe et souhaitez réduire la surcharge de coordination, envisagez de faire du texte et de la voix votre interface principale pour les opérations de l'entreprise. Un agent partagé dans un canal de chat peut remplacer des dizaines de tableaux de bord et éliminer le besoin de la plupart des outils internes.

## Choix technologiques délibérés

Nous sommes très intentionnels quant à notre pile technique car elle affecte directement la vélocité à laquelle nous pouvons avancer et le coût de nos opérations.

**Pour l'agent (CLI)**, nous avons choisi Go. Il se compile en binaires uniques et portables sur les plateformes, sans dépendances temps d'exécution pour l'utilisateur.

**Pour le serveur**, nous avons choisi [Elixir](https://elixir-lang.org) et l'environnement d'exécution [Erlang](https://www.erlang.org). La nature fonctionnelle d'Elixir en fait un excellent choix pour les charges de travail agentic. La machine virtuelle Erlang est éprouvée pour la concurrence et la tolérance aux pannes. Et voici un bonus : un agent IA peut pratiquer l'introspection du système Erlang en marche pour comprendre ce qui se passe, recueillir des informations et même résoudre des problèmes en production.

**Pour l'infrastructure**, tout s'exécute sur un seul VPS. Non seulement le serveur de production Glossia, mais aussi tous les services périphériques : [PostgreSQL](https://www.postgresql.org/) pour la base de données, [Plausible](https://plausible.io) pour les analyses respectant la vie privée, [Grafana](https://grafana.com) pour la télémétrie et l'observabilité. Tout est déployé depuis des définitions d'infrastructure versionnées qui décrivent où placer quoi.

Cela maintient les coûts extrêmement bas. Nous ne dépendons pas de services cloud tiers, de bases de données gérées ou de fournisseurs de plateforme en tant que service. Nous avons quelques dépendances externes, mais uniquement pour des choses qui nous prendraient beaucoup de temps à reproduire et où le coût est justifié.

Lorsque le moment viendra d'échelonner sur plusieurs serveurs, nous évoluerons le modèle. Mais nous croyons que nous pouvons aller très loin avec cette configuration. Et aller vite compte plus grand que grandir pour l'instant.

> \[\!IMPORTANT\]
> Nous sommes très délibérés à éviter la complexité technique que les ingénieurs ont tendance à adopter précocement. Kubernetes, les microservices, les déploiements multi-régions. Rien de tout cela n'est nécessaire à ce stade, et tout cela nous ralentirait.

## Ce que cela débloque

Conduire l'entreprise de cette manière n'est pas seulement une question d'efficacité. Elle transforme ce que nous pouvons offrir et à quelle vitesse nous pouvons apprendre.

**Plus abordable pour les utilisateurs.** L'industrie de la localisation a rendu ses outils inaccessibles grâce à des prix complexes, des tarifs au mot et des cycles de vente d'entreprise. Si votre flux de travail de traduction nécessite l'achat, des négociations de prix et un chef de projet, la plupart des petites équipes finiront par publier en anglais. En maintenant nos coûts d'exploitation près de zéro, nous pouvons offrir quelque chose qui est véritablement accessible.

**Innovation plus rapide.** Nous voulons explorer beaucoup d'idées. De nouvelles interfaces pour l'agent, de meilleurs circuits de feedback, de nouvelles façons d'intégrer les linguistes dans le flux de travail. Une entreprise traditionnelle devrait recruter, aligner les équipes et planifier des revues de roadmap. Nous essayons simplement les choses. La distance entre une idée et une expérience déployée est mesurée en heures, pas en trimestres.

## Remettre en question comment nous travaillons, pas seulement ce que nous construisons

Nous ne sommes pas émotionnellement attachés aux anciennes façons de faire. Nous questionnons activement la signification des revues de code lorsqu'un agent en écrit la majeure partie. Comment fonctionne la collaboration lorsqu'il n'y a que deux humains. Comment résoudre un bug lorsque l'agent peut inspecter le système en exécution.

Nous commettons des erreurs. Nous continuerons à le faire. Mais en restant ouverts à la façon dont nous concevons et gérons l'entreprise, nous découvrons continuellement des idées qui influencent le produit. La façon dont nous opérons n'est pas séparée de ce que nous construisons. Ce sont la même chose.

[McKinsey a récemment décrit](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) ce qu'ils appellent "l'organisation agentic", un nouveau modèle de fonctionnement où les agents IA deviennent des acteurs à part entière dans la gestion d'une entreprise. Nous ne le considérons pas comme un modèle. C'est simplement la façon dont nous travaillons.

## Le pari

Nous parions qu'une équipe de deux personnes dotée des bons outils, de la bonne mentalité et sans bagage organisationnel peut surpasser des entreprises dotées de centaines d'employés et des millions en financement. Pas sur tous les fronts, mais sur celui qui compte : offrir une expérience de localisation fondamentalement meilleure.

L'industrie ne peut pas se réinventer. Nous pouvons.