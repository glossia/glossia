%{
  title:
    "La localisation était bloquée dans le passé. Nous avons créé Glossia pour la faire avancer.",
  summary:
    "Les outils de localisation traditionnels ajoutent des surcoûts, cassent la CI et vous verrouillent dans les écosystèmes de fournisseurs. Nous explorons ce à quoi pourrait ressembler un flux de travail de localisation piloté par des agents.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si vous avez déjà déployé du logiciel dans plus d'une langue, vous connaissez la procédure. Vous choisissez une plateforme de localisation, vous la connectez à votre dépôt, puis vous passez le reste de votre temps à gérer la synchronisation. Le contenu sort, les traductions reviennent, et quelque part en chemin, les choses cassent.

Ce surcoût, l'aller-retour constant du contenu depuis et vers votre dépôt, est le prix que chaque équipe paie en utilisant les outils de localisation d'aujourd'hui. Cela semble mineur jusqu'à ce que vous soyez celui qui doit diagnostiquer pourquoi une PR de traduction a cassé la build de votre site à 18 h un vendredi.

## Une conception héritée d'avant internet

La plupart des plateformes de localisation ont été conçues autour de concepts qui précèdent le flux de développement moderne. Mémoires de traduction. Correspondance floue. Des traducteurs humains travaillant dans des éditeurs propriétaires, assistés par des outils qui suggèrent des chaînes similaires issues d'une base de données.

Ces idées avaient du sens lorsque la traduction était un processus manuel et hors ligne. Mais les entreprises ont transformé les mémoires de traduction en un mécanisme de verrouillage. Vos traductions passées, le savoir institutionnel que vous avez payé, vivent dans leur plateforme. Changer de fournisseur signifie tout recommencer à zéro, ou payer pour une exportation qui ne fonctionne jamais vraiment.

Le résultat est une industrie bâtie sur un frottement artificiel. Votre contenu quitte votre dépôt, entre dans une boîte noire, et revient selon le planning de quelqu'un d'autre.

## La boucle de rétroaction rompue

Le problème est structurel : les outils de localisation externes ne peuvent pas exécuter votre pipeline CI. Ils ignorent vos linters, votre étape de build, votre vérificateur de liens ou votre schéma frontmatter. Ils repoussent le contenu traduit vers votre dépôt et espèrent le meilleur. Lorsqu'il casse, et que cela se produit, quelqu'un de l'équipe doit arrêter son travail pour corriger des problèmes de formatage, une syntaxe cassée ou un marquage invalide introduit par l'outil de traduction.

Les LLM et les expériences agentic nous offrent de nouvelles opportunités pour repenser entièrement ces flux de travail. Un agent qui génère une traduction, exécute vos vérifications, repère l'erreur et réessaie jusqu'à ce que la sortie soit valide. Ce type de boucle de rétroaction serrée change tout.

Mais cela ne fonctionne que si le contenu reste là où il réside : dans votre dépôt. Dès que vous l'envoyez sur une plateforme externe, les traductions reviennent selon un calendrier tiers, et l'intégration se rompt. La rétroaction qui aurait pu être instantanée prend maintenant des heures ou des jours. Le contexte qui en rendait l'utilité est perdu. Vous perdez la boucle, et avec elle, tout l'avantage que les flux de travail agentic devaient vous offrir.

## Observations ayant façonné Glossia

Ces frustrations ne se sont pas transformées en Glossia d'elles-mêmes. Le projet est issu d'une expérience approfondie en développement et en localisation, ce qui a clarifié des problèmes difficiles à voir d'un seul côté. Comprendre les flux de travail linguistiques, la dynamique humaine des équipes de traduction, et les raisons pour lesquelles les outils existants sont arrivés à l'état où ils sont était essentiel.

Nous sommes arrivés ensemble aux mêmes constats : les outils de localisation ont été conçus pour un monde sans LLMs, sans agents de codage, et sans pipelines CI. Le modèle entier présumait que la traduction était quelque chose qui se passait en dehors du flux de travail de développement et qui était renvoyé en arrière. Cela avait du sens il y a dix ans. Ce n'est plus le cas.

Nous avons commencé à nous poser cette question : **si les agents de localisation pouvaient fonctionner de la même manière que les agents de codage ?**

Nous avons prêté une attention particulière à la façon [Anthropic](https://anthropic.com) réfléchit aux flux de travail d'agents avec Claude. Le modèle consistant à donner à un agent un accès aux outils, à lui laisser raisonner sur une tâche, à valider sa propre sortie et à itérer lorsque quelque chose ne va pas correspond étonnamment bien à la localisation. Un agent de traduction capable de lire vos fichiers sources, de comprendre le contexte du projet, de générer des traductions, d'exécuter votre linter et de corriger les problèmes avant d'ouvrir une pull request. Ce n'est pas une fantaisie. C'est le flux de travail que nous construisons.

## Glossia est notre cadeau pour l'industrie logicielle

Nous avons construit Glossia car nous voulons que plus de logiciels soient localisés, pas moins.

Les processus complexes et les plateformes onéreuses rendent la localisation inaccessible aux petites équipes, aux développeurs indépendants et aux projets secondaires. Si votre flux de travail de traduction nécessite un processus d'approvisionnement, une négociation de prix au mot, et un responsable de projet pour coordonner les transferts, la plupart des équipes publieront simplement en anglais et s'en tiendront là.

Glossia utilise des modèles dont vous avez déjà accès. Et elle valide la sortie avec vos propres outils, pas les nôtres.

Nous pensons que la localisation devrait être aussi naturelle que l'exécution de votre suite de tests.

## Un agent d'abord, les interfaces ensuite

Au cœur de Glossia, c'est un agent. Nous commençons par le terminal comme interface principale car c'est là que les problèmes les plus difficiles sont résolus en premier : lire vos fichiers sources, générer des traductions, lancer vos vérifications et itérer jusqu'à ce que la sortie soit valide. C'est le même modèle que [OpenAI](https://openai.com) suivi par [Codex](https://openai.com/index/openai-codex/) et [Anthropic](https://anthropic.com) avec [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Vous construisez l'agent, lui donnez un terminal, et le laissez travailler.

Mais le terminal n'est que la première interface, pas la seule. Nous savons que pas tout le monde qui contribue à la qualité de la localisation est un développeur. Nous en parlons souvent en interne. Ceux qui s'inquiètent le plus de l'exactitude de la traduction, du ton et de la nuance culturelle sont souvent des linguistes et des spécialistes du contenu qui ne raisonnent pas en termes de branches, de compilation ou de JSON.

C'est pourquoi nous souhaitons créer de nouvelles interfaces au-dessus du même agent. Quelque chose où un linguiste voit le contenu, le contexte et la traduction côte à côte. Ils apportent le jugement humain que aucun modèle ne peut remplacer. Ils perfectionnent ce qui nécessite d'être perfectionné. Et l'agent gère tout le reste : la commit, la validation, l'ouverture de la pull request.

Nous n'avons pas encore toutes les réponses, et c'est intentionnel. Nous préférerions construire cela de manière réfléchie plutôt que de précipiter une interface qui raterait le but. Mais la direction est claire : Glossia doit accueillir tout le monde qui s'efforce de faire parler chaque logiciel dans chaque langue.

## Restez à l'écoute

Glossia en est encore à ses débuts, et nous le construisons de manière ouverte. Si cela résonne avec votre approche de la localisation, gardez un œil sur le projet. Nous vous en dirons plus au fur et à mesure.