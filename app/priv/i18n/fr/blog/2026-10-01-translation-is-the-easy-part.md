%{
  title: "La traduction est la partie facile",
  slug: "translation-is-the-easy-part",
  summary:
    "Comment les conversations sur les langues, la livraison de logiciels et la confiance ont amené María José et moi à construire Glossia.",
  author: "pedro"
}
---

Les langues sont un outil extraordinary et sous-estimé pour l'accessibilité et pour amener des produits technologiques sur de nouveaux marchés. Lorsque votre produit s'adresse à des communautés dont la langue principale n'est pas l'anglais, vous signalez que vous avez pensé à elles. Cela peut établir une connexion très profonde.

Malheureusement, faire parler votre produit et votre marque de plusieurs langues est quelque chose dont de nombreuses équipes ne peuvent pas se permettre. Elles se trouvent souvent obligées d'en choisir deux sur trois : **qualité, vitesse et coût**.

S'ils veulent que les traductions tiennent le rythme de la livraison logicielle, ils peuvent investir dans une équipe dédiée pour maintenir la qualité, mais cela a un prix. Ou ils peuvent s'appuyer davantage sur la traduction automatique, en jouant vite mais acceptant une qualité moindre. S'ils choisissent la qualité et le faible coût, en comptant sur la traduction humaine sans équipe dédiée, ils sacrifient généralement la rapidité. Sur cette voie, ils finissent par avoir des systèmes convolutés poussant et tirant les traductions entre leurs dépôts et des outils tiers.

Depuis l'émergence [des grands modèles de langage](https://en.wikipedia.org/wiki/Large_language_model), ma femme, [María José](https://www.linkedin.com/in/mariajosesalmeron/), et moi avons beaucoup discuté de savoir si les modèles pourraient nous aider à arrêter de faire ces compromis. Elle aime les langues et est profondément intégrée à l'industrie de la localisation. Je suis un bâtisseur.

Tuist est mon principal poste. Lorsque j'ai essayé de traduire le produit et ses surfaces marketing, je me suis retrouvé à gérer des solutions convolutées. Aucun n'a tenu le rythme de notre vitesse de livraison, et certains ont mené à des conflits qu'il a été un cauchemar de résoudre. J'ai eu ce moment « cela ne semble pas correct » plusieurs fois.

## De conversations à Glossia

Chaque semaine, nous étions à l'écoute de nouveaux modèles émergents autour des capacités des modèles de langage. Nous voyions de plus en plus de développeurs construire leurs propres pipelines de traduction. Au fond, ces pipelines implique un modèle : entrée en langue source, sortie de traduction, puis continuer.

Cela paraissait compréhensible. C'est ainsi que nous les bâtisseurs opérons. Mais quelqu'un plus proche des langues et des processus qui les entourent pourrait voir à quel point cela pouvait échouer, des incohérences au mieux aux traductions erronées au pire.

Les développeurs avancent de plus en plus vite. Ils ne peuvent pas ralentir pour intégrer un système dont les flux sous-jacents ont été conçus bien avant Internet, portés dans un navigateur, et continuent d'avoir du mal à répondre aux besoins des équipes logicielles.

C'est ainsi que l'idée de créer Glossia a commencé. D'un côté, nous parierons sur des modèles devenant meilleurs pour les langues autres que l'anglais et la traduction. De l'autre, nous construirons un système, initialement axé sur le contenu logiciel, qui semblait simple à installer. Quelque chose s'exécutant en arrière-plan, correspondant à votre vitesse de livraison, et vous donnant confiance que la sortie est correcte et prête pour la production.

Beaucoup de développeurs considèrent la traduction comme une solution en une seule invite. Quelques tokens, entrée anglais, sortie traduction, et c'est fini. Mais quand vous les interrogez, vous réalisez qu'ils ne savent pas si la sortie est précise, capture la voix de leur organisation dans cette langue, ou communique le message souhaité efficacement.

J'ai un pipeline similaire chez Tuist, traduisant vers des langues comme le japonais, et je le fais avec un manque énorme de confiance. Les langues ne sont pas de la logique. Nous pouvons écrire des tests pour garantir que le format est correct, mais cela ne nous dit pas **si les mots sont justes**.

« La traduction est la partie facile, » comme aime le dire ma femme.

C'est pourquoi nous nous sommes lancés pour comprendre à quoi le bon système pourrait ressembler. Nous l'avons appelé Glossia, et nous commençons à l'ouvrir aux personnes et organisations intéressées à nous aider à l'améliorer ensemble.

## Décider quoi traduire

La première chose sur laquelle nous nous sommes concentrés était d'aider les gens à décider ce qu'il faut traduire. Le coût de la traduction diminue et continuera de diminuer, mais il ne sera jamais zéro. Les organisations devraient toujours être sélectives quant aux langues dans lesquelles elles investissent.

Parfois, ce choix découle directement d'une décision commerciale. D'autres fois, les équipes ont une idée vague de leurs communautés et font une hypothèse éclairée. Nous pensions qu'il y avait beaucoup à apprendre des personnes visitant vos sites web ou utilisant vos applications. Leurs préférences linguistiques, combinées avec des informations sur les régions à partir desquelles elles utilisent vos produits, peuvent vous donner une meilleure base pour ces décisions.

La première fonctionnalité que nous avons intégrée à Glossia était l'analyse. Ajoutez une ligne de code à votre site, et les analyses commencent à affluer vers votre compte. Nous présentons ces informations autour de la décision que vous devez prendre : quelles langues devriez-vous investir ensuite ?

Dans un avenir proche, nous explorerons comment intégrer des tests dans la dimension linguistique d'un produit. Imaginez mesurer la fréquence à laquelle les gens cliquent sur un appel à l'action lorsqu'une page utilise différentes voix dans la même langue. N'est-ce pas cool ? La comparaison des variantes a traditionnellement été orientée autour des décisions produit et design, mais les langues font aussi partie du produit.

## De zéro à traduction

Une fois que vous avez décidé de traduire un projet, la prochaine étape est sa configuration. En tant que développeur, je déteste les processus qui provoquent beaucoup de friction. Nous avons convenu que passer de zéro à la traduction devrait idéalement prendre un seul pas. C'est le niveau d'expérience que nous visons.

La configuration implique généralement deux choses. Premièrement, extraire le contenu du dépôt pour qu'il puisse être traduit, car il commence souvent par des chaînes littérales dans le code. Deuxièmement, configurer le projet pour sélectionner le bon contenu basé sur la langue. Cela peut venir du dispositif de l'utilisateur ou, dans des cas plus sophistiqués, une préférence qu'ils ont choisie.

Automatiser cela de manière fiable il y a quelques années aurait été un cauchemar. Les choses ont changé, et les agents peuvent être très efficaces là-dedans.

Le processus se déroule ainsi : vous connectez votre dépôt sur GitHub, sélectionnez les langues que vous voulez traduire, et, après un certain temps, une Pull Request s'ouvre avec les modifications. Une fois que vous la fusionnez, les traductions commencent. C'est tout.

Nous conservons les traductions dans le dépôt, aux côtés des vérifications de format et des autres validations que vous exécutez déjà dans le cadre de [l'intégration continue](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). Le pipeline de traduction renvoie les résultats de ces vérifications à l'agent de traduction. Cela élimine toute une série de problèmes où une plateforme ouvre une Pull Request et vous laisse gérer les échecs de validation ou les conflits de fusion.

Combiné avec d'autres mécanismes pour instaurer la confiance, c'est ce qui rend possible de fusionner automatiquement les traductions. Telle est la conviction qui nous porte. Il n'y a guère d'intérêt à demander à un développeur de vérifier si une Pull Request de traduction est verte et de cliquer sur un bouton, surtout lorsqu'il n'est pas en mesure d'évaluer la lui-même. Nous avons toujours considéré cette cérémonie supplémentaire comme le signe d'un design qui pourrait être amélioré.

Nous croyons que le meilleur système de traduction est celui qui fonctionne sans que vous ayez à y réfléchir.

## Traduire uniquement ce qui a changé

Le système de traduction mérite une section à part. Les jetons ne sont toujours pas gratuits. Traduire tout en permanence est lent, coûteux et un gaspillage de ressources.

Pour résoudre cela, nous avons construit un système de fichier de verrouillage qui nous indique si quelque chose a besoin d'être traduit. Nous appelons cela **traduction incrémentale**. L'idée n'est pas nouvelle : les systèmes de build l'utilisent depuis longtemps pour éviter de recompiler tout à chaque build. Nous l'avons adaptée aux langues.

Le système prend en compte tout le contexte qui affecte une traduction particulière. Une partie de ce contexte réside dans le dépôt. Une autre réside dans Glossia et s'étend sur plusieurs dépôts. Nous construisons un arbre des dépendances et utilisons [les arbres de Merkle](https://en.wikipedia.org/wiki/Merkle_tree) pour calculer des hachages qui nous indiquent si les entrées d'une traduction ont changé.

Le fichier de verrouillage conserve cet arbre. Il peut expliquer pourquoi quelque chose a été envoyé en traduction, ou pourquoi pas, au lieu de laisser les gens dans une incertitude.

[`L10N.md`](/docs/reference/l10n-md) fichiers fournissent un contexte de localisation à nos agents de traduction, tout comme `AGENTS.md` fichiers fournissent des instructions à nos agents de codage. Ils prennent en charge un contexte plus spécifique dans les répertoires imbriqués, ainsi que des dépassements de langue à chaque niveau.

Pour les informations qui s'appliquent à plus d'un dépôt, comme une terminologie partagée, le serveur est la source de vérité. Le système veille à utiliser le bon contexte et à le refléter dans le fichier de verrouillage. Lorsque ce contexte change, nous pouvons retracer le changement vers les traductions qui l'ont utilisé et qui doivent être mises à jour.

## Construire la confiance dans les mots

Le système est conçu pour converger vers un niveau de qualité. Pour y parvenir, nous disposons de plusieurs outils.

Le premier sont des vérifications adversaires qui s'exécutent après la traduction. Pensez à un collègue qui revoit le code que vous avez inclus dans une Pull Request. Ici, les vérifications apportent des connaissances linguistiques dans la révision. Par exemple, une traduction ne devrait pas ajouter ou retirer de sens à la source. Cela peut arriver car les modèles de langage ne produisent pas toujours le même résultat à partir des mêmes entrées.

Alors que nous apprendrons davantage de nos utilisateurs et de notre propre recherche sur les modèles et les systèmes existants, nous ajouterons plus de vérifications automatisées au pipeline. Chaque ajout doit augmenter la confiance que vous pouvez avoir dans une traduction.

L'idée est d'atteindre un point où vous faites confiance au système au point de ne plus ressentir le besoin de parcourir chaque Pull Request. Cette confiance dépend du système et des modèles. Nous pouvons aider à sélectionner les modèles en fonction de la langue cible, car tous les modèles ne sont pas également bons pour les mêmes langues.

Même avec ces vérifications en place, vous devrez peut-être modifier un morceau traduit. Il pourrait s'agir d'une correction ponctuelle, d'une terminologie qui n'a pas encore été écrite dans le contexte, ou l'un des nombreux scénarios que nous sommes encore susceptibles de rencontrer.

Un humain doit pouvoir contribuer ces modifications directement au dépôt. Mais nous pensons aussi que le système devrait traiter ces contributions comme des retours et suggérer comment les réconcilier avec son contexte. Cela pourrait impliquer d'ajouter un terme au glossaire ou d'ajuster la voix.

C'est quelque chose qu'un humain peut faire asynchronement, sans interrompre la traduction continue. Le système devrait vous aider à le rendre plus efficace dans son rôle en apprenant des retours des gens. Nous pourrions étendre cela pour permettre aux personnes de suggérer des retours directement depuis le produit. N'est-ce pas cool ?

Ces corrections doivent aussi être prises en compte pour que les futures traductions ne les écrasent pas. Un appel de traduction sans état n'a aucune connaissance des changements apportés par les gens avant lui. Dans les systèmes traditionnels, les mémoires de traduction aident à combler ce rôle. Le besoin qu'elles servent ne disparaît pas juste parce que la technologie change.

## Où nous allons

C'est Glossia. Nous l'utilisons déjà pour traduire Glossia et je travaille actuellement à le configurer pour traduire la documentation de Tuist, son site marketing et son tableau de bord dans les langues de nos communautés.

María José et moi construisons Glossia dans nos temps libres, suivant une curiosité qui fait partie intégrante de nos discussions depuis des années.

En programmation, beaucoup de gens questionnent le rôle des programmeurs et son évolution. Je pense que l'industrie de la localisation tirerait bénéfice d'un questionnement similaire de ses hypothèses et modèles. Comment pouvons-nous aider notre industrie à traduire plus, plus rapidement et à moindre coût, sans compromettre la qualité ?

Nous n'avons pas encore de réponses à toutes ces questions. Mais nous croyons être dans la bonne direction, avec la simplicité et l'attention à l'artisanat que nous aimons déployer dans tout ce que nous faisons.

Si cela résonne avec vous, [parlons-en](mailto:pedro@glossia.ai).
