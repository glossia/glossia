%{
  title:
    "Construire une entreprise axée sur l'IA pour défier une industrie qui ne peut pas se réinventer.",
  summary:
    "Les entreprises de localisation établies ont le capital, mais pas la liberté d'innover. Nous concevons Glossia de toutes pièces autour de l'IA et des agents, pas seulement dans le produit, mais dans la façon dont nous gérons l'entreprise dans son ensemble.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
Les LLM et agents transforment tout. Pas seulement ce que le logiciel peut faire, mais comment les entreprises sont construites pour créer ce logiciel. Chez [Glossia](https://glossia.ai), nous le voyons comme une opportunité d'une génération pour repenser comment le contenu atteint chaque langue. Mais nous savons aussi qu'une bonne idée de produit ne suffit pas. Il faut une organisation capable d'agir assez vite pour qu'elle compte.

C'est de cette seconde partie que traite ce post.

## Le dilemme de l'innovateur, se jouant en temps réel

Le secteur de la localisation est vaste et bien financé. Des entreprises comme Smartling, Phrase, Crowdin et Lokalise construisent des outils et des services depuis des années. Elles disposent de clients, de revenus, de workflows établis et d'équipes qui savent vendre et accompagner leurs produits.

Alors pourquoi une petite équipe concentrée essaierait-elle même ?

À cause de quelque chose que Clayton Christensen a décrit dans [Le Dilemme de l'innovateur](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): les entreprises établies peinent à adopter l'innovation disruptive, non pas parce qu'elles manquent de ressources, mais parce que leurs modèles commerciaux existants, les attentes de leurs clients et leurs structures organisationnelles les en empêchent.

Ces entreprises ont conçu leurs produits autour des mémoires de traduction, de la tarification au mot et des flux de travail des traducteurs humains. Leurs clients ont construit des modèles mentaux et des processus autour de ces briques. Changer les fondations signifie briser des promesses faites aux clients existants, réentraîner les équipes et repenser les modèles de revenus. Même avec les meilleures intentions et le capital pour investir, l'inertie organisationnelle est énorme.

Ils ont besoin d'une capacité d'innovation et d'un engagement de leur main d'œuvre pour embrasser de nouvelles idées. Mais c'est encore plus difficile : ils doivent amener leurs clients existants à accompagner la transition. Et ces clients sont investis dans l'ancien modèle.

C'est l'ouverture que nous voyons. Non pas en dépit d'avoir moins de ressources, mais à cause de cela. Nous n'avons aucun héritage à protéger, aucun flux de travail à préserver, aucun client à migrer. Nous pouvons tout concevoir de zéro.

> \[\!NOTE\]
> Le dilemme de l'innovateur ne concerne pas la technologie. Il s'agit d'incitations. Les entreprises établies optimisent pour ce que leurs clients actuels veulent, ce qui rend presque impossible de poursuivre quelque chose de fondamentalement différent.

## L'IA au centre, et non aux extrémités

La plupart des entreprises adoptent l'IA en la greffant sur des processus existants. Un chatbot ici, un moteur de suggestions là. Nous prenons l'autre voie : concevoir l'entreprise entière pour être centrée sur l'IA dès le premier jour.

Cela signifie que l'IA n'est pas une fonctionnalité du produit. Elle façonne la manière dont nous concevons, commercialisons, soutenons et gérons. Chaque décision que nous prenons commence par une question : un agent peut-il le faire ?

Le produit lui-même est un agent qui réside dans votre terminal, lit vos fichiers sources, génère des traductions, exécute vos contrôles CI et itère jusqu'à ce que la sortie soit valide. C'est ce que les gens voient. Mais derrière cela, la même philosophie dirige l'entreprise.

## Une petite équipe, délèguant tout le reste à des agents

Nous choisissons délibérément de garder l'équipe petite et de demeurer ainsi aussi longtemps que cela a du sens.

Il ne s'agit pas d'économiser de l'argent. Il s'agit d'éliminer toute catégorie de travail qui ne produit pas de valeur pour les utilisateurs.

Plus vous ajoutez de personnes, plus vous avez besoin de coordination. Vous créez des systèmes de confiance, des modèles d'autorisation, des chaînes d'approbation. Vous gérez les conflits, alignez les priorités, planifiez des réunions. Tout cela est une énergie créative consacrée à maintenir une organisation humaine plutôt qu'à construire un produit.

La manière dont nous faisons fonctionner cela consiste à délèguer tout le reste à des agents. Analyse marketing, synthèse des retours clients, recherche concurrentielle, rédaction de contenu, suivi opérationnel : le travail de routine de faire fonctionner l'entreprise est de plus en plus réalisé par des agents que nous façonnons, évaluons et améliorons.

## Choix technologiques délibérés

Nous sommes très intentionnels concernant notre pile car cela affecte directement la vitesse à laquelle nous pouvons avancer et la manière dont le logiciel se comporte pour les équipes qui l'auto-hébergent.

**Pour l'agent (CLI):** Nous avons choisi Rust. Il se compile en binaires uniques et portables sur toutes les plateformes, sans dépendances runtime pour l'utilisateur.

**Pour le serveur :** Nous avons choisi [Elixir](https://elixir-lang.org) et le [Erlang](https://www.erlang.org) runtime. La nature fonctionnelle d'Elixir en fait un excellent choix pour les charges de travail d'agents. La VM Erlang est éprouvée pour la concurrence et la tolérance aux pannes. Et voici un bonus : un agent IA peut introspecter le système Erlang en cours d'exécution pour comprendre ce qui se passe, recueillir des analyses et même résoudre des problèmes en production.

**Pour la distribution :** Glossia est open source sous la [Licence O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Les équipes souhaitant l'exploiter elles-mêmes peuvent installer le Helm chart dans le dépôt sur n'importe quel cluster Kubernetes. Le même code alimente le service hébergé sur glossia.ai et n'importe quel déploiement auto-hébergé.

> \[\!IMPORTANT\]
> Nous choisissons délibérément de sauter la complexité technique que les ingénieurs ont tendance à adopter précocement, avant que cela ne soit justifié. Chaque dépendance et chaque couche d'infrastructure doit justifier son poids.

## Ce que cela débloque

Exploiter l'entreprise de cette manière n'est pas seulement une question d'optimisation. Cela change ce que nous pouvons offrir et à la vitesse à laquelle nous apprenons.

**Accessible à plus d'équipes.** L'industrie de la localisation a rendu ses outils inaccessibles grâce à des tarifs complexes, des frais au mot et des cycles de vente d'entreprise. Si votre flux de travail de traduction nécessite un processus d'achat, des négociations de prix et un chef de projet, la plupart des petites équipes se contenteront de publier en anglais. En construisant une organisation efficace et en diffusant le logiciel open source pour que les équipes puissent l'héberger elles-mêmes, nous pouvons rendre Glossia véritablement accessible.

**Une innovation plus rapide.** Nous voulons explorer beaucoup d'idées. De nouvelles interfaces pour l'agent, de meilleurs cycles de rétroaction, de nouveaux moyens d'intégrer les linguistes au flux de travail. Une entreprise traditionnelle devrait augmenter ses effectifs, aligner les équipes et planifier des revues de feuille de route. Nous testons simplement des choses. La distance entre une idée et une expérience déployée se mesure en heures, pas en trimestres.

## Remettre en question comment nous travaillons, pas seulement ce que nous construisons

Nous ne sommes pas émotionnellement attachés aux anciennes manières de fonctionner. Nous questionnons activement ce que signifie la revue de code lorsqu'un agent écrit la plupart du code. Comment fonctionne la collaboration lorsque l'équipe humaine est petite et que les agents effectuent le travail de routine. Comment corriger un bug lorsque l'agent peut inspecter le système en cours d'exécution.

Nous faisons des erreurs. Nous continuerons à en faire. Mais en restant ouverts d'esprit concernant la façon dont nous concevons et gérons l'entreprise, nous continuons de découvrir des idées qui influencent le produit. La façon dont nous opérons n'est pas séparée de ce que nous construisons. Ils sont exactement la même chose.

[McKinsey a récemment décrit](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) ce qu'ils appellent "l'organisation agissante," un nouveau modèle opérationnel où les agents IA deviennent des participants de première classe dans la façon dont une entreprise fonctionne. Nous ne pensons pas à cela comme un modèle. C'est simplement la façon dont nous travaillons.

## Le pari

Nous parions qu'une petite équipe dotée des bons outils, de la bonne mentalité et sans bagage organisationnel peut surpasser des entreprises avec des centaines d'employés et des millions en financement. Pas sur tous les fronts, mais sur celui qui compte : livrer une expérience de localisation fondamentalement meilleure.

L'industrie ne peut pas se réinventer. Nous pouvons.