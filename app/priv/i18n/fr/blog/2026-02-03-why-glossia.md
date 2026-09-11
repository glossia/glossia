%{
  title:
    "La localisation était restée figée dans le passé. Nous avons créé Glossia pour la faire avancer.",
  summary:
    "Les outils de localisation traditionnels ajoutent de la complexité, perturbent la CI et vous verrouillent dans les écosystèmes de fournisseurs. Nous explorons ce que peut être un flux de travail de localisation agentique.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si vous avez déjà diffusé du logiciel dans plus d'une langue, vous connaissez la routine. Vous choisissez une plateforme de localisation, la connectez à votre dépôt, puis vous passez le reste de votre temps à gérer la synchronisation. Le contenu sort, les traductions reviennent et quelque part entre les deux, les choses cassent.

Ce surcoût, cet aller-retour constant de contenu depuis et vers votre dépôt, est l'impôt que chaque équipe paie pour l'utilisation des outils de localisation d'aujourd'hui. Cela semble mineur jusqu'à ce que vous soyez celui qui débogue pourquoi une PR de traduction a cassé le build de votre site à 18 h un vendredi.

## Un design hérité d'avant Internet

La plupart des plateformes de localisation ont été conçues autour de concepts qui précèdent le flux de travail de développement moderne. Mémoires de traduction. Correspondance floue. Des traducteurs humains travaillant dans des éditeurs propriétaires, soutenus par des outils qui suggèrent des chaînes similaires depuis une base de données.

Ces idées avaient du sens lorsque la traduction était un processus manuel, hors ligne. Mais les entreprises ont transformé les mémoires de traduction en un mécanisme de verrouillage. Vos traductions passées, les connaissances institutionnelles que vous avez payées, vivent à l'intérieur de leur plateforme. Passer à un autre fournisseur signifie recommencer à zéro, ou payer pour une exportation qui ne fonctionne jamais vraiment.

Le résultat est une industrie bâtie sur une friction artificielle. Votre contenu quitte votre dépôt, entre dans une boîte noire et revient selon le calendrier de quelqu'un d'autre.

## La boucle de rétroaction brisée

Le problème est structurel : les outils de localisation externes ne peuvent pas exécuter votre pipeline CI. Ils ignorent vos linters, votre étape de build, votre vérificateur de liens ou votre schéma frontmatter. Ils poussent le contenu traduit vers votre dépôt et espèrent le meilleur. Lorsque cela casse, et qu'il casse, quelqu'un dans l'équipe doit arrêter ce qu'il fait pour corriger les problèmes de mise en forme, la syntaxe brisée ou le balisage invalide introduit par l'outil de traduction.

Les LLM et les expériences agentiques nous ouvrent de nouvelles opportunités pour repenser entièrement ces flux de travail. Un agent qui génère une traduction, lance vos vérifications, repère l'erreur et réessaie jusqu'à ce que la sortie soit valide. Ce type de boucle de rétroaction serrée transforme tout.

Mais cela ne fonctionne que si le contenu reste là où il vit : dans votre dépôt. Dès que vous l'envoyez vers une plateforme externe, les traductions reviennent selon le calendrier d'un tiers, et l'intégration échoue. Le retour qui aurait pu être instantané nécessite maintenant des heures ou des jours. Le contexte qui lui donnait sens est parti. Vous perdez la boucle, et avec elle, tout l'avantage que les flux agentiques étaient censés vous apporter.

## Observations qui ont façonné Glossia

Ces frustrations n'ont pas amené Glossia d'elles-mêmes. Le projet a surgi d'une expérience approfondie tant en développement qu'en localisation, ce qui a éclairé des problèmes difficiles à percevoir d'un seul côté. Comprendre les flux linguistiques, les dynamiques humaines des équipes de traduction, et les raisons pour lesquelles les outils existants sont devenus tels qu'ils l'étaient, a été essentiel.

Ensemble, nous en sommes arrivés aux mêmes constats : l'outillage de localisation était conçu pour un monde sans LLM, sans agents de codage, ni pipelines CI. Le modèle entier supposait que la traduction était une opération se déroulant en dehors du flux de développement, puis introduite plus tard. Cela avait un sens il y a dix ans. Ce n'est plus le cas.

Nous avons commencé à nous demander : **et si les agents de localisation pouvaient fonctionner de la même manière que les agents de codage ?**

Nous avons porté une attention particulière à la manière [Anthropic](https://anthropic.com) Réfléchit aux flux de travail agents avec Claude. Le schéma consistant à donner à un agent l'accès aux outils, à le laisser raisonner sur une tâche, à valider sa propre sortie et à itérer lorsque quelque chose ne va pas correspond remarquablement bien à la localisation. Un agent de traduction capable de lire vos fichiers sources, de comprendre le contexte du projet, de générer des traductions, d'exécuter votre linter et de corriger les problèmes avant d'ouvrir une pull request. Ce n'est pas une fantaisie. C'est le flux de travail que nous construisons.

## Glossia est notre cadeau pour l'industrie du logiciel.

Nous avons construit Glossia car nous voulons plus de logiciels localisés, pas moins.

Les processus complexes et les plateformes coûteuses rendent la localisation inaccessible aux petites équipes, aux développeurs indépendants et aux projets personnels. Si votre flux de travail de traduction nécessite un processus d'achat, une négociation de prix au mot et un chef de projet pour coordonner les transferts, la plupart des équipes se contenteront de lancer en anglais et d'arrêter là.

Glossia utilise des modèles auxquels vous avez déjà accès. Et il valide la sortie avec vos propres outils, pas les nôtres.

Nous pensons que la localisation devrait être aussi naturelle que l'exécution de votre suite de tests.

## Un agent d'abord, les interfaces ensuite

Au cœur de Glossia se trouve un agent. Nous commençons par le terminal comme interface principale car c'est là que les problèmes les plus complexes sont résolus en premier : lire vos fichiers sources, générer des traductions, exécuter vos vérifications et itérer jusqu'à ce que le résultat soit valide. C'est le même schéma que [OpenAI](https://openai.com) suivi avec [Codex](https://openai.com/index/openai-codex/) et [Anthropic](https://anthropic.com) avec [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Vous construisez l'agent, lui donnez un terminal, et laissez-le travailler.

Mais le terminal n'est qu'une première interface, pas la seule. Nous savons que celles qui contribuent à la qualité de la localisation ne sont pas toujours des développeurs. Nous en parlons souvent en interne. Les personnes qui s'intéressent le plus à l'exactitude des traductions, au ton et aux nuances culturelles sont souvent des linguistes et des spécialistes du contenu qui ne pensent pas en termes de branches, de compilation ou de JSON.

C'est pourquoi nous souhaitons développer de nouvelles interfaces au-dessus du même agent. Une configuration où un linguiste voit le contenu, le contexte et la traduction côte à côte. Ils apportent le jugement humain qu'aucun modèle ne peut remplacer. Ils affinent ce qui doit être affiné. Et l'agent gère tout le reste : la création des commits, la validation, l'ouverture de la pull request.

Nous n'avons pas toutes les réponses pour l'instant, et c'est intentionnel. Nous préférerions construire cela avec soin plutôt que de précipiter une interface qui rate l'essentiel. Mais la direction est claire : Glossia doit accueillir tout le monde qui se soucie de faire en sorte que le logiciel parle toutes les langues.

## À suivre

Glossia est encore à ses débuts et nous le construisons de manière transparente. Si cela résonne avec la façon dont vous envisagez la localisation, gardez un œil sur le projet. Nous partagerons davantage au fur et à mesure.