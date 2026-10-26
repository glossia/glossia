%{
  title: "La traduction est la partie facile",
  slug: "translation-is-the-easy-part",
  summary:
    "Comment les conversations sur les langues, la livraison de logiciels et la confiance ont conduit María José et moi à construire Glossia.",
  author: "pedro"
}
---

Les langues sont un excellent outil sous-estimé pour l'accessibilité et pour amener les produits technologiques sur de nouveaux marchés. Lorsque votre produit s'adresse à des communautés dont la langue principale n'est pas l'anglais, vous signalez que vous y avez réfléchi. Cela peut créer un lien très profond.

Malheureusement, faire en sorte que votre produit et votre marque parlent plusieurs langues est quelque chose dont de nombreuses équipes ne peuvent pas se permettre. Elles se retrouvent souvent obligées de choisir deux sur trois : **qualité, rapidité et coût**.

Si elles souhaitent que les traditations accompagnent le déploiement logiciel, elles peuvent investir dans une équipe dédiée pour maintenir la qualité, mais cela a un coût. Sinon, elles peuvent s'appuyer davantage sur la traduction automatique, bouger rapidement tout en acceptant une qualité inférieure. Si elles choisissent qualité et faible coût, en s'appuyant sur la traduction humaine sans une équipe dédiée, elles sacrifient généralement la vitesse. En faisant cela, elles finissent par des systèmes compliqués poussant et tirant les traductions entre leurs dépôts et des outils tiers.

Depuis l'émergence [des grands modèles de langage](https://en.wikipedia.org/wiki/Large_language_model), ma femme, [María José](https://www.linkedin.com/in/mariajosesalmeron/), et moi avons beaucoup discuté de savoir s'ils pourraient nous aider à arrêter de faire ces compromis. Elle aime les langues et est profondément intégrée dans l'industrie de la localisation. Je suis un bâtisseur.

Tuist est mon travail principal. Lorsque j'ai essayé de traduire le produit et ses interfaces marketing, je me suis retrouvé confronté à des solutions compliquées. Aucune d'elles ne tenait le rythme de notre vitesse de livraison, et certaines ont conduit à des conflits dont la résolution était un cauchemar. J'ai eu ce moment "ça ne sent pas bon" à maintes reprises.

## Des conversations à Glossia

Chaque semaine, nous discutions des nouveaux modèles émergentes autour des capacités des modèles de langage. Nous avons vu de plus en plus de développeurs qui construisaient leurs propres chaînes de traduction. Au cœur de ces pipelines se trouvait un modèle : source en entrée, traduction en sortie, puis on continue.

Cela semblait compréhensible. C'est ainsi que nous, bâtisseurs, opérons. Mais quelqu'un de plus proche des langues et des processus qui l'environnent pouvait voir comment cela pourrait mal tourner, de simples incohérences au mieux à des traductions erronées au pire.

Les développeurs se déplacent de plus en plus vite. Ils ne peuvent pas ralentir pour introduire un système dont les workflows sous-jacents ont été conçus longtemps avant internet, déplacés dans un navigateur, et qui peinent encore à répondre aux besoins des équipes logicielles.

C'est ainsi que l'idée de construire Glossia a commencé. D'un côté, nous parions sur les modèles devenant meilleurs pour les langues autres que l'anglais et pour les traductions. De l'autre, nous construirions un système, initialement axé sur le contenu logiciel, qui se sentait plug and play. Quelque chose qui courait en arrière-plan, correspondant à votre vitesse de livraison, et vous donnant confiance que la sortie est correcte et prête pour la production.

De nombreux développeurs traitent la traduction comme une solution à une seule invite. Quelques jetons, anglais en entrée, traduction en sortie, et fini. Mais quand vous parlez avec eux, vous réalisez qu'ils ne savent pas si la sortie est précise, capte la voix de leur organisation dans cette langue, ou communique le message souhaité efficacement.

J'ai une chaîne similaire chez Tuist, traduisant dans des langues comme le japonais, et je le fais avec un manque énorme de confiance. Les langues ne sont pas de la logique. Nous pouvons écrire des tests pour garantir que le format est correct, mais cela ne nous dit pas **si les mots sont justes**.

« La traduction est la partie facile », comme aime le dire ma femme.

Nous avons donc entrepris de déterminer à quoi un système approprié pourrait ressembler. Nous l'avons appelé Glossia, et nous commençons maintenant à l'ouvrir aux personnes et organisations intéressées à nous aider à l'améliorer ensemble.

## Décider quoi traduire

La première chose sur laquelle nous nous sommes concentrés était d'aider à décider quoi traduire. Le coût de la traduction est en baisse et continuera de baisser, mais il ne sera jamais nul. Les organisations devraient toujours être sélectives sur les langues dans lesquelles elles investissent.

Parfois, ce choix suit directement une décision commerciale. D'autres fois, les équipes ont une idée vague de leurs communautés et font une estimation éclairée. Nous pensions qu'il y avait beaucoup à apprendre des gens qui visitent vos sites web ou utilisent vos applications. Leurs préférences linguistiques, combinées aux informations sur les régions à partir desquelles ils utilisent vos produits, peuvent vous donner une meilleure base pour ces décisions.

La première fonctionnalité que nous avons intégrée dans Glossia était l'analyse. Ajoutez une ligne de code à votre site web, et les analyses commencent à affluer vers votre compte. Nous présentons ces informations autour de la décision que vous devez prendre : dans quelles langues devriez-vous investir la suite ?

Plus tard, nous explorerons comment amener les expériences dans la dimension linguistique d'un produit. Imaginez mesurer la fréquence à laquelle les gens cliquent sur un appel à l'action lorsqu'une page utilise différentes voix dans la même langue. Ce serait pas mal ? Comparer des variantes s'est traditionnellement tourné autour de décisions de produit et de design, mais les langues font aussi partie du produit.

## De zéro à la traduction

Une fois que vous avez décidé de traduire un projet, l'étape suivante est de le configurer. En tant que développeur, je déteste les processus qui comportent beaucoup de friction. Nous sommes convenus que passer du zéro à la traduction devrait idéalement prendre un seul pas. C'est ce niveau d'expérience que nous cherchons à atteindre.

La configuration implique généralement deux choses. D'abord, extraire le contenu du dépôt afin qu'il puisse être traduit, car il commence souvent comme des chaînes littérales dans le code. Ensuite, configurer le projet pour sélectionner le bon contenu basé sur la langue. Cela peut venir de l'appareil de l'utilisateur ou, dans des cas plus élaborés, d'une préférence qu'ils ont choisie.

Automatiser de manière fiable cela il y a quelques années aurait été un cauchemar. Les choses ont changé, et les agents peuvent être assez efficaces à ce sujet.

Le processus se déroule comme ceci : vous connectez votre dépôt GitHub, sélectionnez les langues dans lesquelles vous souhaitez traduire, puis, après un moment, une demande de fusion s'ouvre avec les modifications. Une fois que vous la fusionnez, les traductions commencent. C'est tout.

Nous conservons les traductions dans le dépôt, aux côtés des vérifications de format et d'autres validations que vous exécutez déjà dans le cadre de [l'intégration continue](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). Le pipeline de traduction renvoie les résultats de ces vérifications à l'agent de traduction. Cela élimine toute une catégorie de problèmes où une plateforme ouvre une demande de fusion et vous laisse gérer les vérifications échouées ou les conflits de fusion.

En combinant cela avec d'autres mécanismes pour construire la confiance, c'est ce qui rend la fusion automatique des traductions possible. C'est le modèle que nous défendons. Il y a très peu de valeur à demander à un développeur de vérifier si une demande de fusion de traduction est verte et de cliquer sur un bouton, surtout s'il ne peut pas évaluer la langue lui-même. Nous avons toujours vu cette cérémonie supplémentaire comme un signe que le design pourrait être meilleur.

Nous croyons que le meilleur système de traduction est celui qui fonctionne sans que vous ayez à y réfléchir.

## Traduire uniquement ce qui a changé

Le système de traduction mérite sa propre section. Les tokens ne sont pas encore gratuits. Tout traduire tout le temps est lent, coûteux et un gaspillage de ressources.

Pour résoudre cela, nous avons construit un système de fichier de verrouillage qui nous indique si quelque chose doit être traduit. Nous appelons cela **la traduction incrémentale**. L'idée n'est pas nouvelle : les systèmes de construction l'utilisent depuis longtemps pour éviter de recompiler tout sur chaque build. Nous avons adapté cela aux langues.

Le système tient compte de tout le contexte qui affecte une traduction particulière. Une partie de ce contexte réside dans le dépôt. Une partie réside dans Glossia et s'étend sur plusieurs dépôts. Nous construisons un arbre de dépendances et utilisons [les arbres de Merkle](https://en.wikipedia.org/wiki/Merkle_tree) pour calculer des hachages qui nous indiquent si les entrées d'une traduction ont changé.

Le fichier de verrouillage preserve cet arbre. Il peut expliquer pourquoi quelque chose a été envoyé pour traduction, ou pourquoi il ne l'a pas été, au lieu de laisser les gens deviner.

[`L10N.md`](/docs/reference/l10n-md) offre le contexte de localisation pour nos agents de traduction, tout comme `AGENTS.md` files opèrent pour les agents de codage. Ils utilisent un contexte plus spécifique dans des répertoires imbriqués et des chevauchements linguistiques à chaque niveau.

Pour les informations s'appliquant à plus d'un dépôt, comme la terminologie partagée, le serveur est la source de vérité. Le système s'assure d'utiliser le bon contexte et de le refléter dans le fichier de verrouillage. Lorsque ce contexte change, nous pouvons mapper le changement retour aux traductions qui l'ont utilisé et doivent être mises à jour.

## Construire la confiance dans les mots

Le système est conçu pour converger vers un niveau de qualité. Pour y parvenir, nous avons plusieurs outils.

Le premier sont les vérifications adverses qui s'exécutent après la traduction. Imaginez un collègue qui examine le code que vous avez inclus dans une demande de fusion. Là, les vérifications amènent des connaissances linguistiques dans l'examen. Par exemple, une traduction ne devrait pas ajouter ou retirer de sens de la source. Cela peut arriver car les modèles linguistiques ne produisent pas toujours la même sortie à partir des mêmes entrées.

Comme nous en apprenons plus de nos utilisateurs et de notre propre recherche sur les modèles et les systèmes existants, nous ajouterons plus de vérifications automatisées au pipeline. Chaque vérification devrait augmenter la confiance que vous pouvez avoir dans une traduction.

L'idée est d'atteindre un point où vous avez assez confiance au système que vous ne ressentez pas le besoin de passer toutes les demandes de fusion. Cette confiance dépend à la fois du système et des modèles. Nous pouvons aider à sélectionner des modèles en fonction de la langue cible, car tous les modèles ne sont pas aussi bons pour les mêmes langues.

Même avec ces vérifications en place, vous devrez peut-être modifier une pièce traduite. Cela peut être une correction ponctuelle, de la terminologie qui n'a pas encore été écrite dans le contexte, ou l'un des nombreux scénarios que nous allons encore rencontrer.

Quelqu'un devrait pouvoir contribuer ces modifications directement au dépôt. Mais nous pensons aussi que le système devrait traiter ces contributions comme des commentaires et suggérer comment les réconcilier avec son contexte. Cela pourrait signifier ajouter un terme à la glossaire ou ajuster la voix.

C'est quelque chose qu'un humain peut faire de manière asynchrone, sans interrompre la traduction continue. Le système devrait vous aider à en faire plus efficace son travail en apprenant de ce que les gens ont à dire. Nous pourrions étendre cela aux gens proposant des commentaires directement depuis le produit. Ce serait pas mal ?

Ces corrections doivent aussi être prises en considération pour que les traductions futures ne les écrasent pas. Un appel de traduction sans état n'a aucune connaissance des modifications que les gens ont faites avant lui. Dans les systèmes traditionnels, la mémoire de traduction aide à remplir ce rôle. Le besoin qu'ils servent ne disparaît pas juste parce que la technologie change.

## Où nous allons d'ici là

C'est Glossia. Nous l'utilisons déjà pour traduire Glossia, et je travaille sur sa configuration pour traduire la documentation, le site marketing et le tableau de bord de Tuist dans les langues de nos communautés.

María José et moi construisons Glossia dans notre temps libre, suivant une curiosité qui fait partie de nos conversations depuis des années.

En programmation, beaucoup de questions le rôle des programmeurs et comment il évoluera. Je pense que l'industrie de localisation bénéficierait d'une interrogation similaire de ses hypothèses et modèles. Comment pouvons-nous aider notre industrie à traduire plus, plus vite, et à coût inférieur, sans compromettre la qualité ?

Nous n'avons pas encore les réponses à toutes les questions. Mais nous croyons que nous sommes sur la bonne voie, avec la simplicité et l'attention au travail que nous aimons mettre dans tout ce que nous faisons.

Si cela résonne avec vous, [dés à discuter](mailto:pedro@glossia.ai).
