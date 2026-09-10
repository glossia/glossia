%{
  title:
    "Construire une entreprise centrée sur l'IA pour défier un secteur incapable de se réinventer.",
  summary:
    "Les entreprises de localisation établies disposent du capital, mais pas de la liberté d'innover. Nous concevons Glossia de toutes pièces autour de l'IA et des agents, non seulement dans le produit, mais aussi dans la façon dont nous gérons l'ensemble de l'entreprise.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
Les LLM et les agents transforment tout. Pas seulement ce que le logiciel peut faire, mais comment les entreprises sont construites pour créer ce logiciel. À [Glossia](https://glossia.ai), nous voyons cela comme une opportunité d'une génération pour repenser la façon dont le contenu atteint chaque langue. Mais nous savons également qu'une bonne idée de produit ne suffit pas. Il vous faut une organisation capable d'avancer assez vite pour compter.

C'est cette deuxième partie dont parle cet article.

## Le dilemme de l'innovateur, qui se joue en temps réel

L'industrie de la localisation est vaste et bien financée. Des entreprises comme Smartling, Phrase, Crowdin et Lokalise construisent des outils et des services depuis des années. Elles ont des clients, des revenus, des flux de travail établis et des équipes qui savent vendre et assurer le support de leurs produits.

Alors pourquoi une petite équipe focalisée essaierait-elle même ?

Parce qu'il s'agit de quelque chose que Clayton Christensen a décrit dans [Le Dilemme de l'innovateur](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): les entreprises établies peinent à adopter l'innovation disruptive, non pas parce qu'elles manquent de ressources, mais parce que leurs modèles commerciaux existants, les attentes des clients et leurs structures organisationnelles empêchent de le faire.

Ces entreprises ont construit leurs produits autour de mémoires de traduction, de la tarification au mot, et autour des flux de travail des traducteurs humains. Leurs clients ont eux aussi construit des modèles mentaux et des processus autour de ces briques élémentaires. Changer le fondement signifie enfreindre les promesses faites aux clients existants, requalifier les équipes et repenser les modèles de revenus. Même avec les meilleures intentions et le capital à investir, l'inertie organisationnelle est énorme.

Elles ont besoin d'une capacité d'innovation et d'un engagement de la part de leur effectif pour embrasser les nouvelles idées. Mais c'est encore plus difficile, elles ont besoin que leurs clients existants s'engagent à cette transition. Et ces clients sont investis dans l'ancien modèle.

C'est l'opportunité que nous voyons. Non, pas malgré le fait d'avoir moins de ressources, mais à cause de celles-ci. Nous n'avons aucun héritage à protéger, aucun flux à préserver, aucun client à migrer. Nous pouvons concevoir tout de zéro.

> \[\!NOTE\]
> Le dilemme de l'innovateur ne concerne pas la technologie. Il s'agit d'incitations. Les entreprises établies optimisent pour ce que leurs clients actuels veulent, ce qui rend pratiquement impossible de poursuivre quelque chose de fondamentalement différent.

## IA au centre, pas à la périphérie

La plupart des entreprises adoptent l'IA en la greffant sur des processus existants. Un chatbot ici, un moteur de suggestions là-bas. Nous allons dans l'autre sens : concevoir l'entreprise entière pour être centrée sur l'IA dès le premier jour.

Cela signifie que l'IA n'est pas une fonctionnalité du produit. Elle façonne la façon dont nous construisons, vendons, supportons et opérons. Chaque décision que nous prenons commence par une question : un agent peut-il le faire ?

Le produit lui-même est un agent qui réside dans votre terminal, lit vos fichiers sources, génère des traductions, exécute vos vérifications CI, et itère jusqu'à ce que la sortie passe. C'est la partie que les gens voient. Mais derrière, la même philosophie anime l'entreprise.

## Une petite équipe, déléguant tout le reste aux agents

Nous conservons volontairement l'équipe petite et restons ainsi tant que cela a du sens.

Il ne s'agit pas d'économiser de l'argent. Il s'agit d'éliminer une catégorie entière d'activités qui ne produisent pas de valeur pour les utilisateurs.

Plus vous ajoutez de personnes, plus vous avez besoin de coordination. Vous bâtissez des systèmes de confiance, des modèles de permissions, des chaînes d'approbation. Vous gérez les conflits, alignez les priorités, planifiez des réunions. Tout cela est une énergie créative consacrée au maintien d'une organisation humaine plutôt qu'à la construction d'un produit.

Notre façon de faire fonctionner cela consiste à déléguer tout le reste aux agents. Analyse marketing, synthèse des retours clients, recherche concurrentielle, rédaction de contenu, surveillance opérationnelle : le travail quotidien de faire tourner l'entreprise est de plus en plus réalisé par des agents que nous façonnons, évaluons et améliorons.

## Choix technologiques réfléchis

Nous sommes très intentionnels concernant notre stack car elle affecte directement la rapidité avec laquelle nous pouvons avancer et le comportement du logiciel pour les équipes qui l'auto-hébergent.

**Pour l'agent (CLI):** Nous avons choisi Rust. Il compile en un binaire unique, portable sur toutes les plateformes, sans dépendances d'exécution pour l'utilisateur.

**Pour le serveur:** Nous avons choisi [Elixir](https://elixir-lang.org) et le [Erlang](https://www.erlang.org) runtime. La nature fonctionnelle d'Elixir en fait un excellent choix pour les charges de travail agentic. La VM Erlang est éprouvée pour la concurrence et la tolérance aux pannes. Et voici un bonus : un agent IA peut introspecter le système Erlang en cours d'exécution pour comprendre ce qui se passe, recueillir des insights et même corriger des problèmes en production.

**Pour la distribution :** Glossia est open source sous la [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Les équipes qui souhaitent l'exploiter elles-mêmes peuvent installer la carte Helm dans le dépôt sur n'importe quel cluster Kubernetes. Le même code propulse le service hébergé sur glossia.ai et tout déploiement auto-hébergé.

> \[\!IMPORTANT\]
> Nous évitons intentionnellement la complexité technique que les ingénieurs ont tendance à adopter dès le début quand elle n'est pas justifiée. Chaque dépendance et chaque couche d'infrastructure doit justifier son poids.

## Ce que cela débloque

Gérer l'entreprise de cette manière n'est pas seulement une question d'efficacité. Cela change ce que nous pouvons offrir et la vitesse à laquelle nous pouvons apprendre.

**Accessible à plus d'équipes.** L'industrie de la localisation a rendu ses outils inaccessibles via des tarifs complexes, des frais au mot et des cycles de vente d'entreprise. Si votre flux de traduction nécessite des démarches d'achat, des négociations tarifaires et un chef de projet, la plupart des petites équipes ne lanceront que leur produit en anglais. En construisant une organisation efficace et en diffusant le logiciel en open source pour que les équipes puissent l'héberger elles-mêmes, nous pouvons rendre Glossia véritablement accessible.

**Une innovation plus rapide.** Nous voulons explorer beaucoup d'idées. De nouvelles interfaces pour l'agent, de meilleurs boucles de rétroaction, de nouveaux moyens d'intégrer les linguistes dans le flux de travail. Une entreprise traditionnelle devrait recruter, aligner les équipes et planifier des revues de feuille de route. Nous testons simplement. L'écart entre une idée et une expérience déployée se mesure en heures, pas en trimestres.

## Remettre en cause la façon dont nous travaillons, pas seulement ce que nous construisons

Nous ne sommes pas émotionnellement attachés aux anciennes façons de faire les choses. Nous remettons activement en question ce que signifie la revue de code lorsque l'agent rédige la plupart du code. Comment fonctionne la collaboration lorsque l'équipe humaine est petite et les agents effectuent le travail de routine. Comment corriger un bug lorsque l'agent peut inspecter le système en cours d'exécution.

Nous commettons des erreurs. Nous continuerons à en commettre. Mais en restant ouverts d'esprit sur la façon dont nous concevons et gérons l'entreprise, nous continuons à découvrir des idées qui influencent le produit. La façon dont nous opérons n'est pas séparée de ce que nous construisons. Ce sont la même chose.

[McKinsey a récemment décrit](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) ce qu'ils appellent « l'organisation agentique », un nouveau modèle opérationnel où les agents d'IA deviennent des participants à part entière dans la façon dont une entreprise fonctionne. Nous ne le considérons pas comme un modèle. C'est simplement la façon dont nous travaillons.

## Le pari

Nous parions qu'une petite équipe avec les bons outils, la bonne mentalité et sans lourdeurs organisationnelles peut devancer des entreprises avec des centaines d'employés et des millions en financements. Pas à tous les fronts, mais sur celui qui compte : offrir une expérience de localisation fondamentalement meilleure.

L'industrie ne peut pas se réinventer. Nous le pouvons.