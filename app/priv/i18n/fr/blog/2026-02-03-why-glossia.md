%{
  title:
    "La localisation était restée bloquée dans le passé. Nous avons créé Glossia pour la faire avancer.",
  summary:
    "Les outils de localisation traditionnels ajoutent de la surcharge, perturbent CI et vous enferment dans des écosystèmes d'éditeurs. Nous explorons à quoi peut ressembler un flux de travail de localisation agentique.",
  date: ~D[2026-02-03],
  slug: "2026-02-03-why-glossia",
  author: "pedro"
}
---
Si vous avez déjà publié du logiciel dans plus d'une langue, vous connaissez la procédure. Vous choisissez une plateforme de localisation, la connectez à votre dépôt, puis vous passez le reste de votre temps à gérer la synchronisation. Le contenu sort, les traductions reviennent, et quelque part entre les deux, tout casse.

Ce surcoût, l'allers-retour constant du contenu depuis et vers votre dépôt, est la taxe que chaque équipe paie pour utiliser les outils de localisation d'aujourd'hui. Cela semble mineur jusqu'à ce que vous soyez celui qui débogue pourquoi un PR de traduction a cassé le build de votre site à 18 h ce vendredi.

## Une conception héritée d'avant internet

La plupart des plateformes de localisation ont été conçues autour de concepts qui précèdent le flux de travail de développement moderne. Mémoires de traduction. Correspondance floue. Des traducteurs humains travaillant dans des éditeurs propriétaires, assistés par des outils qui suggèrent des chaînes similaires issues d'une base de données.

Ces idées avaient du sens lorsque la traduction était un processus manuel, hors ligne. Mais les entreprises ont transformé les mémoires de traduction en un mécanisme de verrouillage. Vos traductions passées, les connaissances institutionnelles pour lesquelles vous avez payé, résident à l'intérieur de leur plateforme. Passer à un autre fournisseur signifie partir à zéro, ou payer pour une exportation qui ne fonctionne jamais vraiment.

Le résultat est un secteur construit sur une friction artificielle. Votre contenu quitte votre dépôt, entre dans une boîte noire et revient selon le calendrier d'un tiers.

## La boucle de rétroaction brisée

Le problème est structurel : les outils de localisation externes ne peuvent pas exécuter votre pipeline CI. Ils ignorent vos linters, votre étape de build, votre vérificateur de liens ou votre schéma frontmatter. Ils repoussent le contenu traduit vers votre dépôt et espèrent le meilleur. Lorsqu'il plante, et qu'il le fait, quelqu'un de l'équipe doit arrêter sa tâche pour corriger des problèmes de mise en forme, une syntaxe brisée ou un balisage invalide introduits par l'outil de traduction.

Les LLMs et les expériences agenciques nous offrent de nouvelles opportunités pour repenser entièrement ces flux de travail. Un agent qui génère une traduction, exécute vos vérifications, voit l'erreur et réessaie jusqu'à ce que la sortie soit valide. Ce type de boucle de rétroaction serrée change tout.

Mais cela ne fonctionne que si le contenu reste là où il se trouve : dans votre dépôt. Dès que vous l'envoyez vers une plateforme externe, les traductions reviennent sur le calendrier d'un tiers, et l'intégration se rompt. La rétroaction qui aurait pu être instantanée prend désormais des heures ou des jours. Le contexte qui le rendait utile a disparu. Vous perdez la boucle, et avec elle, tout l'avantage que les flux de travail agenciques devaient vous offrir.

## Les observations qui ont façonné Glossia

Ces frustrations n'ont pas, d'elles-mêmes, donné naissance à Glossia. Le projet est né d'une expérience approfondie, à la fois en développement et en localisation, ce qui a apporté de la clarté à des problèmes difficiles à percevoir depuis un seul côté. Comprendre les flux de travail linguistiques, la dynamique humaine des équipes de traduction, et les raisons pour lesquelles les outils existants en sont venus là, était essentiel.

Ensemble, nous arrivions toujours aux mêmes observations : l'outillage de localisation a été conçu pour un monde sans LLMs, sans agents de codage et sans pipelines CI. Le modèle entier supposait que la traduction se passait en dehors du flux de travail de développement et était ramenée plus tard. Cela avait du sens il y a dix ans. Ce n'est plus le cas.

Nous avons commencé à nous demander : **Et si les agents de localisation pouvaient fonctionner de la même manière que les agents de codage ?**

Nous observons de près comment [Anthropic](https://anthropic.com) réfléchit aux workflows d'agents avec Claude. Le modèle d'accorder à un agent l'accès à des outils, de lui permettre de raisonner sur une tâche, de valider sa propre sortie et d'itérer lorsque quelque chose ne va pas correspond remarquablement bien à la localisation. Un agent de traduction capable de lire vos fichiers sources, de comprendre le contexte du projet, de générer des traductions, d'exécuter votre linter et de corriger les problèmes avant d'ouvrir une pull request. Ce n'est pas une illusion. C'est le flux de travail que nous construisons.

## Glossia est notre cadeau pour l'industrie logicielle

Nous avons créé Glossia car nous souhaitons qu'il y ait plus de logiciels localisés, et non moins.

Des processus complexes et des plateformes coûteuses rendent la localisation inaccessible aux petites équipes, aux développeurs indépendants et aux projets personnels. Si votre flux de traduction nécessite un processus d'approvisionnement, une négociation de prix au mot et un chef de projet pour coordonner les transferts, la plupart des équipes se contenteront de livrer en anglais et de clore le dossier.

Glossia utilise les modèles auxquels vous avez déjà accès. Et il valide les sorties avec vos propres outils, pas les nôtres.

Nous pensons que la localisation devrait être aussi naturelle que l'exécution de votre suite de tests.

## Un agent d'abord, les interfaces ensuite.

Au cœur, Glossia est un agent. Nous commençons par le terminal comme interface principale car c'est là où les problèmes les plus difficiles sont résolus en premier : lire vos fichiers sources, générer des traductions, exécuter vos contrôles et itérer jusqu'à ce que la sortie soit valide. C'est le même modèle que [OpenAI](https://openai.com) suivi avec [Codex](https://openai.com/index/openai-codex/) et [Anthropic](https://anthropic.com) avec [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Construisez l'agent, donnez-lui un terminal, et laissez-le travailler.

Mais le terminal n'est que la première interface, pas la seule. Nous savons que tous ceux qui contribuent à la qualité de la localisation ne sont pas nécessairement des développeurs. Nous en parlons souvent en interne. Ceux qui s'occupent le plus de la précision de la traduction, du ton et de la nuance culturelle sont souvent des linguistes et des spécialistes du contenu qui ne pensent pas en termes de branches, de compilation ou de JSON.

C'est pourquoi nous voulons construire de nouvelles interfaces par-dessus le même agent. Quelque chose où un linguiste voit le contenu, le contexte et la traduction côte à côte. Ils apportent le jugement humain qu'aucun modèle ne peut remplacer. Ils affinent ce qui doit être affiné. Et l'agent gère tout le reste : les commits, la validation et l'ouverture de la demande de fusion.

Nous n'avons pas encore toutes les réponses, et c'est intentionnel. Nous préférerais bâtir cela avec soin plutôt que de précipiter une interface utilisateur qui raterait l'essentiel. Mais l'orientation est claire : Glossia devrait accueillir tout le monde qui s'efforce de faire en sorte que les logiciels parlent dans toutes les langues.

## Restez à l'écoute

Glossia en est encore à ses débuts, et nous le construisons en public. Si cela résonne avec votre approche de la localisation, gardez un œil sur le projet. Nous partagerons plus de détails au fur et à mesure.