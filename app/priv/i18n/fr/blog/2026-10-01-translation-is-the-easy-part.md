%{
  title: "La traduction est la partie facile",
  slug: "translation-is-the-easy-part",
  summary:
    "Comment des conversations sur les langues, la livraison de logiciels et la confiance ont amené María José et moi à créer Glossia.",
  author: "pedro"
}
---

Les langues sont un outil formidable et sous-estimé pour l'accessibilité et l'apport de produits technologiques sur de nouveaux marchés. Quand votre produit s'adresse à des communautés dont la langue principale n'est pas l'anglais, vous signalez que vous avez pensé à elles. Cela peut établir un lien très profond.

Malheureusement, faire parler votre produit et votre marque dans plusieurs langues est quelque chose que de nombreuses équipes ne peuvent pas se permettre. Elles se retrouvent souvent obligées d'en choisir deux sur trois : **qualité, vitesse et coût**.

Si elles souhaitent que des traductions accompagnent la livraison de logiciels, elles peuvent investir dans une équipe dédiée pour maintenir la qualité, mais cela a un prix. Ou elles peuvent s'appuyer plus lourdement sur la traduction automatique, en allant vite mais en acceptant une qualité moindre. Si elles optent pour la qualité et le faible coût, en s'appliquant à la traduction humaine sans équipe dédiée, elles sacrifient généralement la vitesse. En cours de route, elles finissent par obtenir des systèmes trop compliqués qui poussent et tirent des traductions entre leurs dépôts et les outils tiers.

Depuis l'émergence de [grands modèles de langage](https://en.wikipedia.org/wiki/Large_language_model), ma femme, [María José](https://www.linkedin.com/in/mariajosesalmeron/), et moi avons beaucoup discuté de savoir s'ils pouvaient nous aider à cesser de faire ces compromis. Elle adore les langues et est profondément ancrée dans l'industrie de la localisation. Je suis un constructeur.

Tuist est mon activité principale. Quand j'ai essayé de traduire le produit et ses surfaces marketing, je me suis retrouvé à gérer des solutions compliquées. Aucune n'a tenu le rythme de notre vitesse de livraison, et certaines ont conduit à des conflits qui étaient un cauchemar à résoudre. J'ai eu maintes fois ce moment «cela me paraît faux».

## De discussions à Glossia

Toutes les semaines, nous discutions des nouveaux motifs émergents autour des capacités des modèles de langage. Nous avons vu de plus en plus de développeurs construire leurs propres pipelines de traduction. Au cœur de ces pipelines, se trouvait un modèle : langue source en entrée, traduction en sortie, puis continuer.

Ça semblait logique. C'est ainsi que nous, les constructeurs, fonctionnons. Mais quelqu'un plus proche des langues et des processus qui les entourent pouvait voir comment cela pouvait mal tourner, des incohérences au mieux aux fausses traductions au pire.

Les développeurs vont de plus en plus vite. Ils ne peuvent pas ralentir pour introduire un système dont les flux de travail sous-jacents ont été conçus bien avant internet, devenus compatibles avec un navigateur et peinent encore à répondre aux besoins des équipes logicielles.

C'est ainsi que l'idée de construire Glossia a commencé. D'un côté, nous parierions sur des modèles capables de mieux traiter les langues autres que l'anglais et la traduction. De l'autre, nous construirions un système, initialement axé sur le contenu logiciel, simple à mettre en œuvre, qui tourne en arrière-plan, correspond à votre vitesse de livraison, et vous donne confiance que le résultat est juste et prêt pour la production.

De nombreux développeurs traitent la traduction comme une solution à un seul prompt. Quelques tokens, anglais entrant, traduction sortante, et c'est fini. Mais quand vous en parlez avec eux, vous réalisez qu'ils ne savent pas si la sortie est précise, capture la voix de leur organisation dans cette langue, ou communique le message de manière efficace.

J'ai un pipeline similaire chez Tuist, traduisant vers des langues comme le japonais, et je le fais avec un manque énorme de confiance. Les langues ne sont pas de la logique. Nous pouvons écrire des tests pour garantir que le format est correct, mais cela ne nous dit pas **si les mots sont justes**.

« La traduction, c'est la facilité », comme aime le dire ma femme.

Nous nous sommes donc lancé pour déterminer à quoi ressemblerait le bon système. Nous l'appelons Glossia, et nous commençons à l'ouvrir aux personnes et organisations intéressées par nous aider à l'améliorer ensemble.

## Choisir quoi traduire

La première chose sur laquelle nous avons travaillé était d'aider les gens à décider quoi traduire. Le coût de la traduction baisse et continuera de baisser, mais il ne sera jamais nul. Les organisations doivent toujours être sélectives sur les langues qu'elles investissent.

Parfois, ce choix découle directement d'une décision commerciale. D'autres fois, les équipes ont une idée approximative de leurs communautés et font une estimation éclairée. Nous pensions qu'il y avait beaucoup à apprendre des personnes visitant vos sites web ou utilisant vos applications. Leurs préférences linguistiques, combinées à des informations sur les régions depuis lesquelles elles utilisent vos produits, peuvent vous donner une meilleure base pour ces décisions.

La première fonctionnalité que nous avons lancée sur Glossia était l'analytique. Ajoutez une ligne de code à votre site web, et les données d'analytique commencent à affluer vers votre compte. Nous présentons ces informations en fonction de la décision que vous devez prendre : dans quelles langues devriez-vous investir ensuite ?

À l'avenir, nous explorerons comment intégrer les expériences dans la dimension linguistique d'un produit. Imaginez mesurer à quelle fréquence les gens cliquent sur un appel à l'action quand une page utilise des voix différentes dans la même langue. Ce ne serait pas cool ? Comparer les variantes a traditionnellement gravité autour des décisions de produit et de design, mais les langues font aussi partie du produit.

## Du zéro à la traduction

Une fois que vous avez décidé de traduire un projet, l'étape suivante est la configuration. En tant que développeur, je déteste les processus qui comportent beaucoup de friction. Nous avons convenu que passer du zéro à la traduction devrait idéalement ne prendre qu'une étape. C'est le niveau d'expérience pour lequel nous visons.

La configuration implique généralement deux choses. D'abord, extraire le contenu du dépôt afin qu'il puisse être traduit, car il commence souvent sous forme de chaînes littérales dans le code. Ensuite, configurer le projet pour choisir le bon contenu en fonction de la langue. Cela peut provenir du dispositif de l'utilisateur ou, dans des cas plus sophistiqués, une préférence qu'ils ont choisie.

L'automatisation fiable de cela il y a quelques années aurait été un cauchemar. Les choses ont changé, et les agents peuvent en être très efficaces.

Le processus se déroule comme ceci : vous connectez votre dépôt GitHub, sélectionnez les langues dans lesquelles vous souhaitez traduire, et, après un certain temps, une pull request s'ouvre avec les modifications. Une fois que vous la fusionnez, les traductions commencent à se produire. C'est tout.

Nous conservons les traductions dans le dépôt, à côté des vérifications de format et d'autres validations que vous exécutez déjà dans le cadre de [continuous integration](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). Le pipeline de traduction renvoie les résultats de ces vérifications vers l'agent de traduction. Cela élimine toute une catégorie de problèmes où une plateforme ouvre une pull request et vous laisse gérer des vérifications en échec ou des conflits de fusion.

CCombine avec d'autres mécanismes pour renforcer la confiance, c'est ce qui rend possible la fusion automatique des traductions. Tel est le modèle dans lequel nous croyons. Il y a peu de valeur à demander à un développeur de vérifier si une pull request de traduction est verte et de cliquer sur un bouton, surtout s'il ne peut pas évaluer la langue lui-même. Nous avons toujours vu cette cérémonie supplémentaire comme un signe que le design pourrait être meilleur.

Nous croyons que le meilleur système de traduction est celui qui fonctionne sans que vous ayez à y réfléchir.

## Traduire uniquement ce qui a changé

Le système de traduction mérite sa propre section. Les tokens ne sont toujours pas gratuits. Traduire tout le temps est lent, coûteux et gaspille des ressources.

Pour y remédier, nous avons construit un système de fichier de verrouillage qui nous indique si quelque chose a besoin d'être traduit. Nous appelons cela **incremental translation**. L'idée n'est pas nouvelle : les systèmes de construction l'ont utilisé durant longtemps pour éviter de recompiler tout lors de chaque build. Nous l'avons adapté aux langues.

Le système prend en compte tout le contexte qui affecte une traduction particulière. Une partie de ce contexte réside dans le dépôt. D'autre réside dans Glossia et s'étend sur plusieurs dépôts. Nous construisons un arbre de dépendances et utilisons [Merkle trees](https://en.wikipedia.org/wiki/Merkle_tree) pour calculer des hash qui nous disent si les entrées d'une traduction ont changé.

Le fichier de verrouillage préserve cet arbre. Il peut expliquer pourquoi quelque chose a été envoyé pour traduction, ou pourquoi il ne l'a pas été, au lieu de laisser les gens deviner.

[`L10N.md`](/docs/reference/l10n-md) fichiers fournissent un contexte de localisation à nos agents de traduction, tout comme `AGENTS.md` fournissent des instructions aux agents de codage. Ils prennent en charge un contexte plus spécifique dans les répertoires imbriqués, ainsi que des remplacements de langue à chaque niveau.

Pour les informations qui s'appliquent à plusieurs dépôts, comme un glossaire partagé, le serveur est la source de vérité. Le système s'assure d'utiliser le bon contexte et de le refléter dans le fichier de verrouillage. Lorsque ce contexte change, nous pouvons mapper le changement vers les traductions qui l'utilisaient et doivent être mises à jour.

## Renforcer la confiance dans les mots

Le système est conçu pour converger vers un niveau de qualité. Pour y parvenir, nous avons plusieurs outils.

Le premier sont des vérifications adversaires qui s'exécutent après la traduction. Imaginez un collègue qui révise le code que vous avez inclus dans une pull request. Ici, les vérifications apportent des connaissances linguistiques à la révision. Par exemple, une traduction ne devrait pas ajouter ou retirer de sens par rapport à la source. Cela peut arriver car les modèles linguistiques ne produisent pas toujours la même sortie à partir des mêmes entrées.

Au fur et à mesure que nous apprenons davantage de nos utilisateurs et de nos propres recherches sur les modèles et systèmes existants, nous ajouterons plus de vérifications automatisées au pipeline. Chacune devrait augmenter la confiance que vous pouvez avoir dans une traduction.

L'idée est d'atteindre un point où vous faites confiance au système assez pour ne pas sentir le besoin de passer par chaque pull request. Cette confiance dépend à la fois du système et des modèles. Nous pouvons aider à sélectionner des modèles basés sur la langue cible, car tous les modèles ne sont pas également bons dans les mêmes langues.

Même avec ces vérifications en place, vous pouvez avoir à modifier un élément traduit. Cela peut être une correction ponctuelle, une terminologie qui n'a pas encore été écrite dans le contexte, ou l'un des nombreux scénarios que nous sommes encore appelés à rencontrer.

Quelqu'un devrait pouvoir contribuer ces changements directement au dépôt. Mais nous pensons aussi que le système devrait traiter ces contributions comme un feedback et suggérer comment les réconcilier avec son contexte. Cela pourrait signifier ajouter un terme au glossaire ou ajuster la voix.

C'est quelque chose qu'un humain peut faire de manière asynchrone, sans interrompre la traduction continue. Le système devrait vous aider à rendre cela plus efficace dans son travail en apprenant de ce que disent les gens. Nous pourrions étendre cela aux gens qui suggèrent un feedback directement depuis le produit. Ce ne serait pas cool ?

Ces corrections doivent aussi être prises en compte afin que les traductions futures ne les écrasent pas. Un appel de traduction sans état a peu de connaissance des changements que les gens ont effectués avant. Dans les systèmes traditionnels, les mémoires de traduction aident à remplir ce rôle. Le besoin qu'elles servent ne disparaît simplement parce que la technologie change.

## Où allons-nous vers la suite

Voilà Glossia. Nous l'utilisons déjà pour traduire Glossia, et je travaille à le configurer pour traduire la documentation de Tuist, son site marketing et son tableau de bord vers les langues de nos communautés.

María José et moi construisons Glossia dans notre temps libre, suivant une curiosité qui fait partie de nos conversations depuis des années.

En programmation, de nombreuses personnes questionnent le rôle des programmeurs et comment il évoluera. Je pense que l'industrie de localisation bénéficierait d'une remise en question similaire de ses hypothèses et modèles. Comment pouvons-nous aider notre industrie à traduire plus, plus vite et à moindre coût, sans compromettre la qualité ?

Nous n'avons pas encore de réponse à toutes les questions. Mais nous croyons que nous allons dans la bonne direction, avec la simplicité et l'attention portée au métier que nous aimons apporter à tout ce que nous faisons.

Si cela vous parle, [let's chat](mailto:pedro@glossia.ai).
