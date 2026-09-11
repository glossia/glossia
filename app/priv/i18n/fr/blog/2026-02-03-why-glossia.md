%{
  title:
    "La localisation était bloquée dans le passé. Nous avons créé Glossia pour la faire progresser.",
  summary:
    "Les outils de localisation traditionnels ajoutent des contraintes, perturbent la CI et vous verrouillent dans des écosystèmes de fournisseurs. Nous explorons la forme qu'un flux de travail de localisation agentic peut prendre.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si vous avez déjà déployé du logiciel dans plus d'une langue, vous connaissez la routine. Vous choisissez une plateforme de localisation, vous la connectez à votre dépôt, puis vous passez le reste de votre temps à gérer la synchronisation. Le contenu sort, les traductions rentrent, et quelque part entre les deux, les choses cassent.

Cette surcharge, l'aller-retour constant du contenu vers et depuis votre dépôt, est le coût que chaque équipe paie pour utiliser les outils de localisation d'aujourd'hui. Ça semble mineur jusqu'à ce que vous soyez celui qui débogue pourquoi un PR de traduction a cassé le build de votre site à 18 h un vendredi.

## Une conception héritée d'avant Internet

La plupart des plateformes de localisation ont été conçues autour de concepts qui précèdent le flux de travail de développement moderne. Mémoires de traduction. Appariement approximatif. Traducteurs humains travaillant dans des éditeurs propriétaires, soutenus par des outils qui suggèrent des chaînes similaires dans une base de données.

Ces idées avaient leur sens lorsque la traduction était un processus manuel, hors ligne. Mais les entreprises ont transformé les mémoires de traduction en mécanisme de verrouillage. Vos traductions passées, la connaissance institutionnelle que vous avez payée, sont hébergées dans leur plateforme. Passer à un autre fournisseur signifie recommencer à zéro, ou payer pour une exportation qui ne fonctionne jamais parfaitement.

Le résultat est une industrie fondée sur une friction artificielle. Votre contenu quitte votre dépôt, entre dans une boîte noire et revient selon les horaires d'un tiers.

## La boucle de rétroaction brisée

Le problème est structurel : les outils de localisation externes ne peuvent pas exécuter votre pipeline CI. Ils ne connaissent pas vos linters, votre étape build, votre vérificateur de liens ou votre schéma frontmatter. Ils envoient le contenu traduit vers votre dépôt et espèrent le meilleur. Lorsqu'il casse, ce qui arrive, quelqu'un dans l'équipe doit arrêter ce qu'il fait pour corriger les problèmes de formatage, la syntaxe cassée ou le balisage invalide introduit par l'outil de traduction.

Les LLM et les expériences agentiques nous offrent de nouvelles opportunités pour repenser entièrement ces flux de travail. Un agent qui génère une traduction, exécute vos contrôles, repère l'erreur et réessaie jusqu'à ce que la sortie soit valide. Ce type de boucle de rétroaction serrée change tout.

Mais cela ne fonctionne que si le contenu reste là où il vit : dans votre dépôt. Dès que vous l'envoyez sur une plateforme externe, les traductions reviennent sur un calendrier d'autrui, et l'intégration se rompt. La rétroaction qui aurait pu être instantanée prend maintenant des heures ou des jours. Le contexte qui la rendait utile a depuis longtemps disparu. Vous perdez la boucle, et avec elle, tout l'avantage que devaient offrir les flux de travail agents.

## Observations qui ont façonné Glossia

Ces frustrations ne se sont pas transformées en Glossia seule. Le projet est né d'une expérience approfondie tant en développement qu'en localisation, ce qui a apporté de la clarté aux problèmes difficiles à voir du seul côté. Comprendre les flux linguistiques, les dynamiques humaines des équipes de traduction et les raisons pour lesquelles les outils existants sont devenus ce qu'ils sont a été essentiel.

Ensemble, nous arrivions constamment aux mêmes observations : les outils de localisation ont été conçus pour un monde sans LLM, sans agents de code, ni pipelines CI. L'ensemble du modèle supposait que la traduction se produisait en dehors du flux de travail de développement et était réinjectée ultérieurement. Cela avait du sens il y a dix ans. Ce n'est plus le cas.

Nous avons commencé à nous demander : **et si les agents de localisation pouvaient fonctionner de la même manière que les agents de code ?**

Nous accordons une attention particulière à la façon dont [Anthropic](https://anthropic.com) réfléchit aux flux de travail d'agents avec Claude. Le principe consistant à donner accès à des outils à un agent, de le laisser raisonner à travers une tâche, de valider sa propre sortie et d'itérer si quelque chose ne va pas correspond remarquablement bien à la localisation. Un agent de traduction capable de lire vos fichiers sources, de comprendre le contexte du projet, de générer des traductions, de lancer votre linter et de corriger les problèmes avant de soumettre une pull request. Ce n'est pas un fantasme. C'est le flux de travail que nous construisons.

## Glossia est notre cadeau pour l'industrie du logiciel

Nous avons créé Glossia car nous souhaitons que plus de logiciels soient localisés, et non moins.

Les processus complexes et les plateformes coûteuses rendent la localisation inaccessible aux petites équipes, aux développeurs indépendants et aux projets secondaires. Si votre flux de travail de traduction nécessite un processus d'approvisionnement, une négociation de prix au mot et un chef de projet pour coordonner les transferts, la plupart des équipes publieront simplement en anglais et arrêteront là.

Glossia utilise des modèles auxquels vous avez déjà accès. Et il valide la sortie avec vos propres outils, pas les nôtres.

Nous pensons que la localisation devrait être aussi naturelle que l'exécution de votre suite de tests.

## Un agent d'abord, des interfaces ensuite.

Au cœur de Glossia réside un agent. Nous commençons par le terminal comme interface principale car c'est là où les problèmes les plus difficiles sont résolus en premier : lire vos fichiers sources, générer des traductions, exécuter vos vérifications et itérer jusqu'à ce que la sortie soit valide. C'est le même modèle que [OpenAI](https://openai.com) a suivi avec [Codex](https://openai.com/index/openai-codex/) et [Anthropic](https://anthropic.com) avec [Claude Code](https://docs.anthropic.com/en/docs/claude-code). On construit l'agent, on lui donne un terminal, et on le laisse travailler.

Mais le terminal n'est que la première interface, pas la seule. Nous savons que tous ceux qui contribuent à la qualité de la localisation ne sont pas des développeurs. Nous en discutons souvent en interne. Les personnes qui accordent le plus d'importance à la précision de la traduction, au ton et aux nuances culturelles sont souvent des linguistes et des spécialistes du contenu qui ne pensent pas en termes de branches, de compilation ou de JSON.

C'est pourquoi nous souhaitons créer de nouvelles interfaces par-dessus le même agent. Une chose où un linguiste voit le contenu, le contexte et la traduction côte à côte. Ils apportent le jugement humain qu'aucun modèle ne peut remplacer. Ils affinent ce qui a besoin d'être affiné. Et l'agent gère le reste : les commits, les validations et l'ouverture du pull request.

Nous n'avons pas toutes les réponses encore, et c'est intentionnel. Nous préférerais construire cela avec soin plutôt que de nous précipiter vers une interface qui raterait le but. Mais la direction est claire : Glossia doit accueillir tous ceux qui s'intéressent à faire en sorte que le logiciel parle chaque langue.

## À suivre

Glossia en est encore à ses débuts, et nous le construisons de manière ouverte. Si cela résonne avec votre conception de la localisation, gardez un œil sur le projet. Nous partagerons plus d'informations au fur et à mesure.