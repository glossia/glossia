%{
  title: "La traduction est la partie facile",
  slug: "translation-is-the-easy-part",
  summary:
    "Comment les conversations sur les langues, la livraison de logiciels et la confiance ont conduit María José et moi à construire Glossia.",
  author: "pedro"
}
---
Les langues constituent un outil formidable et sous-estimé pour l'accessibilité et la conquête de nouveaux marchés technologiques. Lorsque votre produit s'adresse à des communautés dont la langue principale n'est pas l'anglais, vous prouvez que vous les avez pensés. Cela peut établir un lien très profond.

Malheureusement, faire en sorte que votre produit et votre marque parlent plusieurs langues est quelque chose dont de nombreuses équipes ne peuvent pas se permettre. Elles se retrouvent souvent contraintes de choisir deux sur trois : **qualité, rapidité et coût**.

Si elles souhaitent que les traductions suivent le rythme de la livraison de logiciels, elles peuvent investir dans une équipe dédiée pour maintenir la qualité, mais cela a un coût. Ou elles peuvent miser davantage sur la traduction automatique, en allant vite mais en acceptant moins de qualité. Si elles optent pour la qualité et le faible coût, en s'en remettant à la traduction humaine sans équipe dédiée, elles sacrifient généralement la vitesse. Sur le chemin, elles finissent par se retrouver avec des systèmes compliqués qui poussent et tirent les traductions entre leurs dépôts et les outils tiers.

Depuis [les grands modèles de langage](https://en.wikipedia.org/wiki/Large_language_model) sont apparus, ma femme, [María José](https://www.linkedin.com/in/mariajosesalmeron/), et j'ai beaucoup discuté pour savoir s'ils pouvaient nous aider à arrêter de faire ces compromis. Elle aime les langues et est profondément intégrée à l'industrie de la localisation. Je suis un créateur.

Tuist est mon principal métier. Quand j'ai essayé de traduire le produit et ses surfaces de marketing, je me suis retrouvé confronté à des solutions compliquées. Aucun ne tenait le rythme de notre rapidité de livraison, et certains entraînaient des conflits, un cauchemar à résoudre. J'ai eu ce moment " ça sent faux " à maintes reprises.

## De conversations à Glossia

Toutes les semaines, nous discutions de nouveaux modèles émergents autour des capacités des modèles de langage. Nous avons vu de plus en plus de développeurs construire leurs propres pipelines de traduction. À leur base, ces pipelines imposaient un modèle : langue source d'entrée, traduction sortie, puis continuer.

Ça semblait compréhensible. C'est ainsi que nous, les créateurs, opérons. Mais quelqu'un plus proche des langues et des processus qui les entourent pouvait voir comment cela pourrait mal tourner, de l'incohérence au mieux, aux mauvaises traductions au pire.

Les développeurs accélèrent de plus en plus. Ils ne peuvent pas ralentir pour introduire un système dont les flux de travail sous-jacents ont été conçus long avant l'internet, migrés dans un navigateur, et qui peinent encore à répondre aux besoins des équipes logicielles.

C'est comment l'idée de créer Glossia a commencé. D'un côté, nous parions sur les modèles améliorant les autres langues et la traduction. De l'autre, nous construirions un système, initialement axé sur le contenu logiciel, conçu pour être plug and play. Quelque chose qui tournerait en arrière-plan, s'alignant sur votre vitesse de livraison, et vous donnant la confiance que le résultat est juste et prêt pour la production.

Beaucoup de développeurs traitent la traduction comme une solution à une seule invite. Quelques tokens, anglais en entrée, traduction en sortie, et c'est fini. Mais quand vous parlez avec eux, vous réalisez qu'ils ignorent si le résultat est précis, s'il capture la voix de leur organisation dans cette langue, ou s'il communique le message prévu de manière efficace.

J'ai un pipeline similaire chez Tuist, traduisant dans des langues comme le japonais, et je le fais avec un gros manque de confiance. Les langues ne sont pas de la logique. Nous pouvons écrire des tests pour nous assurer que le format est correct, mais cela ne nous indique pas **si les mots sont justes**.

« La traduction, c'est la partie facile, » comme aime à le dire ma femme.

Alors nous avons entrepris de déterminer à quoi le système idéal pourrait ressembler. Nous l'avons appelé Glossia, et nous commençons à l'ouvrir aux personnes et organisations intéressées à nous aider à l'améliorer ensemble.

## Décider quoi traduire

Le premier élément sur lequel nous nous sommes axés était d'aider les gens à décider quoi traduire. Le coût de la traduction diminue et continuera de diminuer, mais il ne sera jamais nul. Les organisations devraient demeurer sélectives concernant les langues dans lesquelles elles investissent.

Parfois, ce choix découle directement d'une décision commerciale. D'autres fois, les équipes ont une idée approximative de leurs communautés et font une hypothèse éclairée. Nous pensions qu'il y avait beaucoup à apprendre des personnes visitant vos sites web ou utilisant vos applications. Leurs préférences linguistiques, combinées aux informations sur les régions depuis lesquelles elles utilisent vos produits, peuvent vous offrir une meilleure base pour ces décisions.

La première fonctionnalité de Glossia que nous avons ajoutée est l'analyse. Ajoutez une ligne de code à votre site web et l'analyse commence à affluer vers votre compte. Nous présentons ces informations autour de la décision que vous devez prendre : dans quels langages devriez-vous investir à l'avenir ?

À terme, nous explorerons comment intégrer des expérimentations à la dimension linguistique d'un produit. Imaginez mesurer à quelle fréquence les personnes cliquent sur un appel à l'action lorsqu'une page utilise différentes voix dans la même langue. N'est-ce pas cool ? Comparer des variantes s'est traditionnellement concentré sur les décisions de produit et de design, mais les langues font aussi partie du produit.

## De zéro à traduction

Une fois que vous avez décidé de traduire un projet, la prochaine étape est de le configurer. En tant que développeur, je déteste les processus qui comportent beaucoup de friction. Nous sommes convenus que passer de zéro à la traduction devrait idéalement ne prendre qu'une étape. C'est le niveau d'expérience que nous visons.

La configuration implique généralement deux points. Premièrement, extraire le contenu du dépôt afin qu'il puisse être traduit, car il commence souvent sous forme de chaînes de caractères littérales dans le code. Deuxièmement, configurer le projet pour sélectionner le bon contenu en fonction de la langue. Cela peut provenir du dispositif de l'utilisateur ou, dans des cas plus sophistiqués, d'une préférence qu'ils ont choisie.

L'automatisation de cela de manière fiable il y a quelques années aurait été un véritable cauchemar. Les choses ont changé, et les agents peuvent être assez efficaces pour cela.

Le processus se déroule comme ceci : vous connectez votre dépôt GitHub, sélectionnez les langues dans lesquelles vous souhaitez traduire, puis, après un certain temps, une pull request s'ouvre avec les modifications. Une fois que vous la fusionnez, les traductions commencent. C'est tout.

Nous conservons les traductions dans le dépôt, aux côtés des contrôles de format et des autres validations que vous exécutez déjà dans le cadre de [l'intégration continue](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). Le pipeline de traduction renvoie les résultats de ces contrôles à l'agent de traduction. Cela élimine une large catégorie de problèmes où une plateforme ouvre un pull request et vous laisse gérer des contrôles échoués ou des conflits de fusion.

Combiné à d'autres mécanismes pour établir la confiance, c'est cela qui permet de fusionner les traductions automatiquement. C'est le modèle que nous croyons. Il n'y a guère de valeur à demander à un développeur de vérifier si une pull request de traduction est verte et cliquer sur un bouton, surtout lorsqu'ils ne peuvent pas évaluer le langage eux-mêmes. Nous avons toujours considéré cette cérémonie supplémentaire comme un signe indiquant que la conception pourrait être améliorée.

Nous pensons que le meilleur système de traduction est celui qui fonctionne sans que vous ayez à y penser.

## Traduire uniquement ce qui a changé

Le système de traduction mérite sa propre section. Les tokens ne sont pas gratuits. Traduire tout en permanence est lent, coûteux et gaspille des ressources.

Pour y remédier, nous avons conçu un système de fichiers de verrouillage qui nous indique si quelque chose doit être traduit. Nous appelons cela **traduction incrémentale**. Cette idée n'est pas nouvelle : les systèmes de compilation l'utilisent depuis longtemps pour éviter de tout recompiler à chaque compilation. Nous avons adapté cela aux langages.

Le système prend en compte tout le contexte affectant une traduction spécifique. Une partie de ce contexte réside dans le référentiel. Une autre réside dans Glossia et s'étend sur plusieurs référentiels. Nous construisons un arbre de dépendances et utilisons [les arbres de Merkle](https://en.wikipedia.org/wiki/Merkle_tree) pour calculer des hachages indiquant si les entrées d'une traduction ont changé.

Le fichier de verrouillage préserve cet arbre. Il peut expliquer pourquoi un élément a été envoyé pour traduction, ou pourquoi il ne l'a pas été, plutôt que de laisser les utilisateurs dans le doute.

[`L10N.md`](/docs/reference/l10n-md) les fichiers fournissent un contexte de localisation à nos agents de traduction, tout comme `AGENTS.md` les fichiers fournissent des instructions aux agents de codage. Ils prennent en charge un contexte plus précis dans les sous-répertoires, ainsi que des surcharges linguistiques à chaque niveau.

Pour les informations qui s'appliquent à plusieurs dépôts, telles que la terminologie partagée, le serveur est la source de vérité. Le système s'assure d'utiliser le bon contexte et de le refléter dans le fichier de verrouillage. Quand ce contexte change, nous pouvons relier le changement aux traductions qui l'ont utilisé et qui nécessitent une mise à jour.

## Construire la confiance dans les mots

Le système est conçu pour converger vers un niveau de qualité. Pour y parvenir, nous disposons de plusieurs outils.

Le premier sont les vérifications adversaires qui s'exécutent après la traduction. Imaginez un collègue examinant le code que vous avez inclus dans une demande de modification. Ici, les vérifications apportent des connaissances linguistiques dans l'examen. Par exemple, une traduction ne doit pas ajouter ou retirer de sens à la source. Cela peut survenir car les modèles linguistiques ne produisent pas toujours le même résultat à partir des mêmes entrées.

À mesure que nous apprenons davantage auprès de nos utilisateurs et grâce à notre propre recherche sur les modèles et les systèmes existants, nous ajouterons plus de contrôles automatisés au pipeline. Chacun d'eux devrait augmenter la confiance que vous pouvez avoir en une traduction.

L'idée est d'atteindre un point où vous faites assez confiance au système pour ne pas ressentir le besoin de passer en revue chaque demande de modification. Cette confiance repose à la fois sur le système et sur les modèles. Nous pouvons vous aider à choisir les modèles en fonction de la langue cible, car tous les modèles ne sont pas aussi performants pour les mêmes langues.

Même si ces vérifications sont en place, vous devrez peut-être modifier un élément traduit. Il pourrait s'agir d'une correction ponctuelle, d'une terminologie qui n'est pas encore intégrée au contexte, ou l'un des nombreux scénarios que nous allons encore rencontrer.

Il faudrait pouvoir contribuer ces modifications directement au dépôt. Mais nous pensons aussi que le système doit traiter ces contributions comme des retours et suggérer comment les concilier avec son contexte. Cela pourrait signifier l'ajout d'un terme au glossaire ou l'ajustement de la voix.

Il s'agit de quelque chose qu'une personne peut faire de manière asynchrone, sans interrompre la traduction continue. Le système devrait vous aider à l'orienter pour rendre plus efficace son travail en apprenant de ce que les gens ayant à dire. Nous pourrions étendre cela aux personnes suggérant des retours directement depuis le produit. N'est-ce pas cool ?

Ces corrections doivent également être prises en compte afin que les traductions futures ne les écrasent pas. Une requête de traduction sans état n'a aucune connaissance des modifications effectuées avant elle. Dans les systèmes traditionnels, les mémoires de traduction aident à combler ce rôle. Le besoin qu'elles servent ne disparaît pas simplement parce que la technologie évolue.

## Où nous en allons

C'est Glossia. Nous l'utilisons déjà pour traduire Glossia, et je travaille à sa mise en place afin de traduire la documentation de Tuist, son site marketing et son tableau de bord dans les langues de nos communautés.

María José et moi construisons Glossia dans notre temps libre, suivant une curiosité qui fait partie de nos conversations depuis des années.

En programmation, beaucoup de gens questionnent le rôle des programmeurs et son évolution. Je pense que l'industrie de la localisation bénéficierait d'un questionnement similaire sur ses hypothèses et modèles. Comment pouvons-nous aider notre industrie à traduire plus, plus vite et à moindre coût, sans compromettre la qualité ?

Nous n'avons pas encore les réponses à toutes les questions. Mais nous croyons aller dans la bonne direction, avec la simplicité et le savoir-faire que nous apportons à tout ce que nous faisons.

Si cela vous parle, [Discutons-en](mailto:pedro@glossia.ai).