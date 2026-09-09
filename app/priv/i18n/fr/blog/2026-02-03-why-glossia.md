%{
  title:
    "La localisation était restée figée dans le passé. Nous avons construit Glossia pour la faire avancer.",
  summary:
    "Les outils de localisation traditionnels ajoutent des surcoûts, brisent la CI, et vous enferment dans des écosystèmes de fournisseurs. Nous explorons ce qu'un workflow de localisation agentic peut ressembler.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si vous avez déjà distribué du logiciel dans plus d'une langue, vous connaissez la routine. Vous choisissez une plateforme de localisation, vous la connectez à votre dépôt, puis vous passez le reste de votre temps à gérer la synchronisation. Le contenu part, les traductions reviennent, et quelque part entre les deux, les choses déraillent.

Ce surcoût, cet aller-retour constant de contenu vers et depuis votre dépôt, est la taxe que chaque équipe paie pour utiliser les outils de localisation d'aujourd'hui. Cela semble mineur jusqu'à ce que vous soyez celui qui débogue pourquoi une PR de traduction a cassé le build du site à 18 h le vendredi.

## Un design hérité d'avant Internet.

La plupart des plateformes de localisation ont été conçues autour de concepts antérieurs au flux de travail de développement moderne. Mémoires de traduction. Correspondance floue. Des traducteurs humains travaillant dans des éditeurs propriétaires, soutenus par des outils suggérant des chaînes similaires issues d'une base de données.

Ces idées avaient du sens lorsque la traduction était un processus manuel et hors ligne. Mais les entreprises ont transformé les mémoires de traduction en un mécanisme de verrouillage. Vos traductions passées, le savoir institutionnel que vous avez payé, résident sur leur plateforme. Passer à un autre fournisseur signifie recommencer à zéro, ou payer pour une export qui ne fonctionne jamais vraiment.

Le résultat est une industrie construite sur des frottements artificiels. Votre contenu quitte votre dépôt, entre dans une boîte noire et revient selon le planning de quelqu'un d'autre.

## La boucle de rétroaction brisée

Le problème est structurel : les outils de localisation externes ne peuvent pas exécuter votre pipeline CI. Ils ignorent vos linters, votre étape de build, votre vérificateur de liens ou votre schéma frontmatter. Ils repoussent le contenu traduit vers votre dépôt et espèrent le meilleur. Quand cela plante, et cela arrive, quelqu'un de l'équipe doit arrêter ce qu'il fait pour corriger les problèmes de mise en forme, la syntaxe cassée ou le marquage invalide introduit par l'outil de traduction.

Les LLMs et les expériences agenciques nous offrent de nouvelles opportunités pour repenser entièrement ces flux de travail. Un agent génère une traduction, exécute vos contrôles, détecte l'erreur et réessaye jusqu'à ce que le résultat soit valide. Ce genre de boucle de rétroaction serrée change tout.

Mais cela ne fonctionne que si le contenu reste là où il est : dans votre dépôt. À l'instant où vous le confiez à une plateforme externe, les traductions suivent un calendrier tiers, et l'intégration est rompue. Le feedback qui aurait pu être instantané prend maintenant des heures ou des jours. Le contexte qui en rendait l'utilité est disparu. Vous perdez la boucle, et avec elle, tout l'avantage que devaient procurer les flux de travail agenciques.

## Observations qui ont façonné Glossia

Ces frustrations n'ont pas conduit à Glossia d'elles-mêmes. Le projet est issu d'une expérience approfondie tant en développement qu'en localisation, ce qui a apporté de la clarté sur des problèmes difficiles à percevoir d'un seul côté. Comprendre les flux de travail linguistiques, les dynamiques humaines des équipes de traduction, et les raisons pour lesquelles les outils existants en sont arrivés là était essentiel.

Ensemble, nous sommes toujours parvenus aux mêmes observations : l'outillage de localisation a été conçu pour un monde sans LLMs, sans agents de code et sans pipelines CI. L'ensemble du modèle présumait que la traduction se déroulait en dehors du flux de développement et était réintégré par la suite. Cela avait du sens il y a dix ans. Ce n'est plus le cas.

Nous avons commencé à nous demander : **que si les agents de localisation pouvaient fonctionner de la même manière que les agents de code ?**

Nous accordons une attention de près à la façon dont [Anthropic](https://anthropic.com) réfléchit aux workflows agentic avec Claude. Le schéma de donner à un agent accès aux outils, en lui permettant de raisonner sur une tâche, de valider sa propre sortie et d'itérer lorsque quelque chose ne va pas, correspond remarquablement bien à la localisation. Un agent de traduction capable de lire vos fichiers sources, de comprendre le contexte du projet, de générer des traductions, d'exécuter votre linter et de corriger les problèmes avant d'ouvrir une pull request. Ce n'est pas une utopie. C'est le workflow que nous construisons.

## Glossia est notre cadeau pour l'industrie logicielle.

Nous avons créé Glossia car nous souhaitons que davantage de logiciels soient localisés, pas moins.

Des processus complexes et des plateformes coûteuses rendent la localisation inaccessible aux petites équipes, aux développeurs indépendants et aux projets secondaires. Si votre flux de travail de traduction nécessite un processus d'achat, une négociation de prix au mot, et un chef de projet pour coordonner les transferts, la plupart des équipes se contenteront de distribuer en anglais et s'en tireront là.

Glossia utilise des modèles auxquels vous avez déjà accès. Et il valide la sortie avec vos propres outils, pas les nôtres.

Nous pensons que la localisation devrait être aussi naturelle que l'exécution de votre suite de tests.

## Un agent d'abord, des interfaces ensuite

Au cœur de Glossia, il s'agit d'un agent. Nous commençons avec le terminal comme interface principale car c'est là que les problèmes les plus difficiles sont résolus en premier : lire vos fichiers sources, générer des traductions, exécuter vos vérifications et itérer jusqu'à ce que la sortie soit valide. C'est le même modèle que [OpenAI](https://openai.com) a suivi avec [Codex](https://openai.com/index/openai-codex/) et [Anthropic](https://anthropic.com) avec [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Vous construisez l'agent, offrez-lui un terminal et laissez-le travailler.

Mais le terminal n'est que la première interface, pas la seule. Nous savons que tous ceux qui contribuent à la qualité de la localisation ne sont pas des développeurs. Nous en parlons souvent en interne. Les personnes qui s'attachent le plus à l'exactitude de la traduction, à la nuance culturelle et au ton sont souvent des linguistes et des spécialistes du contenu qui ne pensent pas en termes de branches, de compilation ou de JSON.

C'est pourquoi nous voulons construire de nouvelles interfaces au-dessus de ce même agent. Quelque chose où un linguiste voit le contenu, le contexte et la traduction côte à côte. Ils apportent le jugement humain qu'aucun modèle ne peut remplacer. Ils affinent ce qui a besoin d'être affiné. Et l'agent gère tout le reste : les commits, la validation, l'ouverture de la pull request.

Nous n'avons pas encore toutes les réponses, et c'est intentionnel. Nous préférerions construire cela avec soin plutôt que de nous lancer précipitamment vers une UI qui raterait l'essentiel. Mais la direction est claire : Glossia doit accueillir tous ceux qui s'occupent de faire parler le logiciel dans toutes les langues.

## À suivre

Glossia est encore à ses débuts, et nous le développons en public. Si tout cela résonne avec votre approche de la localisation, gardez un œil sur le projet. Nous partagerons plus d'informations au fur et à mesure.