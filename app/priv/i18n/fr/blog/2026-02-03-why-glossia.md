%{
  title:
    "La localisation est restée bloquée dans le passé. Nous avons construit Glossia pour la faire avancer.",
  summary:
    "Les outils de localisation traditionnels ajoutent une surcharge, cassent la CI et vous verrouillent dans des écosystèmes de fournisseurs. Nous explorons ce à quoi peut ressembler un flux de travail de localisation agentique.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si vous avez déjà déployé du logiciel dans plus d'une langue, vous connaissez la donne. Vous choisissez une plateforme de localisation, vous la connectez à votre dépôt, puis passez le reste de votre temps à gérer la synchronisation. Le contenu part, les traductions reviennent, et quelque part en chemin, les choses cassent.

Ce surcoût, l'aller-retour constant du contenu vers et depuis votre dépôt, est le prix que chaque équipe paie pour utiliser les outils de localisation d'aujourd'hui. Ça semble minime jusqu'à ce que vous soyez celui qui doit déboguer pourquoi une PR de traduction a cassé la build de votre site le vendredi à 18 heures.

## Un design hérité de l'ère pré-internet.

La plupart des plateformes de localisation ont été conçues autour de concepts qui précèdent le workflow de développement moderne. Mémoire de traduction. Correspondance floue. Traducteurs humains travaillant dans des éditeurs propriétaires, assistés par des outils suggérant des chaînes similaires depuis une base de données.

Ces idées avaient du sens lorsque la traduction était un processus manuel, hors connexion. Mais les entreprises ont transformé les mémoires de traduction en un mécanisme de verrouillage. Vos traductions passées, la connaissance institutionnelle que vous avez payée, vivent dans leur plateforme. Passer à un autre fournisseur signifie repartir de zéro, ou payer pour une exportation qui ne fonctionne jamais vraiment.

Le résultat est une industrie bâtie sur une friction artificielle. Votre contenu quitte votre dépôt, entre dans une boîte noire, et revient selon le calendrier d'autrui.

## La boucle de rétroaction brisée

Le problème est structurel : les outils de localisation externes ne peuvent pas exécuter votre pipeline CI. Ils ne sont pas au courant de vos linters, de votre étape de build, de votre vérificateur de liens, ou de votre schéma de frontmatter. Ils poussent le contenu traduit vers votre dépôt et espèrent le meilleur. Quand ça casse, et que c'est le cas, quelqu'un de l'équipe doit arrêter ce qu'il fait pour corriger les problèmes de formatage, la syntaxe brisée, ou le markup invalide introduit par l'outil de traduction.

Les LLM et les expériences d'agents nous offrent de nouvelles opportunités pour repenser entièrement ces flux de travail. Un agent qui génère une traduction, exécute vos vérifications, détecte l'erreur et réessaie jusqu'à ce que le résultat soit valide. Ce type de boucle de rétroaction serrée change tout.

Mais cela ne fonctionne que si le contenu reste là où il réside : dans votre dépôt. Dès que vous l'envoyez sur une plateforme externe, les traductions reviennent dans le calendrier d'un tiers, et l'intégration échoue. Le feedback qui aurait pu être instantané prend désormais des heures voire des jours. Le contexte qui rendait cela utile a disparu. Vous perdez le cycle, et avec lui, tout l'avantage que les flux de travail d'agents étaient censés vous apporter.

## Observations qui ont façonné Glossia

Ces frustrations n'ont pas donné naissance à Glossia seules. Le projet est issu d'une riche expérience tant dans le développement que dans la localisation, ce qui a permis de clarifier des problèmes difficilement perceptibles d'un seul côté. Comprendre les flux de travail linguistiques, la dynamique humaine des équipes de traduction, et les raisons pour lesquelles les outils existants en sont venus là était essentiel.

Nous arrivons continuellement aux mêmes observations ensemble : les outils de localisation ont été conçus pour un monde sans LLM, sans agents de codage, et sans pipelines CI. Ce modèle entier supposait que la traduction se déroulait en dehors du flux de travail de développement et était réinjectée dans ce flux. Cela avait du sens il y a dix ans. Ce n'est plus le cas aujourd'hui.

Nous avons commencé à nous demander : **Et si les agents de localisation pouvaient fonctionner de la même manière que les agents de codage ?**

Nous accordons une attention particulière à la façon dont [Anthropic](https://anthropic.com) pense aux flux d'agents avec Claude. Le schéma consistant à donner un accès aux outils à un agent, en lui permettant de raisonner sur une tâche, valider sa propre sortie et itérer lorsqu'un problème survient, correspond remarquablement bien à la localisation. Un agent de traduction capable de lire vos fichiers sources, comprendre le contexte du projet, générer des traductions, exécuter votre linter et corriger les problèmes avant de créer une demande de fusion. Ce n'est pas une utopie. C'est le flux de travail que nous construisons.

## Glossia est notre cadeau pour l'industrie du logiciel

Nous avons créé Glossia car nous souhaitons que plus de logiciels soient localisés, pas moins.

Les processus complexes et les plateformes coûteuses rendent la localisation inaccessible aux petites équipes, aux développeurs indépendants et aux projets secondaires. Si votre flux de travail de traduction nécessite un processus d'achat, une négociation de prix au mot et la coordination d'un chef de projet pour les transferts, la plupart des équipes publieront simplement en anglais et considéreront le travail terminé.

Glossia utilise des modèles auxquels vous avez déjà accès. Et elle valide les sorties avec vos propres outils, pas les nôtres.

Nous pensons que la localisation devrait être aussi naturelle que l'exécution de votre suite de tests.

## Un agent d'abord, les interfaces en second.

Au cœur, Glossia est un agent. Nous commençons par le terminal comme interface principale car c'est là que les problèmes les plus difficiles sont résolus en premier : lire vos fichiers sources, générer des traductions, exécuter vos vérifications et itérer jusqu'à ce que la sortie soit valide. C'est la même logique que [OpenAI](https://openai.com) suivi avec [Codex](https://openai.com/index/openai-codex/) et [Anthropic](https://anthropic.com) avec [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Vous construisez l'agent, lui donnez un terminal, et laissez-le fonctionner.

Mais le terminal n'est que la première interface, et non la seule. Nous savons que tous ceux qui contribuent à la qualité de la localisation ne sont pas des développeurs. Nous en parlons souvent en interne. Les personnes qui s'inquiètent le plus de l'exactitude de la traduction, du ton et des nuances culturelles sont souvent des linguistes et des spécialistes du contenu qui ne raisonnent pas en termes de branches, de compilation ou de JSON.

C'est pourquoi nous voulons construire de nouvelles interfaces basées sur le même agent. Un espace où un linguiste voit le contenu, le contexte et la traduction côte à côte. Ils apportent le jugement humain qu'aucun modèle ne peut remplacer. Ils affinent ce qui doit l'être. Et l'agent gère tout le reste : le commit, la validation, l'ouverture de la pull request.

Nous n'avons pas encore toutes les réponses, et c'est intentionnel. Nous préférerions construire cela avec soin plutôt que de nous précipiter dans une interface utilisateur qui manquerait le but. Mais la direction est claire : Glossia doit accueillir tout le monde qui veille à faire parler le logiciel dans chaque langue.

## Restez à l'écoute

Glossia en est encore à ses débuts, et nous le développons en public. Si cela résonne avec votre vision de la localisation, gardez un œil sur le projet. Nous partagerons plus d'informations au fur et à mesure.