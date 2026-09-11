%{
  title:
    "La localisation était restée figée dans le passé. Nous avons construit Glossia pour la faire avancer.",
  summary:
    "Les outils de localisation traditionnels ajoutent une surcharge, perturbent la CI et verrouillent les utilisateurs dans des écosystèmes de fournisseurs. Nous explorons ce à quoi pourrait ressembler un flux de travail de localisation agentique.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si vous avez déjà déployé du logiciel en plus d'une langue, vous connaissez la routine. Vous choisissez une plateforme de localisation, vous la connectez à votre dépôt, et vous passez le reste de votre temps à gérer la synchronisation. Le contenu sort, les traductions rentrent, et quelque part entre les deux, les choses cassent.

Ce surcoût, ce trajet aller-retour constant de contenu entre votre dépôt et lui, est la taxe que chaque équipe paie pour utiliser les outils de localisation actuels. Cela semble mineur jusqu'à ce que vous soyez celui qui doit déboguer pourquoi une PR de traduction a cassé la build de votre site à 18 h le vendredi.

## Une conception héritée de l'avant-internet.

La plupart des plateformes de localisation ont été conçues autour de concepts antérieurs au flux de travail de développement moderne. Les mémoires de traduction. L'appariement flou. Des traducteurs humains travaillant à l'intérieur d'éditeurs propriétaires, appuyés par des outils qui suggèrent des chaînes similaires issues d'une base de données.

Ces idées avaient du sens lorsque la traduction était un processus manuel et hors ligne. Mais les entreprises ont transformé les mémoires de traduction en un mécanisme de verrouillage. Vos traductions passées, le savoir institutionnel que vous avez payé, vivent à l'intérieur de leur plateforme. Basculer vers un autre fournisseur signifie recommencer à zéro ou payer pour une exportation qui ne fonctionne jamais parfaitement.

Le résultat est une industrie construite sur une friction artificielle. Votre contenu quitte votre dépôt, entre dans une boîte noire, et revient selon le planning d'autrui.

## La boucle de rétroaction brisée

Le problème est structurel : les outils de localisation externes ne peuvent pas exécuter votre pipeline CI. Ils ignorent vos linters, votre étape de build, votre vérificateur de liens ou votre schéma frontmatter. Ils poussent le contenu traduit vers votre dépôt et espèrent le meilleur. Lorsque cela casse, et cela arrive, quelqu'un de l'équipe doit arrêter ce qu'il fait pour corriger les problèmes de formatage, la syntaxe brisée ou le balisage invalide introduit par l'outil de traduction.

Les LLMs et les expériences agentiques nous offrent de nouvelles opportunités pour repenser ces flux de travail entièrement. Un agent qui génère une traduction, exécute vos vérifications, détecte l'erreur et réessaie tant que la sortie n'est pas valide. Ce genre de boucle de rétroaction serrée change tout.

Mais cela ne fonctionne que si le contenu reste là où il se trouve : dans votre dépôt. Dès que vous l'envoyez sur une plateforme externe, les traductions reviennent dans un calendrier tiers, et l'intégration se rompt. La rétroaction qui aurait pu être instantanée prend désormais des heures ou des jours. Le contexte qui la rendait utile est totalement disparu. Vous perdez la boucle, et avec elle, l'ensemble des avantages que les flux de travail agentiques devaient vous offrir.

## Les observations qui ont façonné Glossia

Ces frustrations ne se sont pas transformées en Glossia d'elles-mêmes. Le projet est issu d'une expérience approfondie, tant en développement qu'en localisation, qui a apporté de la clarté à des problèmes difficiles à voir du seul côté. Comprendre les flux de travail linguistiques, les dynamiques humaines des équipes de traduction, et les raisons pour lesquelles les outils existants en sont arrivés là était essentiel.

Ensemble, nous parvenions toujours aux mêmes observations : l'outillage de localisation a été conçu pour un monde sans LLMs, sans agents de code, ni pipelines CI. Le modèle entier supposait que la traduction se déroulait en dehors du flux de travail de développement et était ensuite réintroduit. Cela avait du sens il y a dix ans. Ce n'est plus le cas.

Nous avons commencé à nous demander : **et si les agents de localisation pouvaient fonctionner de la même manière que les agents de code ?**

Nous avons prêté une attention particulière à la façon dont [Anthropic](https://anthropic.com) réfléchit aux flux de travail d'agents avec Claude. Le modèle consistant à donner un accès aux outils à un agent, à le laisser raisonner sur une tâche, à valider sa propre sortie et à itérer lorsqu'il y a un souci correspond étonnamment bien à la localisation. Un agent de traduction capable de lire vos fichiers sources, de comprendre le contexte du projet, de générer des traductions, d'exécuter votre linter et de corriger les problèmes avant d'ouvrir une pull request. Ce n'est pas une fantaisie. C'est le flux de travail que nous construisons.

## Glossia est notre cadeau à l'industrie logicielle

Nous avons construit Glossia car nous voulons que plus de logiciels soient localisés, et non moins.

Des processus complexes et des plateformes coûteuses rendent la localisation inaccessible aux petites équipes, aux développeurs indépendants et aux projets personnels. Si votre flux de traduction nécessite un processus d'achat, une négociation de tarifs par mot et un chef de projet pour coordonner les transferts, la plupart des équipes se contentent de publier en anglais et d'arrêter là.

Glossia utilise des modèles auxquels vous avez déjà accès. Il valide également les résultats avec vos propres outils, pas les nôtres.

Nous pensons que la localisation devrait être aussi naturelle que l'exécution de votre suite de tests.

## Un agent en premier, les interfaces en second.

À son cœur, Glossia est un agent. Nous commençons avec le terminal comme interface principale, car c'est là que les problèmes les plus complexes sont résolus en premier : lire vos fichiers sources, générer des traductions, lancer vos vérifications et itérer jusqu'à ce que les sorties soient valides. C'est le même modèle que [OpenAI](https://openai.com) suivi avec [Codex](https://openai.com/index/openai-codex/) et [Anthropic](https://anthropic.com) avec [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Construisez l'agent, donnez-lui un terminal, et laissez-le travailler.

Mais le terminal n'est qu'une première interface, pas la seule. Nous savons que tous ceux qui contribuent à la qualité de la localisation ne sont pas des développeurs. Nous en parlons souvent en interne. Ceux qui s'occupent le plus de l'exactitude de la traduction, du ton et de la nuance culturelle sont souvent des linguistes et des spécialistes du contenu qui ne pensent pas en termes de branches, de compilation ou de JSON.

C'est pourquoi nous souhaitons créer de nouvelles interfaces au-dessus du même agent. Quelque chose où un linguiste voit le contenu, le contexte et la traduction côte à côte. Ils apportent le jugement humain qu'aucun modèle ne peut remplacer. Ils affinent ce qui nécessite d'être affiné. Et l'agent gère tout le reste : commits, validation, ouverture du pull request.

Nous n'avons pas encore toutes les réponses, et c'est intentionnel. Nous préférions plutôt construire cela avec réflexion que de précipiter une interface utilisateur qui rate l'essentiel. Mais la direction est claire : Glossia devrait accueillir tous ceux qui s'intéressent à faire parler les logiciels dans toutes les langues.

## Restez à l'écoute

Glossia est encore à ses débuts, et nous le construisons en public. Si cela résonne avec votre vision de la localisation, gardez un œil sur le projet. Nous partagerons davantage au fur et à mesure.