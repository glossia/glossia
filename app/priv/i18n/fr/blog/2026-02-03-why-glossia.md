%{
  title:
    "La localisation était bloquée dans le passé. Nous avons créé Glossia pour la faire avancer.",
  summary:
    "Les outils de localisation traditionnels ajoutent des surcoûts, font échouer la CI et vous verrouillent dans des écosystèmes de fournisseurs. Nous explorons à quoi peut ressembler un flux de travail de localisation agentique.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si vous avez déjà déployé du logiciel dans plus d'une langue, vous connaissez la routine. Vous choisissez une plateforme de localisation, vous la connectez à votre référentiel, puis vous passez le reste de votre temps à gérer la synchronisation. Le contenu sort, les traductions reviennent, et quelque part entre les deux, les choses cassent.

Cet overhead, l'allé-retour constant du contenu depuis et vers votre référentiel, est la taxe que chaque équipe paie en utilisant les outils de localisation d'aujourd'hui. Ça semble mineur jusqu'à ce que vous soyez celui qui débogue pourquoi une PR de traduction a cassé la construction de votre site à 18 h un vendredi.

## Une conception héritée de l'avant-internet

La plupart des plateformes de localisation ont été conçues autour de concepts qui précèdent le flux de travail de développement moderne. Mémoires de traduction. Appariement flou. Des traducteurs humains travaillant dans des éditeurs propriétaires, soutenus par des outils qui suggèrent des chaînes de caractères similaires issues d'une base de données.

Ces idées avaient du sens lorsque la traduction était un processus manuel et hors ligne. Mais les entreprises ont transformé les mémoires de traduction en mécanisme de verrouillage. Vos traductions passées, les connaissances institutionnelles pour lesquelles vous avez payé, vivent à l'intérieur de leur plateforme. Passer à un autre fournisseur signifie tout recommencer à zéro, ou payer pour une exportation qui ne fonctionne jamais vraiment.

Le résultat est une industrie construite sur une friction artificielle. Votre contenu quitte votre référentiel, entre dans une boîte noire, et revient selon le planning de quelqu'un d'autre.

## La boucle de rétroaction rompue

Le problème est structurel : les outils de localisation externes ne peuvent pas exécuter votre pipeline CI. Ils ignorent vos linters, votre étape de build, votre vérificateur de liens, ou votre schéma frontmatter. Ils poussent le contenu traduit vers votre référentiel et espèrent pour le meilleur. Lorsqu'il casse, et c'est le cas, quelqu'un de l'équipe doit arrêter ce qu'il fait pour corriger des problèmes de formatage, une syntaxe cassée ou un markup invalide introduit par l'outil de traduction.

Les LLMs et les expériences autonomes nous offrent de nouvelles opportunités pour repenser entièrement ces flux de travail. Un agent qui génère une traduction, exécute vos vérifications, voit l'erreur, et réessaie jusqu'à ce que la sortie soit valide. Ce genre de boucle de rétroaction serrée change tout.

Mais ça ne fonctionne que si le contenu reste là où il vit : dans votre référentiel. Le moment où vous l'envoyez vers une plateforme externe, les traductions reviennent selon le planning de quelqu'un d'autre, et l'intégration casse. Le feedback qui aurait pu être instantané prend maintenant des heures ou des jours. Le contexte qui le rendait utile est désormais absent. Vous perdez la boucle, et avec elle, tous les avantages que les flux de travail autonomes devaient vous offrir.

## Observations qui ont façonné Glossia

Ces frustrations ne sont pas devenues Glossia par elles-mêmes. Le projet est né d'une expérience profonde à la fois en développement et en localisation, ce qui a clarifié des problèmes difficiles à voir d'un seul côté. Comprendre les flux de travail linguistiques, les dynamiques humaines des équipes de traduction, et les raisons pour lesquelles les outils existants sont arrivés à tel point étaient essentiels.

Ensemble, nous sommes constamment arrivés aux mêmes observations : les outils de localisation étaient conçus pour un monde sans LLMs, sans agents de codage, et sans pipelines CI. Le modèle entier supposait que la traduction était quelque chose qui se produisait en dehors du flux de travail de développement et qui était réinjecté ensuite. Ça avait du sens il y a dix ans. Pas plus aujourd'hui.

Nous avons commencé à nous demander : **et si les agents de localisation pouvaient travailler de la même manière que les agents de codage ?**

Nous avons porté une attention particulière à la manière dont [Anthropic](https://anthropic.com) réfléchit aux flux de travail autonomes avec Claude. Le modèle de donner à un agent accès aux outils, de lui laisser raisonner sur une tâche, de valider sa propre sortie, et d'itérer lorsqu'un problème survient correspond remarquablement bien à la localisation. Un agent de traduction capable de lire vos fichiers sources, de comprendre le contexte du projet, de générer des traductions, d'exécuter votre linter et de corriger les problèmes avant d'ouvrir une pull request. Ce n'est pas une fantaisie. C'est le flux de travail que nous construisons.

## Glossia est notre cadeau à l'industrie du logiciel

Nous avons construit Glossia parce que nous voulons plus de logiciel localisé, pas moins.

Des processus complexes et des plateformes onéreuses rendent la localisation inaccessible aux petites équipes, aux développeurs indépendants et aux projets secondaires. Si votre flux de travail de traduction nécessite un processus d'approvisionnement, une négociation de prix au mot et un gestionnaire de projet pour coordonner les transferts, la plupart des équipes publieront simplement en anglais et laisseront filer.

Glossia utilise les modèles auxquels vous avez déjà accès. Et elle valide la sortie avec vos propres outils, pas les nôtres.

Nous pensons que la localisation devrait être aussi naturelle que l'exécution de votre suite de tests.

## Un agent d'abord, les interfaces en second

Au cœur de la plateforme, Glossia est un agent. Nous commençons par le terminal comme interface principale car c'est là où les problèmes les plus difficiles sont résolus en premier : en lisant vos fichiers sources, en générant des traductions, en exécutant vos vérifications et en itérant jusqu'à ce que la sortie soit valide. C'est le même schéma que [OpenAI](https://openai.com) a suivi avec [Codex](https://openai.com/index/openai-codex/) et [Anthropic](https://anthropic.com) avec [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Vous construisez l'agent, lui donnez un terminal, et le laissez travailler.

Mais le terminal n'est qu'une première interface, pas la seule. Nous savons que pas tous ceux qui contribuent à la qualité de la localisation sont des développeurs. Nous en discutons souvent en interne. Les personnes qui se soucient le plus de la précision des traductions, du ton et des nuances culturelles sont souvent des linguistes et des spécialistes du contenu qui ne pensent pas en termes de branches, de compilation ou de JSON.

C'est pourquoi nous souhaitons construire de nouvelles interfaces sur le même agent. Quelque chose où un linguiste voit le contenu, le contexte et la traduction côte à côte. Ils apportent le jugement humain qu'aucun modèle ne peut remplacer. Ils affinent ce qui doit être affiné. Et l'agent gère tout le reste : l'engagement, la validation et l'ouverture de la demande de fusion.

Nous n'avons pas encore toutes les réponses, et c'est intentionnel. Nous préférons construire cela de manière réfléchie plutôt que de nous précipiter vers une interface utilisateur qui manque l'essentiel. Mais l'orientation est claire : Glossia doit accueillir tout le monde qui s'intéresse à faire parler le logiciel dans toutes les langues.

## Restez à l'écoute

Glossia est en phase initiale, et nous construisons cela de manière ouverte. Si cela résonne avec votre façon de penser à la localisation, gardez un œil sur le projet. Nous partagerons davantage au fur et à mesure que nous avancerons.