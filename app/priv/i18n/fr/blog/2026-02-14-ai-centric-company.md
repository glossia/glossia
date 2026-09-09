%{
  title:
    "Construire une entreprise axée sur l'IA pour défier un secteur qui ne peut pas se réinventer lui-même",
  summary:
    "Les entreprises de localisation établies ont le capital mais pas la liberté d'innover. Nous concevons Glossia de zéro autour de l'IA et des agents, non seulement dans le produit, mais aussi dans la façondont nous gérons l'ensemble de notre activité.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
Les LLMs et les agents transforment tout. Pas seulement ce que le logiciel peut faire, mais comment les entreprises sont construites pour créer ce logiciel. Chez [Glossia](https://glossia.ai), nous y voyons cela comme une opportunité d'une génération pour repenser la façon dont le contenu atteint toutes les langues. Mais nous savons également qu'avoir une bonne idée de produit ne suffit pas. Il faut une organisation capable de bouger assez vite pour compter.

Cette deuxième partie est le sujet de ce post.

## Le dilemme de l'innovateur, qui se joue en temps réel

Le secteur de la localisation est vaste et bien financé. Des entreprises comme Smartling, Phrase, Crowdin et Lokalise construisent des outils et des services depuis des années. Elles ont des clients, des revenus, des flux de travail établis et des équipes qui savent vendre et soutenir leurs produits.

Alors pourquoi une petite équipe focalisée essaierait-elle même ?

Car quelque chose que Clayton Christensen a décrit dans [Le dilemme de l'innovateur](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): les entreprises établies peinent à adopter l'innovation disruptive, non pas parce qu'elles manquent de ressources, mais parce que leurs modèles d'affaires existants, les attentes des clients et leurs structures organisationnelles les empêchent de le faire.

Ces entreprises ont construit leurs produits autour des mémoires de traduction, de la tarification au mot et des flux de travail de traducteurs humains. Leurs clients ont construit des modèles mentaux et des processus autour de ces briques. Changer les fondations signifie rompre des promesses envers des clients existants, requalifier les équipes et repenser les modèles de revenus. Même avec les meilleures intentions et le capital à investir, l'inertie organisationnelle est énorme.

Ils ont besoin de capacité d'innovation et de l'engagement de leur effectif pour embrasser les nouvelles idées. Mais c'est encore plus difficile : ils ont besoin que leurs clients existants viennent à bord. Et ces clients sont investis dans l'ancien modèle.

C'est l'ouverture que nous voyons. Non pas en dépit de ressources plus faibles, mais à cause d'elles. Nous n'avons aucun héritage à protéger, aucun flux à préserver, aucun client à migrer. Nous pouvons tout concevoir de zéro.

> \[\!NOTE\]
> Le dilemme de l'innovateur ne concerne pas la technologie. Il s'agit d'incitations. Les entreprises établies optimisent pour ce que leurs clients actuels veulent, ce qui rend pratiquement impossible de poursuivre quelque chose de fondamentalement différent.

## IA au centre, pas aux extrémités

La plupart des entreprises adoptent l'IA en y greffant sur leurs processus existants. Un chatbot ici, un moteur de suggestions là. Nous allons dans l'autre sens : concevoir toute l'entreprise pour être centrée sur l'IA dès le premier jour.

Cela signifie que l'IA n'est pas une fonctionnalité du produit. Elle façonne la façon dont nous concevons, vendons, soutenons et gérons. Chaque décision que nous prenons commence par une question : un agent peut-il le faire ?

Le produit lui-même est un agent qui réside dans votre terminal, lit vos fichiers source, génère des traductions, effectue vos contrôles CI, et itère jusqu'à ce que la sortie soit valide. C'est cette partie que les gens voient. Mais derrière, c'est la même philosophie qui anime l'entreprise.

## Une petite équipe, déléguant tout le reste aux agents

Nous conservons délibérément l'équipe réduite et y restons ainsi tant que cela a du sens.

Il ne s'agit pas d'économiser de l'argent. Il s'agit d'éliminer une catégorie entière de travail qui ne génère pas de valeur pour les utilisateurs.

Plus vous ajoutez d'humains, plus vous avez besoin de coordination. Vous créez des systèmes de confiance, des modèles d'autorisation, des chaînes d'approbation. Vous gérez les conflits, alignez les priorités, planifiez des réunions. Tout cela consomme de l'énergie créative qui serait orientée vers l'entretien d'une organisation humaine plutôt que vers la création d'un produit.

La manière dont nous faisons fonctionner cela consiste à déléguer tout le reste aux agents. Analyse marketing, synthèse des retours clients, recherche concurrentielle, rédaction de contenu, suivi opérationnel : le travail de routine de faire tourner la société est de plus en plus effectué par des agents que nous façonnons, évaluons et améliorons.

## Des choix technologiques délibérés

Nous sommes très intentionnels concernant notre pile car elle affecte directement la vitesse à laquelle nous pouvons avancer et le comportement du logiciel pour les équipes qui l'auto-hébergent.

**Pour l'agent (CLI):** Nous avons choisi Rust. Il se compile en un binaire unique et portable sur toutes les plateformes, sans dépendances d'exécution pour l'utilisateur.

**Pour le serveur:** Nous avons choisi [Elixir](https://elixir-lang.org) et le [Erlang](https://www.erlang.org) runtime. La nature fonctionnelle d'Elixir en fait un excellent choix pour les charges de travail d'agents. La VM Erlang est éprouvée pour la concurrence et la tolérance aux pannes. Et voici un bonus : un agent IA peut introspecter le système Erlang en cours d'exécution pour comprendre ce qui se passe, recueillir des analyses et même corriger des problèmes en production.

**Pour la distribution:** Glossia est open source sous la [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Les équipes qui souhaitent l'exécuter elles-mêmes peuvent installer le Helm chart dans le dépôt sur n'importe quel cluster Kubernetes. Le même code propulse le service hébergé à glossia.ai et n'importe quel déploiement auto-hébergé.

> \[\!IMPORTANT\]
> Nous agissons avec intention pour éviter la complexité technique que les ingénieurs ont tendance à adopter précocement, tant qu'elle n'est pas justifiée. Chaque dépendance et chaque couche d'infrastructure doit justifier son poids.

## Ce que cela débloque

Mener l'entreprise de cette manière ne se résume pas à une simple question d'efficacité. Cela change ce que nous pouvons offrir et à quelle vitesse nous pouvons apprendre.

**Accessible à plus d'équipes.** L'industrie de la localisation a rendu ses outils inaccessibles à cause de tarifs complexes, de frais par mot et de cycles de vente d'entreprise. Si votre workflow de traduction nécessite des achats, des négociations de prix et un chef de projet, la plupart des petites équipes se contenteront de livrer en anglais. En structurant une organisation efficace et en diffusant le logiciel en open source pour permettre aux équipes de l'héberger elles-mêmes, nous pouvons rendre Glossia véritablement accessible.

**Une innovation plus rapide.** Nous souhaitons explorer beaucoup d'idées. Nouvelles interfaces pour l'agent, meilleures boucles de rétroaction, nouveaux moyens d'intégrer les linguistes dans le workflow. Une entreprise traditionnelle devrait recruter, aligner les équipes et programmer des revues de feuille de route. Nous testons simplement des choses. La distance entre une idea et une expérience déployée se mesure en heures, pas en trimestres.

## Remettre en question comment nous travaillons, pas seulement ce que nous construisons.

Nous ne sommes pas attachés émotionnellement aux anciennes façons de faire. Nous questionnons activement ce que la revue de code signifie quand un agent rédige la majeure partie du code. Comment fonctionne la collaboration lorsque l'équipe humaine est réduite et que les agents gèrent le travail routinier. Comment résoudre un bug lorsque l'agent peut inspecter le système en fonctionnement.

Nous faisons des erreurs. Nous continuerons à en commettre. Mais en restant ouverts d'esprit quant à la conception et à la direction de l'entreprise, nous continuons de découvrir des idées qui influencent le produit. La manière dont nous agissons n'est pas séparée de ce que nous construisons. Ils sont la même chose.

[McKinsey a récemment décrit](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) ce qu'ils appellent « l'organisation agentic », un nouveau modèle opérationnel où les agents IA deviennent des participants à part entière dans le fonctionnement d'une entreprise. Nous ne le considérons pas comme un modèle. C'est simplement la façon dont nous travaillons.

## Le pari

Nous parions qu'une petite équipe, avec les bons outils, la bonne mentalité et sans bagage organisationnel, peut surpasser des entreprises avec des centaines d'employés et des millions en financement. Pas sur tous les fronts, mais sur celui qui compte : offrir une expérience de localisation fondamentalement meilleure.

L'industrie ne peut pas se réinventer. Nous pouvons.