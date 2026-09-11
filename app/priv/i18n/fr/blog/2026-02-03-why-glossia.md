%{
  title:
    "La localisation était figée dans le passé. Nous avons créé Glossia pour la faire avancer.",
  summary:
    "Les outils de localisation traditionnels ajoutent des surcoûts, brisent la CI et verrouillent les utilisateurs dans les écosystèmes des fournisseurs. Nous explorons ce qu'un workflow de localisation piloté par des agents peut devenir.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si vous avez déjà déployé du logiciel dans plus d'une langue, vous connaissez la routine. Vous choisissez une plateforme de localisation, la connectez à votre dépôt, puis passez le reste de votre temps à gérer la synchronisation. Le contenu sort, les traductions reviennent, et quelque part entre les deux, les choses cassent.

Ce surcoût, cet aller-retour constant du contenu vers et depuis votre dépôt, est le prix que chaque équipe paie en utilisant les outils de localisation d'aujourd'hui. Ça semble mineur tant que vous n'êtes pas celui qui débogue pourquoi une PR de traduction a cassé le build de votre site à 18 h un vendredi.

## Un design hérité de l'avant-internet

La plupart des plateformes de localisation ont été conçues autour de concepts antérieurs au flux de travail de développement moderne. Mémoires de traduction. Appariement flou. Des traducteurs humains travaillant dans des éditeurs propriétaires, soutenus par des outils qui suggèrent des chaînes similaires issues d'une base de données.

Ces idées avaient du sens lorsque la traduction était un processus manuel, hors ligne. Mais les entreprises ont transformé les mémoires de traduction en un mécanisme de verrouillage. Vos traductions passées, la connaissance institutionnelle que vous avez payée, vivent à l'intérieur de leur plateforme. Changer de prestataire signifie partir de zéro, ou payer pour une exportation qui ne fonctionne jamais vraiment.

Le résultat est une industrie construite sur une friction artificielle. Votre contenu quitte votre dépôt, entre dans une boîte noire, et revient selon le planning de quelqu'un d'autre.

## La boucle de rétroaction cassée

Le problème est structurel : les outils de localisation externes ne peuvent pas exécuter votre pipeline CI. Ils ignorent vos linters, votre étape de build, votre vérificateur de liens ou votre schéma frontmatter. Ils poussent le contenu traduit vers votre dépôt et espèrent le meilleur. Lorsqu'il échoue, et que c'est le cas, un membre de l'équipe doit arrêter ce qu'il fait pour corriger les problèmes de formatage, la syntaxe cassée ou le balisage invalide introduit par l'outil de traduction.

Les LLM et les expériences agenciques nous offrent de nouvelles opportunités pour repenser entièrement ces flux de travail. Un agent qui génère une traduction, exécute vos vérifications, détecte l'erreur et réessaie jusqu'à ce que la sortie soit valide. Ce genre de boucle de rétroaction serrée change tout.

Mais cela ne fonctionne que si le contenu reste là où il réside : dans votre dépôt. Dès que vous le soumettez à une plateforme externe, les traductions reviennent dans le calendrier d'un tiers, et l'intégration se brise. La rétroaction qui aurait pu être instantanée prend désormais des heures ou des jours. Le contexte qui le rendait utile est déjà disparu. Vous perdez la boucle, et avec elle, tout l'avantage que ces flux de travail agenciques devaient vous apporter.

## Observations qui ont façonné Glossia

Ces frustrations n'ont pas mené à Glossia toutes seules. Le projet est né d'une profonde expérience à la fois en développement et en localisation, apportant clarté à des problèmes difficiles à voir d'un seul côté. Comprendre les flux de travail linguistiques, la dynamique humaine des équipes de traduction, et les raisons pour lesquelles les outils existants se sont trouvés tels qu'ils le sont était essentiel.

Ensemble, nous avons toujours abouti aux mêmes observations : les outils de localisation étaient conçus pour un monde sans LLM, sans agents de codage, et sans pipelines CI. Ce modèle entier supposait que la traduction était quelque chose qui se passait en dehors du flux de développement et qui était repoussé plus tarde. Cela avait du sens il y a dix ans. Ce n'est plus le cas.

Nous avons commencé à nous poser la question : **et si les agents de localisation pouvaient fonctionner de la même manière que les agents de codage ?**

Nous avons prêté une attention particulière à la manière dont [Anthropic](https://anthropic.com) réfléchit aux flux de travail agentic avec Claude. Le schéma consistant à donner à un agent l'accès aux outils, à le laisser raisonner sur la tâche, à valider sa propre sortie et à itérer si quelque chose ne va pas, correspond remarquablement bien à la localisation. Un agent de traduction capable de lire vos fichiers sources, de comprendre le contexte du projet, de générer des traductions, d'exécuter votre linter et de corriger les problèmes avant d'ouvrir une pull request. Ce n'est pas une fantasie. C'est le flux de travail que nous construisons.

## Glossia est notre cadeau pour l'industrie du logiciel.

Nous avons construit Glossia parce que nous voulons que davantage de logiciels soient localisés, et non moins.

Les processus complexes et les plateformes onéreuses rendent la localisation inaccessible aux petites équipes, aux développeurs indépendants et aux projets personnels. Si votre flux de travail de traduction nécessiste un processus d'approvisionnement, une négociation de prix au mot, et un chef de projet pour coordonner les transferts, la plupart des équipes publieront tout simplement en anglais et s'arrêteront là.

Glossia utilise des modèles auxquels vous avez déjà accès. Et elle valide les résultats avec vos propres outils, pas les nôtres.

Nous pensons que la localisation devrait être aussi naturelle que l'exécution de votre suite de tests.

## Un agent d'abord, des interfaces ensuite.

Au cœur, Glossia est un agent. Nous commençons par le terminal comme interface principale car c'est là que les problèmes les plus difficiles sont résolus en premier : lire vos fichiers sources, générer des traductions, exécuter vos vérifications et itérer jusqu'à ce que la sortie soit valide. C'est le même modèle que [OpenAI](https://openai.com) a suivi avec [Codex](https://openai.com/index/openai-codex/) et [Anthropic](https://anthropic.com) avec [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Vous construisez l'agent, lui offrez un terminal, et laissez-le travailler.

Mais le terminal n'est que la première interface, pas la seule. Nous savons que pas tout le monde qui contribue à la qualité de la localisation est un développeur. Nous en parlons souvent en interne. Les personnes qui s'attachent le plus à la précision de la traduction, du ton et de la nuance culturelle sont souvent des linguistes et des spécialistes du contenu qui ne pensent pas en termes de branches, de compilation ou de JSON.

C'est pourquoi nous souhaitons créer de nouvelles interfaces sur la base du même agent. Quelque chose où un linguiste voit le contenu, le contexte et la traduction côte à côte. Ils apportent le jugement humain qu'aucun modèle ne peut remplacer. Ils affinent ce qui mérite d'être affiné. Et l'agent gère tout le reste : les commits, la validation, l'ouverture de la pull request.

Nous n'avons pas encore toutes les réponses, et c'est intentionnel. Nous préférerions construire cela soigneusement plutôt que de précipiter une interface utilisateur qui rate le but. Mais la direction est claire : Glossia devrait accueillir tous ceux qui s'intéressent à faire en sorte que le logiciel parle toutes les langues.

## À suivre

Glossia est encore à ses débuts, et nous le construisons en public. Si cela résonne avec votre vision de la localisation, gardez un œil sur le projet. Nous partagerons davantage au fur et à mesure.