%{
  title:
    "Construire une entreprise centrée sur l'IA pour défier une industrie incapable de se réinventer",
  summary:
    "Les sociétés de localisation établies ont le capital mais pas la liberté d'innover. Nous concevons Glossia de zéro autour de l'IA et des agents, non seulement dans le produit, mais aussi dans la manière dont nous gérons l'entreprise entière.",
  date: ~D[2026-02-14],
  slug: "2026-02-14-ai-centric-company",
  author: "pedro"
}
---
Les LLMs et les agents transforment tout. Non seulement ce que le logiciel peut faire, mais comment les entreprises sont construites pour le créer. Chez [Glossia](https://glossia.ai), nous voyons cela comme une opportunité une fois par génération pour repenser l'accès du contenu à chaque langue. Mais nous savons aussi qu'une bonne idée de produit ne suffit pas. Il faut une organisation capable d'agir assez vite pour faire la différence.

C'est de ce deuxième point qu'il est question dans ce post.

## Le dilemme de l'innovateur, qui se joue en temps réel.

Le secteur de la localisation est vaste et bien financé. Des entreprises comme Smartling, Phrase, Crowdin et Lokalise développent des outils et services depuis des années. Elles comptent des clients, des revenus, des flux de travail établis et des équipes capables de vendre et de soutenir leurs produits.

Alors pourquoi une petite équipe centrée essaierait-elle même de le faire ?

Parce que c'est quelque chose que Clayton Christensen a décrit dans [Le Dilemme de l'innovateur](https://en.wikipedia.org/wiki/The_Innovator%27s_Dilemma): les entreprises établies peinent à adopter l'innovation disruptive, non pas parce qu'elles manquent de ressources, mais parce que leurs modèles d'affaires existants, leurs attentes clients et leurs structures organisationnelles les empêchent de le faire.

Ces entreprises ont construit leurs produits autour des mémoires de traduction, de la tarification au mot et des flux de travail des traducteurs humains. Leurs clients ont construit des modèles mentaux et des processus autour de ces éléments de base. Changer les fondations signifie rompre les promesses faites aux clients existants, former les équipes et repenser les modèles de revenus. Même avec les meilleures intentions et le capital à investir, l'inertie organisationnelle est énorme.

Ils ont besoin de capacités d'innovation et de l'engagement de leur personnel pour embrasser de nouvelles idées. Mais c'est encore plus difficile : ils doivent que leurs clients existants les rejoignent. Et ces clients sont investis dans l'ancien modèle.

C'est l'opportunité que nous voyons. Non pas malgré nos ressources réduites, mais grâce à elles. Nous n'avons pas d'héritage à protéger, pas de flux de travail à préserver, ni de clients à migrer. Nous pouvons concevoir tout de toutes pièces.

> \[\!NOTE\]
> Le dilemme de l'innovateur ne porte pas sur la technologie. Il s'agit d'incitations. Les entreprises établies optimisent pour ce que leurs clients actuels souhaitent, ce qui rend presque impossible de poursuivre quelque chose de fondamentalement différent.

## IA au centre, pas aux bords

La plupart des entreprises adoptent l'IA en la greffant sur des processus existants. Un chatbot ici, un moteur de suggestions là. Nous prenons la direction opposée : concevoir toute l'entreprise pour qu'elle soit centrée sur l'IA dès le premier jour.

Cela signifie que l'IA n'est pas une fonctionnalité du produit. Elle façonne la manière dont nous concevons, vendons, accompagnons et gérons. Chaque décision que nous prenons commence par une question : un agent peut-il le faire ?

Le produit lui-même est un agent qui vit dans votre terminal, lit vos fichiers sources, génère des traductions, exécute vos contrôles CI et itère jusqu'à ce que la sortie soit validée. C'est la partie que l'on voit. Mais derrière, la même philosophie dirige l'entreprise.

## Une petite équipe, déléguant tout le reste aux agents

Nous conservons délibérément l'équipe petite et nous en restons là tant que cela a du sens.

Il ne s'agit pas d'économiser de l'argent. Il s'agit d'éliminer une catégorie entière de travail qui ne produit pas de valeur pour les utilisateurs.

Plus vous ajoutez d'humains, plus vous avez besoin de coordination. Vous construisez des systèmes de confiance, des modèles d'autorisation, des chaînes d'approbation. Vous gérez les conflits, alignez les priorités, planifiez des réunions. Tout cela consomme de l'énergie créative pour entretenir une organisation humaine plutôt que de créer un produit.

La façon dont nous parvenons à faire fonctionner cela consiste à déléguer tout le reste aux agents.

## Choix technologiques délibérés

Nous sommes très intentionnels quant à notre pile technologique car cela affecte directement la vitesse à laquelle nous pouvons avancer et la façon dont le logiciel se comporte pour les équipes qui l'hébergent elles-mêmes.

**Pour l'agent (CLI) :** Nous avons choisi Rust. Il se compile en un seul binaire portable sur toutes les plateformes, sans dépendances d'exécution pour l'utilisateur.

**Pour le serveur :** Nous avons choisi [Elixir](https://elixir-lang.org) et le [Erlang](https://www.erlang.org) runtime. La nature fonctionnelle d'Elixir le rend idéal pour les charges de travail agentic. La machine virtuelle Erlang est éprouvée pour la concurrence et la tolérance aux pannes. Et voici un plus : un agent IA peut introspecter le système Erlang en cours d'exécution pour comprendre ce qui se passe, recueillir des analyses et même corriger les problèmes en production.

**Pour la distribution :** Glossia est open source sous la [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Les équipes qui souhaitent l'exécuter elles-mêmes peuvent installer le Helm chart du dépôt sur n'importe quel cluster Kubernetes. Le même code alimente le service hébergé sur glossia.ai et n'importe quel déploiement auto-hébergé.

> \[\!IMPORTANT\]
> Nous sommes méthodiques dans l'évitement de la complexité technique que les ingénieurs ont tendance à privilégier précocement tant qu'elle n'est pas justifiée. Chaque dépendance et chaque couche d'infrastructure doit justifier son poids.

## Ce que cela débloque

Diriger l'entreprise de cette manière ne se résume pas à un simple gain d'efficacité. Cela transforme ce que nous offrons et la vitesse à laquelle nous apprenons.

**Accessible à plus d'équipes.** L'industrie de la localisation a rendu ses outils inaccessibles par des tarifs complexes, des frais au mot et des cycles de vente d'entreprise. Si votre workflow de traduction nécessite du procurement, des négociations de prix et un chef de projet, la plupart des petites équipes se contenteront de déployer en anglais. En construisant une organisation efficace et en diffusant le logiciel en open source pour permettre aux équipes de l'héberger elles-mêmes, nous pouvons rendre Glossia véritablement accessible.

**Innovation plus rapide.** Nous voulons explorer beaucoup d'idées. Nouvelles interfaces pour l'agent, meilleurs boucles de rétroaction, nouvelles façons d'intégrer les linguistes dans le flux de travail. Une entreprise traditionnelle aurait besoin de recruter du personnel, d'aligner les équipes et de planifier des revues de roadmap. Nous testons simplement des choses. La distance entre une idée et une expérience déployée est mesurée en heures, pas en trimestres.

## Remettre en question la manière dont nous travaillons, pas seulement ce que nous construisons.

Nous ne sommes pas émotionnellement attachés aux anciennes façons de faire. Nous remettons activement en question la signification de la revue de code lorsque l'agent écrit la majorité du code. Comment fonctionne la collaboration lorsque l'équipe humaine est petite et que les agents réalisent le travail de routine. Comment vous corrigez un bug lorsque l'agent peut inspecter le système en cours d'exécution.

Nous faisons des erreurs. Nous continuerons à en commettre. Mais en restant ouverts d'esprit sur la manière dont nous concevons et gérons l'entreprise, nous continuons de découvrir des idées qui influencent le produit. La manière dont nous opérons n'est pas séparée de ce que nous construisons. Ils sont la même chose.

[McKinsey a récemment décrit](https://www.mckinsey.com/capabilities/people-and-organizational-performance/our-insights/the-agentic-organization-contours-of-the-next-paradigm-for-the-ai-era) ce qu'on appelle "l'organisation agentique", un nouveau modèle opérationnel où les agents IA deviennent des participants à part entière de la manière dont une entreprise fonctionne. Nous ne pensons pas à cela comme un modèle. C'est simplement la façon dont nous travaillons.

## Le pari

Nous faisons le pari qu'une petite équipe avec les bons outils, la bonne mentalité et aucun bagage organisationnel puisse surpasser les entreprises avec des centaines d'employés et des millions de fonds. Pas sur tous les fronts, mais sur celui qui compte : offrir une expérience de localisation fondamentalement meilleure.

L'industrie ne peut pas se réinventer. Nous pouvons.