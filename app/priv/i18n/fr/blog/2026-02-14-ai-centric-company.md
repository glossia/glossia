%{
  title:
    "Construire une entreprise centrée sur l'IA pour défier une industrie incapable de se réinventer elle-même.",
  summary:
    "Les entreprises de localisation établies ont le capital, mais pas la liberté d'innover. Nous concevons Glossia de zéro autour de l'IA et des agents, non seulement dans le produit, mais aussi dans la manière dont nous gérons l'ensemble de l'entreprise.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
Les LLM et les agents transforment tout. Non seulement ce que le logiciel peut faire, mais comment les entreprises sont construites pour créer ce logiciel. À [Glossia](https://glossia.ai), nous y voyons une opportunité d'une génération pour repenser comment le contenu parvient à chaque langue. Mais nous savons aussi qu'une bonne idée de produit ne suffit pas. Il vous faut une organisation capable d'évoluer assez vite pour compter.

Cette deuxième partie est le sujet de ce post.

## Le dilemme de l'innovateur, qui se joue en temps réel

L'industrie de la localisation est vaste et bien financée. Des entreprises comme Smartling, Phrase, Crowdin et Lokalise construisent des outils et des services depuis des années. Elles disposent de clients, de revenus, de flux de travail établis et d'équipes qui savent vendre et supporter leurs produits.

Alors pourquoi une petite équipe ciblée essaierait-elle même ?

En raison de quelque chose que Clayton Christensen a décrit dans [Le Dilemme de l'Innovateur](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): les entreprises établies peinent à adopter l'innovation disruptive, non pas parce qu'elles manquent de ressources, mais parce que leurs modèles d'affaires existants, les attentes des clients et leurs structures organisationnelles les en empêchent.

Ces entreprises ont construit leurs produits autour des mémoires de traduction, de la tarification au mot et des flux de travail des traducteurs humains. Leurs clients ont construit des modèles mentaux et des processus autour de ces briques. Changer les fondations signifie briser les promesses faites à des clients existants, former à nouveau les équipes et repenser les modèles de revenus. Même avec les meilleures intentions et le capital à investir, l'inertie organisationnelle est énorme.

Elles ont besoin d'une capacité d'innovation et de l'engagement de leur effectif pour embrasser de nouvelles idées. Mais encore plus difficile, elles ont besoin que leurs clients existants les accompagnent. Et ces clients sont investis dans le modèle ancien.

C'est l'opportunité que nous voyons. Non pas en dépit d'avoir moins de ressources, mais grâce à cela. Nous n'avons aucun héritage à protéger, aucun flux de travail à préserver, aucun client à migrer. Nous pouvons tout concevoir de zéro.

> \[\!NOTE\]
> Le dilemme de l'innovateur ne concerne pas la technologie. Il s'agit d'incitations. Les entreprises établies optimisent pour ce que leurs clients actuels veulent, ce qui rend presque impossible la poursuite de quelque chose de fondamentalement différent.

## L'IA au centre, pas en périphérie.

La plupart des entreprises adoptent l'IA en la greffant sur des processus existants. Un chatbot ici, un moteur de suggestions là. Nous prenons l'autre direction : concevoir l'entreprise entière pour qu'elle soit centrée sur l'IA dès le premier jour.

Cela signifie que l'IA n'est pas une fonctionnalité du produit. Elle façonne notre façon de construire, vendre, soutenir et piloter. Chaque décision que nous prenons commence par une question : un agent peut-il le faire ?

Le produit lui-même est un agent qui réside dans votre terminal, lit vos fichiers sources, génère des traductions, exécute vos contrôles CI, et itère jusqu'à ce que la sortie passe. C'est la partie que les gens voient. Mais derrière, la même philosophie anime l'entreprise.

## Une petite équipe, déléguant tout le reste aux agents

Nous conservons volontairement une petite équipe et restons ainsi tant que cela a du sens.

Ce n'est pas une question d'économies. Il s'agit d'éliminer une catégorie entière de travail qui ne produit pas de valeur pour les utilisateurs.

Plus vous ajoutez d'humains, plus vous avez besoin de coordination. Vous construisez des systèmes de confiance, des modèles d'autorisation, des chaînes d'approbation. Vous gérez les conflits, alignez les priorités, planifiez les réunions. Tout cela mobilise une énergie créative consacrée au maintien d'une organisation humaine plutôt qu'à la construction d'un produit.

La façon dont nous rendons cela fonctionnel consiste à déléguer tout le reste aux agents. Analyse marketing, synthèse des retours clients, recherche concurrentielle, rédaction de contenu, surveillance opérationnelle : le travail courant de gestion de l'entreprise est de plus en plus effectué par des agents que nous façonnons, révisons et améliorons.

## Choix technologiques réfléchis

Nous accordons une grande importance à notre pile technique, car cela affecte directement la rapidité avec laquelle nous pouvons avancer et la manière dont le logiciel se comporte pour les équipes qui l'auto-hébergent.

**Pour l'agent (CLI) :** Nous avons choisi Rust. Il compile en des binaires uniques et portables sur toutes les plateformes, sans dépendances d'exécution pour l'utilisateur.

**Pour le serveur :** Nous avons choisi [Elixir](https://elixir-lang.org) et le [Erlang](https://www.erlang.org) runtime. La nature fonctionnelle d'Elixir en fait un excellent choix pour les charges de travail agentiques. La VM Erlang est éprouvée pour la concurrence et la tolérance aux pannes. Et voici un bonus : un agent IA peut introspecter le système Erlang en cours d'exécution pour comprendre ce qui se passe, recueillir des informations et même corriger des problèmes en production.

**Pour la distribution :** Glossia est open source sous la [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Les équipes qui souhaitent l'utiliser elles-mêmes peuvent installer le Helm chart dans le dépôt sur n'importe quel cluster Kubernetes. Le même code propulse le service hébergé sur glossia.ai et n'importe quel déploiement auto-hébergé.

> \[\!IMPORTANT\]
> Nous sautons volontairement la complexité technique que les ingénieurs ont tendance à rechercher dès le début, avant qu'elle ne soit méritée. Chaque dépendance et chaque couche d'infrastructure doit justifier son poids.

## Ce que cela débloque

Gérer l'entreprise de cette manière n'est pas seulement une question d'efficacité. Cela modifie ce que nous pouvons offrir et la vitesse de notre apprentissage.

**Accessible à plus d'équipes.** L'industrie de la localisation a rendu ses outils inaccessibles grâce à des tarifs complexes, des frais au mot et des cycles de vente d'entreprise. Si votre flux de travail de traduction nécessite des achats, des négociations de prix et un chef de projet, la plupart des petites équipes se contenteront de déployer en anglais. En construisant une organisation efficace et en publiant le logiciel open source pour que les équipes puissent l'héberger elles-mêmes, nous pouvons rendre Glossia véritablement accessible.

**Une innovation plus rapide.** Nous souhaitons explorer beaucoup d'idées. De nouvelles interfaces pour l'agent, de meilleures boucles de rétroaction, de nouveaux moyens d'intégrer les linguistes au flux de travail. Une entreprise traditionnelle devrait recruter du personnel, aligner les équipes et planifier des revues de feuille de route. Nous testons simplement. La distance entre une idée et une expérimentation déployée se mesure en heures, et non en trimestres.

## Remettre en question notre façon de travailler, pas seulement ce que nous construisons

Nous ne sommes pas attachés émotionnellement aux anciennes façons de faire. Nous remettons activement en question ce que signifie la revue de code lorsque l'agent écrit la plupart du code. Comment la collaboration fonctionne lorsque l'équipe humaine est réduite et que les agents effectuent les tâches répétitives. Comment on corrige un bug lorsque l'agent peut inspecter le système en cours d'exécution.

Nous faisons des erreurs. Nous continuerons de les commettre. Mais en restant ouverts sur la façon dont nous concevons et gérons l'entreprise, nous continuons de découvrir des idées qui influencent le produit. La façon dont nous opérons n'est pas séparée de ce que nous construisons. C'est la même chose.

[McKinsey a récemment décrit](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) ce qu'ils appellent « l'organisation agentique », un nouveau modèle opérationnel où les agents IA deviennent des participants de première classe dans la façon dont une entreprise fonctionne. Nous ne pensons pas à cela comme un modèle. C'est simplement la façon dont nous travaillons.

## Le pari

Nous parions qu'une petite équipe dotée des bons outils, d'une bonne mentalité et sans bagage organisationnel peut devancer des entreprises avec des centaines d'employés et des millions en capitaux. Pas sur tous les fronts, mais sur celui qui compte : offrir une expérience de localisation fondamentalement meilleure.

L'industrie ne peut pas se réinventer. Nous pouvons.