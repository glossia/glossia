%{
  title:
    "La localisation était restée figée dans le passé. Nous avons construit Glossia pour la faire avancer.",
  summary:
    "Les outils de localisation traditionnels ajoutent une surcharge, brisent la CI et vous enferment dans des écosystèmes de fournisseurs. Nous explorons à quoi ressemblerait un flux de travail de localisation agentique.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si vous avez déjà déployé du logiciel dans plus d'une langue, vous connaissez la procédure. Vous choisissez une plateforme de localisation, la connectez à votre dépôt, puis passez le reste de votre temps à gérer la synchronisation. Le contenu sort, les traductions reviennent, et quelque part entre les deux, les choses cassent.

Ce surcoût, l'aller-retour constant du contenu de et vers votre dépôt, est la taxe que chaque équipe paie pour utiliser les outils de localisation d'aujourd'hui. Ça paraît mineur jusqu'à ce que ce soit vous qui débogiez pourquoi une PR de traduction a cassé la construction de votre site à 18 h un vendredi.

## Un design hérité de l'avant Internet.

La plupart des plateformes de localisation ont été conçues autour de concepts qui précèdent le flux de travail de développement moderne. Mémoires de traduction. Appariement flou. Des traducteurs humains travaillant dans des éditeurs propriétaires, assistés par des outils suggérant des chaînes de caractères similaires issues d'une base de données.

Ces idées avaient du sens quand la traduction était un processus manuel, hors ligne. Mais les entreprises ont transformé les mémoires de traduction en un mécanisme de verrouillage. Vos traductions passées, le savoir institutionnel pour lequel vous avez payé, vivent dans leur plateforme. Passer à un autre prestataire signifie tout recommencer, ou payer pour une exportation qui ne fonctionne jamais vraiment.

Le résultat est une industrie construite sur une friction artificielle. Votre contenu quitte votre dépôt, entre dans une boîte noire, et revient selon le planning de quelqu'un d'autre.

## La boucle de rétroaction cassée.

Le problème est structurel : les outils de localisation externes ne peuvent pas exécuter votre pipeline CI. Ils ignorent vos linters, votre étape de construction, votre vérificateur de liens, ou votre schéma frontmatter. Ils poussent le contenu traduit de retour vers votre dépôt et espèrent le meilleur. Quand ça casse, et ça le fait bien souvent, quelqu'un de l'équipe doit arrêter ce qu'il fait pour corriger les problèmes de formatage, la syntaxe cassée, ou le balisage invalide que l'outil de traduction a introduit.

Les LLM et les expériences agentiques nous offrent de nouvelles opportunités pour repenser ces flux de travail entièrement. Un agent qui génère une traduction, exécute vos contrôles, repère l'erreur et réessaie jusqu'à ce que la sortie soit valide. Ce type de boucle de rétroaction serrée change tout.

Mais cela ne fonctionne que si le contenu reste là où il réside : dans votre dépôt. Dès que vous l'envoyez sur une plateforme externe, les traductions reviennent sur un calendrier tiers, et l'intégration se rompt. La rétroaction qui aurait pu être instantanée prend maintenant des heures ou des jours. Le contexte qui la rendait utile est depuis longtemps perdu. Vous perdez la boucle, et avec elle, tout l'avantage que les flux de travail agentiques devaient vous offrir.

## Observations ayant façonné Glossia

Ces frustrations n'ont pas donné naissance à Glossia d'elles-mêmes. Le projet est issu d'une expérience approfondie à la fois dans le développement et dans la localisation, ce qui a apporté une clarté aux problèmes difficiles à voir d'un seul côté. Comprendre les flux de travail linguistiques, les dynamiques humaines des équipes de traduction, et les raisons pour lesquelles les outils existants en sont arrivés là était essentiel.

Ensemble, nous sommes parvenus aux mêmes observations : les outils de localisation ont été conçus pour un monde sans LLM, sans agents de codage, et sans pipelines CI. Tout le modèle supposait que la traduction était une activité se déroulant en dehors du flux de développement et qui était réintégrée ultérieurement. Cela avait du sens il y a dix ans. Ce n'est plus le cas.

Nous avons commencé à nous demander : **et si les agents de localisation pouvaient fonctionner de la même manière que les agents de codage ?**

Nous accordons une attention particulière à la façon dont [Anthropic](https://anthropic.com) réfléchit aux workflows agentiques avec Claude. L'approche consistant à donner à un agent l'accès à des outils, le laisser raisonner sur une tâche, valider sa propre sortie et itérer lorsqu'une anomalie se présente correspond remarquablement bien à la localisation. Un agent de traduction capable de lire vos fichiers sources, comprendre le contexte du projet, générer des traductions, lancer votre linter et corriger les problèmes avant de créer une pull request. Ce n'est pas une fantaisie. C'est le workflow que nous construisons.

## Glossia est notre cadeau à l'industrie du logiciel

Nous avons construit Glossia car nous souhaitons que davantage de logiciels soient localisés, et non moins.

Les processus complexes et les plateformes onéreuses rendent la localisation inaccessible aux petites équipes, aux développeurs indépendants et aux projets secondaires. Si votre flux de travail de traduction nécessite un processus d'approvisionnement, une négociation de prix au mot et un chef de projet pour coordonner les transferts, la plupart des équipes publieront simplement en anglais et la journée sera faite.

Glossia utilise des modèles auxquels vous avez déjà accès. Il valide également les sorties avec vos propres outils, pas les nôtres.

Nous pensons que la localisation devrait être aussi naturelle que l'exécution de votre suite de tests.

## D'abord un agent, ensuite des interfaces.

Au cœur de Glossia se trouve un agent. Nous commençons par le terminal comme interface principale car c'est là que les problèmes les plus difficiles sont résolus en premier : lire vos fichiers sources, générer des traductions, exécuter vos vérifications, et itérer jusqu'à ce que la sortie soit valide. C'est le même schéma que [OpenAI](https://openai.com) a suivi avec [Codex](https://openai.com/index/openai-codex/) et [Anthropic](https://anthropic.com) avec [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Construisez l'agent, donnez-lui un terminal, et laissez-le travailler.

Mais le terminal n'est que la première interface, pas la seule. Nous savons que pas tous ceux qui contribuent à la qualité de la localisation sont des développeurs. Nous en parlons souvent en interne. Les personnes qui s'intéressent le plus à la précision de la traduction, au ton et aux nuances culturelles sont souvent des linguistes et des spécialistes du contenu qui ne pensent pas en termes de branches, de compilation ou de JSON.

C'est pourquoi nous souhaitons construire de nouvelles interfaces au-dessus du même agent. Quelque chose où un linguiste voit le contenu, le contexte et la traduction côte à côte. Ils apportent le jugement humain qu'aucun modèle ne peut remplacer. Ils affinent ce qui doit être affiné. Et l'agent gère tout le reste : les commits, la validation, l'ouverture de la pull request.

Nous n'avons pas encore toutes les réponses, et c'est intentionnel. Nous préférerions plutôt construire cela de manière réfléchie que de nous précipiter vers une interface qui rate l'essentiel. Mais la direction est claire : Glossia devrait accueillir tous ceux qui s'intéressent à faire parler le logiciel dans toutes les langues.

## Restez à l'écoute

Glossia en est encore à ses débuts, et nous le construisons en public. Si cela résonne avec votre vision de la localisation, gardez un œil sur le projet. Nous partagerons plus au fur et à mesure.