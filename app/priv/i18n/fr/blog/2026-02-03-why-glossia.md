%{
  title:
    "La localisation restait bloquée dans le passé. Nous avons construit Glossia pour la faire avancer.",
  summary:
    "Les outils de localisation traditionnels ajoutent une surcharge, rompent la CI et vous enferment dans des écosystèmes de fournisseurs. Nous explorons ce qu'un flux de travail de localisation agentique peut prendre.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si vous avez déjà distribué du logiciel dans plus d'une langue, vous connaissez la routine. Vous choisissez une plateforme de localisation, vous la connectez à votre dépôt, puis vous passez le reste de votre temps à gérer la synchronisation. Le contenu sort, les traductions reviennent, et quelque part entre les deux, les choses cassent.

Cette surcharge, ce aller-retour constant de contenu vers et depuis votre dépôt, est la taxe que chaque équipe paie pour utiliser les outils de localisation d'aujourd'hui. Cela semble mineur jusqu'à ce que vous soyez celui qui débogue pourquoi un PR de traduction a brisé la build de votre site à 18 heures un vendredi.

## Un design hérité de l'avant internet

La plupart des plateformes de localisation ont été conçues autour de concepts qui précèdent le flux de développement moderne. Mémoires de traduction. Correspondance approximative. Des traducteurs humains travaillant dans des éditeurs propriétaires, soutenus par des outils suggérant des chaînes similaires issues d'une base de données.

Ces idées avaient du sens lorsque la traduction était un processus manuel, hors ligne. Mais les entreprises ont transformé les mémoires de traduction en un mécanisme de verrouillage. Vos traductions passées, le savoir institutionnel que vous avez financé, résident à l'intérieur de leur plateforme. Migrer vers un autre fournisseur signifie recommencer à zéro, ou payer pour une export qui ne fonctionne jamais parfaitement.

Le résultat est une industrie bâtie sur une friction artificielle. Votre contenu quitte votre dépôt, entre dans une boîte noire, et revient selon le calendrier de quelqu'un d'autre.

## Le cycle de rétroaction brisé

Le problème est structurel : les outils de localisation externes ne peuvent pas exécuter votre pipeline CI. Ils ignorent vos linters, votre étape de build, votre vérificateur de liens ou votre schéma frontmatter. Ils poussent le contenu traduit dans votre dépôt et espèrent le meilleur. Quand cela casse, et cela arrive, quelqu'un de l'équipe doit arrêter ce qu'il fait pour corriger les problèmes de formatage, la syntaxe cassée ou le balisage invalide introduit par l'outil de traduction.

Les LLM et les expériences agentiques nous offrent de nouvelles opportunités pour repenser intégralement ces flux de travail. Un agent qui génère une traduction, exécute vos vérifications, repère l'erreur et réessaie tant que le résultat n'est pas valide. Ce genre de boucle de rétroaction serrée change tout.

Mais cela ne fonctionne que si le contenu reste là où il réside : dans votre dépôt. Dès que vous l'envoyez sur une plateforme externe, les traductions reviennent sur le calendrier d'un tiers, et l'intégration se rompt. Le retour d'information qui aurait pu être instantané prend désormais des heures ou des jours. Le contexte qui l'a rendu utile est loin. Vous perdez la boucle, et avec elle, tout l'avantage que les flux de travail agentiques devaient vous offrir.

## Les observations qui ont façonné Glossia

Ces frustrations ne sont pas devenues Glossia d'elles-mêmes. Le projet s'est développé à partir d'une expérience profonde tant en développement qu'en localisation, apportant de la clarté sur des problèmes que l'on ne voit pas facilement d'un seul côté. Comprendre les flux de travail linguistiques, les dynamiques humaines des équipes de traduction et les raisons pour lesquelles les outils existants sont arrivés à être ce qu'ils sont était essentiel.

Ensemble, nous sommes arrivés aux mêmes observations : les outils de localisation étaient conçus pour un monde sans LLM, sans agents de codage, ni pipelines CI. Le modèle entier supposait que la traduction était quelque chose qui se produisait en dehors du flux de travail de développement, puis était ramenée plus tard. Cela avait du sens il y a dix ans. Ce n'est plus le cas.

Nous avons commencé à nous demander : **et si les agents de localisation pouvaient fonctionner de la même manière que les agents de codage ?**

Nous accordons une attention particulière à la façon [Anthropic](https://anthropic.com) Anthropic réfléchit aux workflows agents avec Claude. Le principe de donner un accès aux outils à un agent, de lui permettre de raisonner sur une tâche, de valider sa propre sortie et d'itérer lorsque quelque chose ne va pas correspond remarquablement bien à la localisation. Un agent de traduction capable de lire vos fichiers sources, de comprendre le contexte du projet, de générer des traductions, d'exécuter votre linter et de corriger les problèmes avant de créer une pull request. Ce n'est pas de la fantasy. C'est le workflow que nous construisons.

## Glossia est notre cadeau pour l'industrie logicielle

Nous avons construit Glossia parce que nous voulons que plus de logiciels soient localisés, et non moins.

Les processus complexes et les plateformes coûteuses rendent la localisation inaccessible aux petites équipes, aux développeurs indépendants et aux projets personnels. Si votre flux de travail de traduction nécessite un processus d'approvisionnement, une négociation de prix au mot et un chef de projet pour coordonner les transferts, la plupart des équipes ne feront que livrer en anglais et laisseront les choses là.

Glossia utilise des modèles auxquels vous avez déjà accès. Et il valide la sortie avec vos propres outils, pas les nôtres.

Nous pensons que la localisation devrait être aussi naturelle que l'exécution de votre suite de tests.

## Un agent d'abord, des interfaces ensuite

Au cœur, Glossia est un agent. Nous commençons par le terminal comme interface principale car c'est là que les problèmes les plus complexes sont résolus en premier : lire vos fichiers sources, générer des traductions, exécuter vos vérifications et itérer jusqu'à ce que la sortie soit valide. C'est le même modèle que [OpenAI](https://openai.com) a suivi avec [Codex](https://openai.com/index/openai-codex/) et [Anthropic](https://anthropic.com) avec [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Vous construisez l'agent, lui donnez un terminal, et laissez-le fonctionner.

Mais le terminal n'est qu'une première interface, pas la seule. Nous savons que tous ceux qui contribuent à la qualité de la localisation ne sont pas des développeurs. Nous en parlons souvent en interne. Les personnes qui s'intéressent le plus à la précision de la traduction, au ton et aux nuances culturelles sont souvent des linguistes et des spécialistes du contenu qui ne pensent pas en termes de branches, compilation ou JSON.

C'est pourquoi nous souhaitons construire de nouvelles interfaces au-dessus du même agent. Quelque chose où un linguiste voit le contenu, le contexte et la traduction côte à côte. Ils apportent le jugement humain qu'aucun modèle ne peut remplacer. Ils affinent ce qui a besoin d'être affiné. Et l'agent gère tout le reste : le commit, la validation et l'ouverture de la pull request.

Nous n'avons pas encore toutes les réponses, et c'est intentionnel. Nous préférons construire cela de manière réfléchie plutôt que de précipiter une interface utilisateur qui rate l'essentiel. Mais la direction est claire : Glossia devrait accueillir tout le monde qui s'intéresse à faire parler le logiciel dans chaque langue.

## Restez à l'écoute

Glossia est encore à ses débuts, et nous le construisons de manière ouverte. Si cela résonne avec votre façon de concevoir la localisation, gardez un œil sur le projet. Nous partagerons davantage au fur et à mesure.