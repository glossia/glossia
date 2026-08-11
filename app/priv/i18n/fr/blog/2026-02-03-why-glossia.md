%{
  title: "La localisation était restée figée dans le passé. Nous avons créé Glossia pour la faire progresser.",
  summary: "Les outils de localisation traditionnels alourdissent les processus, perturbent la CI et vous enferment dans des écosystèmes propriétaires. Nous explorons ce que pourrait être un flux de travail de localisation agentique.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si vous avez déjà livré un logiciel dans plusieurs langues, vous connaissez le processus. Vous choisissez une plateforme de localisation, vous la connectez à votre dépôt, puis vous passez le reste de votre temps à gérer la synchronisation. Le contenu est envoyé, les traductions reviennent et, entre les deux, des problèmes surviennent.

Cette charge de travail, liée aux transferts constants de contenu depuis et vers votre dépôt, est le prix que chaque équipe paie pour utiliser les outils de localisation actuels. Cela semble anodin jusqu’au jour où vous devez comprendre pourquoi une pull request de traduction a interrompu la compilation de votre site à 18 h un vendredi.

## Une conception héritée d’avant Internet

La plupart des plateformes de localisation reposent sur des concepts antérieurs aux processus de développement modernes. Mémoires de traduction. Correspondances approximatives. Traducteurs humains travaillant dans des éditeurs propriétaires, assistés par des outils qui suggèrent des chaînes similaires issues d’une base de données.

Ces concepts étaient pertinents lorsque la traduction constituait un processus manuel et hors ligne. Mais les entreprises ont transformé les mémoires de traduction en mécanisme de verrouillage propriétaire. Vos traductions antérieures, ces connaissances institutionnelles que vous avez financées, restent enfermées dans leur plateforme. Passer à un autre fournisseur signifie repartir de zéro ou payer pour une exportation qui ne fonctionne jamais tout à fait.

Il en résulte un secteur fondé sur des obstacles artificiels. Votre contenu quitte votre dépôt, entre dans une boîte noire et revient selon le calendrier d’un tiers.

## Une boucle de rétroaction défaillante

Le problème est structurel : les outils de localisation externes ne peuvent pas exécuter votre pipeline d’intégration continue. Ils ne connaissent ni vos analyseurs de code, ni votre étape de compilation, ni votre vérificateur de liens, ni le schéma de vos métadonnées d’en-tête. Ils renvoient le contenu traduit vers votre dépôt et espèrent que tout fonctionnera. Lorsqu’un problème survient, ce qui arrive inévitablement, un membre de l’équipe doit interrompre son travail pour corriger les problèmes de mise en forme, la syntaxe incorrecte ou le balisage non valide introduits par l’outil de traduction.

Les grands modèles de langage et les expériences agentiques nous offrent de nouvelles possibilités pour repenser entièrement ces processus. Un agent peut générer une traduction, exécuter vos vérifications, identifier l’erreur et recommencer jusqu’à obtenir un résultat valide. Une boucle de rétroaction aussi étroite change tout.

Mais cela ne fonctionne que si le contenu reste là où il réside : dans votre dépôt. Dès que vous l’envoyez à une plateforme externe, les traductions reviennent selon le calendrier d’un tiers et l’intégration se rompt. La rétroaction qui aurait pu être instantanée prend alors des heures ou des jours. Le contexte qui la rendait utile a depuis longtemps disparu. Vous perdez la boucle et, avec elle, tout l’avantage que les processus agentiques étaient censés vous apporter.

## Les constats qui ont façonné Glossia

Ces frustrations ne se sont pas transformées d’elles-mêmes en Glossia. Le projet est né d’une solide expérience du développement et de la localisation, qui a permis de clarifier des problèmes difficiles à percevoir depuis un seul de ces domaines. Il était essentiel de comprendre les processus linguistiques, les dynamiques humaines des équipes de traduction et les raisons pour lesquelles les outils existants ont évolué de cette manière.

Ensemble, nous revenions toujours aux mêmes constats : les outils de localisation ont été conçus pour un monde sans grands modèles de langage, sans agents de programmation et sans pipelines d’intégration continue. Le modèle entier reposait sur l’idée que la traduction intervenait en dehors du processus de développement, avant d’y être réintégrée. Cela avait du sens il y a dix ans. Ce n’est plus le cas.

Nous avons commencé à nous demander : **et si les agents de localisation pouvaient travailler comme les agents de programmation ?**

Nous suivons attentivement la manière dont [Anthropic](https://anthropic.com) conçoit les processus agentiques avec Claude. Donner à un agent l’accès à des outils, le laisser raisonner pour accomplir une tâche, valider son propre résultat et recommencer lorsqu’un élément est incorrect correspond remarquablement bien aux besoins de la localisation. Un agent de traduction capable de lire vos fichiers sources, de comprendre le contexte du projet, de générer des traductions, d’exécuter votre analyseur de code et de corriger les problèmes avant d’ouvrir une pull request. Ce n’est pas une vision irréaliste. C’est le processus que nous construisons.

## Glossia est notre contribution à l’industrie du logiciel

Nous avons créé Glossia parce que nous voulons que davantage de logiciels soient localisés, pas moins.

Les processus complexes et les plateformes coûteuses rendent la localisation inaccessible aux petites équipes, aux développeurs indépendants et aux projets personnels. Si votre processus de traduction nécessite une procédure d’achat, une négociation tarifaire au mot et un chef de projet pour coordonner les transmissions, la plupart des équipes se contenteront de publier leur logiciel en anglais.

Glossia utilise des modèles auxquels vous avez déjà accès. Et valide les résultats avec vos propres outils, pas les nôtres.

Nous pensons que la localisation devrait être aussi naturelle que l’exécution de votre suite de tests.

## L’agent d’abord, les interfaces ensuite

Glossia est avant tout un agent. Nous commençons par le terminal comme interface principale, car c’est là que les problèmes les plus difficiles sont résolus en premier : lire vos fichiers sources, générer des traductions, exécuter vos vérifications et effectuer des itérations jusqu’à ce que le résultat soit valide. C’est la même approche qu’ont suivie [OpenAI](https://openai.com) avec [Codex](https://openai.com/index/openai-codex/), et [Anthropic](https://anthropic.com) avec [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Vous développez l’agent, lui donnez accès à un terminal et le laissez travailler.

Mais le terminal n’est que la première interface, pas la seule. Nous savons que toutes les personnes qui contribuent à la qualité de la localisation ne sont pas des développeurs. Nous en parlons souvent en interne. Les personnes les plus attentives à l’exactitude des traductions, au ton et aux nuances culturelles sont souvent des linguistes et des spécialistes du contenu qui ne raisonnent pas en termes de branches, de compilation ou de JSON.

C’est pourquoi nous voulons créer de nouvelles interfaces reposant sur le même agent. Une interface dans laquelle un linguiste voit côte à côte le contenu, le contexte et la traduction. Il apporte le discernement humain qu’aucun modèle ne peut remplacer. Il affine ce qui doit l’être. Et l’agent s’occupe de tout le reste : enregistrer les modifications, les valider et ouvrir la demande d’intégration.

Nous n’avons pas encore toutes les réponses, et c’est intentionnel. Nous préférons construire cette solution avec discernement plutôt que de nous précipiter vers une interface utilisateur qui passerait à côté de l’essentiel. Mais l’orientation est claire : Glossia doit accueillir toutes les personnes qui souhaitent permettre aux logiciels de parler toutes les langues.

## Restez informé

Glossia n’en est encore qu’à ses débuts, et nous le développons ouvertement. Si cette vision correspond à votre conception de la localisation, suivez le projet. Nous communiquerons davantage au fil de son évolution.