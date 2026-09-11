%{
  title:
    "La localisation était coincée dans le passé. Nous avons créé Glossia pour la faire avancer.",
  summary:
    "Les outils de localisation traditionnels ajoutent de la surcharge, cassent le CI et vous enferment dans des écosystèmes de fournisseurs. Nous explorons ce qu'un workflow de localisation agentique peut ressembler.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si vous avez déjà livré du logiciel dans plusieurs langues, vous connaissez la donne. Vous choisissez une plateforme de localisation, vous la connectez à votre dépôt, puis vous passez le reste de votre temps à gérer la synchronisation. Le contenu part, les traductions reviennent, et quelque part entre les deux, tout casse.

Ce surcoût, cet aller-retour constant du contenu vers et depuis votre dépôt, est la taxe que chaque équipe paie pour utiliser les outils de localisation actuels. Cela semble mineur tant que vous n'êtes pas celui qui débugge pourquoi une PR de traduction a cassé le build de votre site à 18 h le vendredi.

## Un design hérité d'avant Internet

La plupart des plateformes de localisation ont été conçues autour de concepts qui précèdent le flux de travail de développement moderne. Mémoires de traduction. Correspondance floue. Traducteurs humains travaillant dans des éditeurs propriétaires, appuyés par des outils suggérant des chaînes similaires issues d'une base de données.

Ces idées avaient du sens lorsque la traduction était un processus manuel et hors ligne. Mais les entreprises ont transformé les mémoires de traduction en un mécanisme d'enfermement. Vos traductions passées, les connaissances institutionnelles pour lesquelles vous avez payé, sont hébergées sur leur plateforme. Passer à un autre fournisseur signifie repartir de zéro, ou payer pour une exportation qui ne fonctionne jamais vraiment.

Le résultat est un secteur basé sur une friction artificielle. Votre contenu quitte votre dépôt, entre dans une boîte noire, et revient selon un planning imposé par autrui.

## La boucle de rétroaction rompue

Le problème est structurel : les outils de localisation externes ne peuvent pas exécuter votre pipeline CI. Ils ignorent vos linters, votre étape de build, votre vérificateur de liens ou votre schéma frontmatter. Ils envoient le contenu traduit de nouveau vers votre dépôt et espèrent le meilleur. Lorsque cela échoue, et que cela arrive, quelqu'un de l'équipe doit arrêter ce qu'il fait pour corriger des problèmes de mise en forme, une syntaxe cassée ou un balisage invalide introduits par l'outil de traduction.

Les LLM et les expériences agentic nous ouvrent de nouvelles opportunités pour repenser ces flux de travail entièrement. Un agent qui génère une traduction, exécute vos contrôles, voit l'erreur et réessaie jusqu'à ce que la sortie soit valide. Ce type de boucle de rétroaction serrée change tout.

Mais cela ne fonctionne que si le contenu reste là où il se trouve : dans votre dépôt. Dès que vous l'envoyez sur une plateforme externe, les traductions reviennent sur les délais d'un tiers, et l'intégration échoue. Les retours qui auraient pu être instantanés prennent désormais des heures ou des jours. Le contexte qui lui donnait son utilité a disparu. Vous perdez la boucle, et avec elle, tous les avantages que les flux agentic étaient censés vous offrir.

## Observations qui ont façonné Glossia

Ces frustrations ne sont pas devenues Glossia de leur propre chef. Le projet est issu d'une expérience approfondie tant en développement qu'en localisation, ce qui a apporté de la clarté à des problèmes difficiles à voir d'un seul côté. Comprendre les flux linguistiques, la dynamique humaine des équipes de traduction, et les raisons pour lesquelles les outils existants sont devenus ce qu'ils sont, était essentiel.

Ensemble, nous continuions d'arriver aux mêmes observations : l'outillage de localisation a été conçu pour un monde sans LLM, sans agents de codage, et sans pipelines CI. Le modèle entier partait du principe que la traduction se déroulait en dehors du flux de développement et était réintroduite plus tard. Cela avait du sens il y a dix ans. Ce n'est plus le cas.

Nous avons commencé à demander : **et si les agents de localisation pouvaient fonctionner de la même manière que les agents de codage ?**

Nous accordons une attention particulière à la façon dont [Anthropic](https://anthropic.com) pense aux workflows d'agents avec Claude. Le modèle de donner un agent accès à des outils, de lui laisser raisonner sur une tâche, de valider sa propre sortie, et d'itérer lorsque quelque chose ne va pas correspond parfaitement à la localisation. Un agent de traduction capable de lire vos fichiers sources, de comprendre le contexte du projet, de générer des traductions, d'exécuter votre linter et de corriger les problèmes avant de créer une pull request. Ce n'est pas une fantasie. C'est le flux de travail que nous construisons.

## Glossia est notre cadeau pour l'industrie logicielle

Nous avons construit Glossia parce que nous voulons que davantage de logiciels soient localisés, et non moins.

Les processus complexes et les plateformes coûteuses rendent la localisation inaccessible aux petites équipes, aux développeurs indépendants et aux projets secondaires. Si votre flux de travail de traduction nécessite une procédure d'achat, une négociation de prix au mot et un chef de projet pour coordonner les transferts, la plupart des équipes publieront tout simplement en anglais et en ont fini là.

Glossia utilise des modèles auxquels vous avez déjà accès. Et il valide les sorties avec vos propres outils, pas les nôtres.

Nous pensons que la localisation devrait être aussi naturelle que d'exécuter votre suite de tests.

## Un agent d'abord, interfaces ensuite

Au cœur, Glossia est un agent. Nous commençons avec le terminal comme interface principale, car c'est là que les problèmes les plus difficiles sont résolus en premier : lire vos fichiers sources, générer des traductions, exécuter vos contrôles et itérer jusqu'à ce que la sortie soit valide. C'est le même modèle que [OpenAI](https://openai.com) a suivi avec [Codex](https://openai.com/index/openai-codex/) et [Anthropic](https://anthropic.com) avec [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Vous construisez l'agent, lui donnez un terminal, et laissez-le travailler.

Mais le terminal n'est qu'une première interface, pas la seule. Nous savons que tous ceux qui contribuent à la qualité de localisation ne sont pas des développeurs. Nous en parlons souvent en interne. Les personnes qui s'attachent le plus à la précision de la traduction, au ton et aux nuances culturelles sont souvent des linguistes et des spécialistes du contenu qui ne pensent pas en termes de branches, de compilation ou de JSON.

C'est pourquoi nous souhaitons construire de nouvelles interfaces au-dessus du même agent. Quelque chose où un linguiste voit le contenu, le contexte et la traduction côte à côte. Ils apportent le jugement humain qu'aucun modèle ne peut remplacer. Ils affinent ce qui nécessite des ajustements. Et l'agent gère tout le reste : les commits, la validation et l'ouverture du pull request.

Nous n'avons pas encore toutes les réponses, et c'est intentionnel. Nous préférerions construire cela avec réflexion plutôt que de foncer dans une interface utilisateur qui rate l'essentiel. Mais la direction est claire : Glossia devrait accueillir tout le monde qui s'intéresse à faire en sorte que le logiciel parle toutes les langues.

## À suivre

Glossia en est encore à ses débuts, et nous le développons ouvertement. Si cela résonne avec la manière dont vous abordez la localisation, gardez un œil sur le projet. Nous partagerons davantage au fur et à mesure.