%{
  title: "Construire une entreprise centrée sur l’IA pour défier un secteur qui ne sait pas se réinventer",
  summary: "Les entreprises de localisation établies disposent des capitaux, mais pas de la liberté nécessaire pour innover. Nous concevons Glossia de zéro autour de l’IA et des agents, non seulement dans le produit, mais aussi dans la manière dont nous gérons l’ensemble de l’entreprise.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
Les grands modèles de langage et les agents transforment tout. Ils ne changent pas seulement ce que les logiciels peuvent faire, mais aussi la manière dont les entreprises sont structurées pour les créer. Chez [Glossia](https://glossia.ai), nous y voyons une occasion unique de repenser la manière dont les contenus sont diffusés dans toutes les langues. Mais nous savons également qu’une bonne idée de produit ne suffit pas. Il faut une organisation capable d’avancer assez vite pour avoir un réel impact.

C’est ce deuxième aspect que nous abordons dans cet article.

## Le dilemme de l’innovateur à l’œuvre en temps réel

Le secteur de la localisation est vaste et bénéficie de financements importants. Des entreprises comme Smartling, Phrase, Crowdin et Lokalise développent des outils et des services depuis des années. Elles disposent de clients, de revenus, de processus établis et d’équipes qui savent vendre leurs produits et en assurer l’assistance.

Alors pourquoi une équipe de deux personnes essaierait-elle malgré tout ?

En raison d’un phénomène décrit par Clayton Christensen dans [The Innovator's Dilemma](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma) : les entreprises établies peinent à adopter les innovations de rupture, non par manque de ressources, mais parce que leurs modèles économiques, les attentes de leurs clients et leurs structures organisationnelles les en empêchent.

Ces entreprises ont conçu leurs produits autour des mémoires de traduction, de la tarification au mot et des processus de travail des traducteurs humains. Leurs clients ont construit leurs modèles mentaux et leurs processus autour de ces éléments fondamentaux. Changer de fondation implique de remettre en cause les engagements pris auprès des clients existants, de former à nouveau les équipes et de repenser les modèles de revenus. Même avec les meilleures intentions et les capitaux nécessaires pour investir, l’inertie organisationnelle est considérable.

Elles ont besoin d’une capacité d’innovation et de l’engagement de leurs équipes pour adopter de nouvelles idées. Mais plus difficile encore, elles doivent convaincre leurs clients existants de les suivre. Or, ces clients ont investi dans l’ancien modèle.

C’est l’ouverture que nous identifions. Non pas malgré nos ressources plus limitées, mais grâce à elles. Nous n’avons aucun héritage à protéger, aucun processus à préserver, aucun client à faire migrer. Nous pouvons tout concevoir à partir de zéro.

> [!NOTE]
> Le dilemme de l’innovateur ne porte pas sur la technologie. Il porte sur les incitations. Les entreprises établies optimisent leurs activités en fonction des attentes de leurs clients actuels, ce qui rend presque impossible l’adoption d’une approche fondamentalement différente.

## L’intelligence artificielle au cœur de l’entreprise, pas à sa périphérie

La plupart des entreprises adoptent l’intelligence artificielle en la greffant sur leurs processus existants. Un agent conversationnel ici, un moteur de suggestions là. Nous suivons l’approche inverse : concevoir dès le premier jour l’ensemble de l’entreprise autour de l’intelligence artificielle.

Cela signifie que l’intelligence artificielle n’est pas une fonctionnalité du produit. Elle détermine notre manière de développer, de vendre, d’assurer l’assistance et de gérer nos activités. Chaque décision commence par une question : un agent peut-il s’en charger ?

Le produit lui-même est un agent qui s’exécute dans votre terminal, lit vos fichiers sources, génère des traductions, exécute les contrôles de votre intégration continue et itère jusqu’à ce que le résultat les réussisse. C’est la partie visible. Mais en coulisses, la même philosophie guide l’entreprise.

## Deux personnes, aucune surcharge organisationnelle

Nous avons délibérément choisi de maintenir une équipe aussi réduite que possible. Pour l’instant, nous ne sommes que deux. Notre objectif est de rester deux ou trois personnes aussi longtemps que possible.

Il ne s’agit pas d’économiser de l’argent, même si cela y contribue. Il s’agit d’éliminer toute une catégorie de tâches qui ne créent aucune valeur pour les utilisateurs.

Plus vous ajoutez de personnes, plus la coordination devient nécessaire. Vous mettez en place des systèmes de confiance, des modèles d’autorisation et des chaînes d’approbation. Vous gérez les conflits, harmonisez les priorités et planifiez des réunions. Toute cette énergie créative sert alors à maintenir une organisation humaine plutôt qu’à développer un produit.

À deux, nous évitons tout cela. Nous nous faisons entièrement confiance. Nous avons accès à tout. Il n’y a ni surcharge, ni politique interne, ni processus instauré pour sa propre existence.

Pour rendre ce modèle viable à grande échelle, nous déléguons tout le reste à des agents.

## Discord, un agent d’intelligence artificielle et une seule ligne de commande

Voici quelque chose qui peut sembler inhabituel : notre principale interface métier est un serveur [Discord](https://discord.com).

Nous y avons connecté un agent d’intelligence artificielle, propulsé par [OpenAI](https://openai.com), qui dispose de tous les outils nécessaires pour gérer l’entreprise. Au lieu de passer d’un tableau de bord web à une plateforme d’analyse ou à une interface d’administration, nous dialoguons avec l’agent. Le texte et la voix sont nos modes d’interaction.

Grâce à l’agent, chacun de nous peut :

- Interroger les données d’analyse marketing et produit
- Inspecter les serveurs de production
- Réaliser des études de marché
- Recueillir les retours des clients
- Effectuer une analyse concurrentielle en parcourant le web
- Rédiger du contenu, réviser des textes et les publier

Aucun de nous ne dépend de l’autre pour effectuer ces tâches. L’agent a accès à nos interfaces de programmation, à nos bases de données et à nos outils de surveillance. Il peut parcourir le web, lire la documentation et synthétiser des informations. Il repose sur un serveur Discord, une instance OpenAI et une clé de grand modèle de langage. Voilà le système d’exploitation de l’entreprise.

> [!TIP]
> Si vous constituez une petite équipe et souhaitez réduire les coûts de coordination, envisagez de faire du texte et de la voix vos principales interfaces pour les opérations de l’entreprise. Un agent partagé dans un canal de discussion peut remplacer des dizaines de tableaux de bord et éliminer la plupart des outils internes.

## Des choix technologiques délibérés

Nous choisissons notre socle technologique avec beaucoup de discernement, car il détermine directement notre vitesse d’exécution et nos coûts d’exploitation.

**Pour l’agent (interface de ligne de commande) :** nous avons choisi Go. Il permet de compiler des exécutables uniques et portables sur différentes plateformes, sans dépendance d’exécution pour l’utilisateur.

**Pour le serveur :** nous avons choisi [Elixir](https://elixir-lang.org) et l’environnement d’exécution [Erlang](https://www.erlang.org). La nature fonctionnelle d’Elixir convient parfaitement aux charges de travail fondées sur des agents. La machine virtuelle Erlang a largement fait ses preuves en matière de concurrence d’exécution et de tolérance aux pannes. Autre avantage : un agent d’intelligence artificielle peut examiner le système Erlang en cours d’exécution pour comprendre ce qui se passe, en tirer des enseignements et même résoudre des problèmes en production.

**Pour l’infrastructure :** tout fonctionne sur un seul serveur privé virtuel. Cela comprend non seulement le serveur de production de Glossia, mais aussi tous les services périphériques : [PostgreSQL](https://www.postgresql.org/) pour la base de données, [Plausible](https://plausible.io) pour une analyse respectueuse de la vie privée et [Grafana](https://grafana.com) pour la télémétrie et l’observabilité. L’ensemble est déployé à partir de définitions d’infrastructure placées sous gestion de versions, qui décrivent l’emplacement de chaque élément.

Cette approche maintient les coûts à un niveau extrêmement bas. Nous ne dépendons pas de services infonuagiques tiers, de bases de données gérées ni de fournisseurs de plateformes en tant que service. Nous conservons quelques dépendances externes, mais uniquement pour des éléments dont la reproduction nous demanderait beaucoup de temps et lorsque leur coût est justifié.

Lorsque le moment sera venu de répartir la charge entre plusieurs serveurs, nous ferons évoluer ce modèle. Nous pensons toutefois pouvoir aller très loin avec cette configuration. À ce stade, avancer vite importe davantage que voir grand.

> [!IMPORTANT]
> Nous évitons délibérément la complexité technique que les ingénieurs ont tendance à adopter trop tôt : Kubernetes, les microservices et les déploiements multirégion. Rien de cela n’est nécessaire à ce stade, et tout cela nous ralentirait.

## Ce que cette approche rend possible

Gérer l’entreprise de cette façon ne constitue pas seulement un gain d’efficacité. Cela transforme ce que nous pouvons proposer et la vitesse à laquelle nous pouvons apprendre.

**Plus abordable pour les utilisateurs.** Le secteur de la localisation a rendu ses outils inaccessibles en raison de modèles tarifaires complexes, d’une facturation au mot et de cycles de vente destinés aux grandes entreprises. Si votre flux de traduction exige un processus d’approvisionnement, des négociations tarifaires et un chef de projet, la plupart des petites équipes se contenteront de publier en anglais. En maintenant nos coûts d’exploitation proches de zéro, nous pouvons proposer une solution véritablement accessible.

**Une innovation plus rapide.** Nous voulons explorer de nombreuses idées : de nouvelles interfaces pour l’agent, de meilleures boucles de rétroaction et de nouvelles façons d’intégrer les linguistes au flux de travail. Une entreprise traditionnelle devrait recruter, coordonner ses équipes et planifier des revues de sa feuille de route. Nous, nous expérimentons. Le délai entre une idée et son déploiement à titre expérimental se mesure en heures, pas en trimestres.

## Remettre en question notre façon de travailler, pas seulement ce que nous créons

Nous ne sommes pas attachés aux anciennes méthodes de travail. Nous nous interrogeons activement sur la signification de la revue de code lorsqu’un agent écrit l’essentiel du code. Sur le fonctionnement de la collaboration lorsqu’il n’y a que deux personnes. Sur la manière de corriger un bogue lorsque l’agent peut inspecter le système en cours d’exécution.

Nous commettons des erreurs. Nous continuerons à en commettre. Mais en restant ouverts quant à la façon dont nous concevons et gérons l’entreprise, nous continuons à découvrir des idées qui influencent le produit. Notre mode de fonctionnement n’est pas distinct de ce que nous créons. Ils ne font qu’un.

[McKinsey a récemment décrit](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) ce qu’ils appellent « l’organisation agentique », un nouveau modèle opérationnel dans lequel les agents d’intelligence artificielle deviennent des participants à part entière au fonctionnement d’une entreprise. Nous ne considérons pas cela comme un modèle. C’est simplement notre façon de travailler.

## Notre pari

Nous faisons le pari qu’une équipe de deux personnes disposant des bons outils, du bon état d’esprit et d’aucune lourdeur organisationnelle peut avancer plus vite que des entreprises comptant des centaines de salariés et bénéficiant de millions de financement. Pas sur tous les fronts, mais sur celui qui compte : offrir une expérience de localisation fondamentalement meilleure.

Le secteur ne peut pas se réinventer. Nous le pouvons.