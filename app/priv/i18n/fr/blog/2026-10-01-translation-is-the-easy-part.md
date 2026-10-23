%{
  title: "La traduction est la partie facile.",
  slug: "translation-is-the-easy-part",
  summary:
    "Comment des conversations sur les langues, la livraison de logiciels et la confiance ont conduit María José et moi à construire Glossia.",
  author: "pedro"
}
---

Les langues sont un outil formidable et généralement sous-estimé pour l'accessibilité et l'ouverture de produits technologiques de nouveaux marchés. Quand votre produit s'adresse à des communautés dont la langue principale n'est pas l'anglais, vous signalez que vous y avez pensé. Cela peut établir une connexion très profonde.

Malheureusement, faire parler votre produit et votre marque dans plusieurs langues est quelque chose que de nombreuses équipes ne peuvent se permettre. Elles se retrouvent souvent devoir choisir deux sur trois : **qualité, vitesse, et coût**.

Si elles veulent que les traductions suivent le rythme de la livraison de logiciels, elles peuvent investir dans une équipe dédiée pour maintenir la qualité, mais cela a un coût. Ou elles peuvent compter davantage sur la traduction automatique, avancer vite tout en acceptant une qualité inférieure. Si elles choisissent la qualité et le faible coût, en s'appuyant sur une traduction humaine sans équipe dédiée, elles sacrifient généralement la vitesse. En route, elles finissent par avoir des systèmes compliqués poussant et tirant des traductions entre leurs dépôts et des outils tiers.

Depuis l'émergence de [modèles de langage](https://en.wikipedia.org/wiki/Large_language_model), ma femme, [María José](https://www.linkedin.com/in/mariajosesalmeron/), et moi avons beaucoup parlé de savoir s'ils pourraient nous aider à arrêter de faire ces compromis. Elle aime les langues et est profondément impliquée dans l'industrie de la localisation. Je suis un bâtisseur.

Tuist est mon activité principale. Quand j'ai tenté de traduire le produit et ses surfaces marketing, je me suis retrouvé à gérer des solutions compliquées. Aucun d'elles ne tenait le rythme de notre vitesse de livraison, et certains ont conduit à des conflits nocturnes à résoudre. J'ai eu ces moments "ça ne va pas" à maintes reprises.

## Des conversations à Glossia

Toutes les semaines, nous discutions des nouveaux modèles émergeant autour des capacités des modèles de langage. Nous avons vu de plus en plus de développeurs construire leurs propres pipelines de traduction. Au cœur, ces pipelines proposait un modèle : langue source entrante, traduction sortante, puis continuer.

Ça semblait compréhensible. C'est ainsi que nous, les bâtisseurs, opérons. Mais quelqu'un de plus proche des langues et des processus qui les entourent pouvait voir où ça pourrait mal tourner, de simples incohérences au mieux à des traductions incorrectes au pire.

Les développeurs avancent de plus en plus vite. Ils ne peuvent pas ralentir pour introduire un système dont les workflows sous-jacents ont été conçus bien avant Internet, déployés dans un navigateur, et qui peinent encore à répondre aux besoins des équipes logicielles.

C'est ainsi que l'idée de construire Glossia a commencé. D'un côté, nous aurions parié sur les modèles s'améliorant dans les langues autres que l'anglais et dans la traduction. De l'autre, nous aurions construit un système, initialement axé sur le contenu logiciel, qui semblait plug and play. Quelque chose qui court en arrière-plan, correspond à votre vitesse de livraison, et vous donnant la confiance que la sortie est juste et prête à la production.

De nombreux développeurs traitent la traduction comme une solution à une seule invite. Quelques tokens, anglais entrant, traduction sortante, et c'est fini. Mais quand vous parlez avec eux, vous réalisez qu'ils ne savent pas si la sortie est exacte, capture la voix de leur organisation dans cette langue, ou communique le message prévu efficacement.

J'ai un pipeline similaire chez Tuist, traduisant dans des langues comme le japonais, et je le fais avec un énorme manque de confiance. Les langues ne sont pas la logique. Nous pouvons écrire des tests pour garantir que le format est correct, mais cela ne nous dit pas **si les mots sont corrects**.

« La traduction est la partie facile », comme aime dire ma femme.

Ainsi, nous avons envisagé de découvrir à quoi le bon système pourrait ressembler. Nous l'avons appelé Glossia, et nous commençons à l'ouvrir aux personnes et organisations intéressées par nous aider à l'itérer ensemble.

## Décider ce que traduire

La première chose sur laquelle nous avons misé était d'aider les gens à décider quoi traduire. Le coût de la traduction baisse et continuera de baisser, mais il ne sera jamais zéro. Les organisations devraient toujours être sélectives sur les langues dans lesquelles elles investissent.

Parfois, ce choix découle directement d'une décision commerciale. D'autres fois, les équipes ont une idée approximative de leurs communautés et font une supposition éclairée. Nous pensions qu'il y avait beaucoup à apprendre des personnes visitant vos sites web ou utilisant vos applications. Leurs préférences linguistiques, combinées aux informations sur les régions dont elles utilisent vos produits, peuvent vous donner une meilleure base pour ces décisions.

La première fonctionnalité que nous avons intégrée dans Glossia était l'analytique. Ajoutez une ligne de code à votre site web, et l'analytique commence à affluer vers votre compte. Nous présentons cette information autour de la décision que vous devez prendre : quelles langues devriez-vous investir dans ensuite ?

À l'avenir, nous explorerons comment intégrer des expériences dans la dimension linguistique d'un produit. Imaginez mesurer à quelle fréquence les gens cliquent sur un appel à l'action quand une page utilise différentes voix dans la même langue. N'est-ce pas cool ? Comparer des variantes s'est traditionnellement centré sur les décisions de produit et de design, mais les langues font aussi partie du produit.

## De zéro à traduction

Une fois que vous avez décidé de traduire un projet, la prochaine étape est de le configurer. En tant que développeur, je n'aime pas les processus qui viennent avec beaucoup de friction. Nous sommes d'accord qu'aller de zéro à traduction devrait idéalement ne prendre qu'une étape. C'est le niveau d'expérience que nous visons.

L'installation implique généralement deux choses. D'abord, extraire le contenu du dépôt pour qu'il puisse être traduit, car il commence souvent par des chaînes littérales dans le code. Ensuite, configurer le projet pour choisir le bon contenu en fonction de la langue. Cela peut venir du dispositif de l'utilisateur ou, dans des cas plus sophistiqués, une préférence qu'ils ont choisie.

Automatiser cela de manière fiable il y a quelques années aurait été un cauchemar. Les choses ont changé, et les agents peuvent être assez efficaces à cela.

Le processus se passe ainsi : vous connectez votre dépôt GitHub, sélectionnez les langues dans lesquelles vous voulez traduire, et, après un moment, une demande de tirage s'ouvre avec les changements. Une fois que vous les fusionnez, les traductions commencent à se produire. C'est tout.

Nous conservons les traductions dans le dépôt, aux côtés des vérifications de format et des autres validations que vous exécutez déjà dans le cadre de [continuous integration](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). La pipeline de traduction renvoie les résultats de ces vérifications à l'agent de traduction. Cela élimine une catégorie entière de problèmes où une plateforme ouvre une demande de tirage et vous laisse gérer les échecs de vérification ou les conflits de fusion.

Combiné à d'autres mécanismes de construction de la confiance, c'est ce qui rend possible la fusion automatique des traductions. C'est le modèle que nous croyons. Il y a peu de valeur à demander à un développeur de vérifier si une demande de tirage de traduction est verte et de cliquer sur un bouton, surtout s'il ne peut pas évaluer la langue lui-même. Nous avons toujours vu cette cérémonie supplémentaire comme le signe que la conception pourrait être améliorée.

Nous croyons que le meilleur système de traduction est celui qui fonctionne sans que vous ayez à y réfléchir.

## Traduire uniquement les modifications

Le système de traduction mérite sa propre section. Les jetons ne sont pas encore gratuits. Traduire tout en permanence est lent, coûteux et un gaspillage de ressources.

Pour résoudre cela, nous avons construit un système de fichier de blocage qui nous indique si quelque chose a besoin d'être traduit. Nous appelons cela **traduction incrémentale**. L'idée n'est pas nouvelle : les systèmes de build l'utilisent depuis longtemps pour éviter de tout recompiler à chaque build. Nous l'avons adaptée aux langues.

Le système prend en compte tout le contexte qui affecte une traduction particulière. Une partie de ce contexte réside dans le dépôt. Le reste réside dans Glossia et s'étend sur plusieurs dépôts. Nous construisons un arbre de dépendances et utilisons [Merkle trees](https://en.wikipedia.org/wiki/Merkle_tree) pour calculer des hachages qui nous disent si les entrées d'une traduction ont changé.

Le fichier de blocage préserve cet arbre. Il peut expliquer pourquoi quelque chose a été envoyé pour traduction, ou pourquoi il n'a pas été, au lieu de laisser les gens dans l'incertitude.

[`L10N.md`](/docs/reference/l10n-md) fichiers fournissent un contexte de localisation à nos agents de traduction, tout comme `AGENTS.md` fichiers fournissent des instructions aux agents de codage. Ils supportent un contexte plus spécifique dans les dossiers imbriqués, tout comme des surcharges de langue à chaque niveau.

Pour les informations qui s'appliquent à plus d'un dépôt, comme le vocabulaire partagé, le serveur est la source de vérité. Le système s'assure qu'il utilise le bon contexte et le reflète dans le fichier de blocage. Lorsque ce contexte change, nous pouvons mapper le changement vers les traductions qui l'ont utilisé et doivent être mises à jour.

## Construire la confiance dans les mots

Le système est conçu pour converger vers un niveau de qualité. Pour y parvenir, nous avons plusieurs outils.

Le premier est une vérification antagoniste qui s'exécute après la traduction. Pensez à un collègue qui révise le code que vous avez inclus dans une demande de tirage. Ici, les vérifications apportent une connaissance linguistique à la révision. Par exemple, une traduction ne doit pas ajouter ni enlever de sens à la source. Cela peut arriver car les modèles de langage ne produisent pas toujours la même sortie à partir des mêmes entrées.

Au fur et à mesure que nous en saurons plus grâce à nos utilisateurs et à nos propres recherches sur les modèles et les systèmes existants, nous ajouterons plus de vérifications automatisées à la chaîne. Chacune devrait accroître la confiance que vous pouvez avoir dans une traduction.

L'idée est d'atteindre un point où vous faites confiance au système assez pour ne pas avoir besoin de vérifier chaque demande de tirage. Cette confiance dépend à la fois du système et des modèles. Nous pouvons aider à sélectionner les modèles en fonction de la langue cible, car tous les modèles ne sont pas également bons dans les mêmes langues.

Même avec ces vérifications en place, vous pourriez avoir besoin de modifier un élément traduit. Cela peut être une correction ponctuelle, une terminologie qui n'a pas encore été intégrée au contexte, ou l'un des nombreux scénarios que nous devons encore rencontrer.

Quelqu'un devrait pouvoir apporter ces modifications directement au dépôt. Mais nous pensons aussi que le système devrait traiter ces contributions comme des commentaires et suggérer comment les réconcilier avec son contexte. Cela peut signifier ajouter un terme au glossaire ou ajuster la voix.

C'est quelque chose qu'un humain peut faire de manière asynchrone, sans interrompre la traduction continue. Le système devrait vous aider à le rendre plus efficace dans son travail en apprenant de ce que les gens disent. Nous pourrions étendre cela aux gens qui suggèrent des commentaires directement depuis le produit. N'est-ce pas cool ?

Ces corrections doivent aussi être prises en compte pour que les futures traductions ne les écrasent pas. Un appel de traduction sans état n'a aucune connaissance des changements que les gens ont effectués avant lui. Dans les systèmes traditionnels, les mémoires de traduction aident à combler ce rôle. Le besoin qu'elles servent ne disparaît pas simplement parce que la technologie change.

## Où nous allons d'ici

C'est Glossia. Nous l'utilisons déjà pour traduire Glossia, et je travaille à le configurer pour traduire la documentation, le site de marketing et le tableau de bord de Tuist dans les langues de nos communautés.

María José et moi construisons Glossia dans notre temps libre, suivant une curiosité qui fait partie de nos conversations depuis des années.

En programmation, beaucoup s'interrogent sur le rôle des programmeurs et comment il évoluera. Je pense que l'industrie de la localisation gagnerait à interroger de manière similaire ses hypothèses et modèles. Comment pouvons-nous aider notre industrie à traduire plus, plus vite, et à un coût moindre, sans compromettre la qualité ?

Nous n'avons pas encore toutes les réponses. Mais nous croyons suivre la bonne direction, avec la simplicité et l'attention au métier que nous accordons à tout ce que nous faisons.

Si cela résonne avec vous, [discutons](mailto:pedro@glossia.ai).
