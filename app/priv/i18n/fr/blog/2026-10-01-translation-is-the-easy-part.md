%{
  title: "La traduction est la partie facile",
  slug: "translation-is-the-easy-part",
  summary:
    "Comment des conversations sur les langues, la livraison de logiciels et la confiance ont mené María José et moi à construire Glossia.",
  author: "pedro"
}
---

Les langues sont un outil formidable et sous-estimé pour l'accessibilité et pour amener les produits technologiques sur de nouveaux marchés. Quand votre produit s'adresse aux communautés dont la langue principale n'est pas l'anglais, vous signalez que vous y avez pensé. Cela peut établir une connexion très profonde.

Malheureusement, faire que votre produit et votre marque parlent plusieurs langues est quelque chose de nombreuses équipes ne peuvent pas s'offrir. Elles se retrouvent souvent contraintes de choisir deux sur trois : **qualité, rapidité et coût**.

Si elles souhaitent que les traductions gardent le rythme de la livraison de logiciels, elles peuvent investir dans une équipe dédiée pour maintenir la qualité, mais cela entraîne un coût. Ou elles peuvent faire plus confiance à la traduction automatique, avancer rapidement mais accepter une qualité moindre. Si elles choisissent la qualité et un faible coût, en s'appuyant sur la traduction humaine sans équipe dédiée, elles sacrifient généralement la vitesse. En cours de route, elles finissent par adopter des systèmes compliqués poussant et tirant les traductions entre leurs dépôts et des outils tiers.

Depuis l'émergence des [grands modèles de langage](https://en.wikipedia.org/wiki/Large_language_model), ma femme, [María José](https://www.linkedin.com/in/mariajosesalmeron/), et moi nous avons beaucoup discuté de savoir s'ils pouvaient nous aider à cesser de faire ces compromis. Elle adore les langues et est profondément ancrée dans l'industrie de la localisation. Je suis un créateur.

Tuist est mon activité principale. Quand j'ai tenté de traduire le produit et ses surfaces marketing, je me suis retrouvé confronté à des solutions compliquées. Aucune ne tenait le rythme de notre vitesse de livraison, et certaines ont mené à des conflits qui étaient un cauchemar à résoudre. J'ai eu souvent ce moment « ça ne va pas ».

## Des conversations à Glossia

Chaque semaine, nous discutions de nouveaux schémas émergeant autour des capacités des modèles de langage. Nous avons vu plus de développeurs bâtir leurs propres pipelines de traduction. Au cœur de ces pipelines, on trouvait un modèle : langue source entrée, traduction sortie, puis continuer.

Cela semblait compréhensible. C'est ainsi que nous, les créateurs, fonctionnons. Mais quelqu'un plus proche des langues et des processus qui les entourent pourrait voir comment cela pourrait mal tourner, des incohérences au mieux aux erreurs de traduction au pire.

Les développeurs progressent de plus en plus vite. Ils ne peuvent pas ralentir pour introduire un système dont les workflows sous-jacents ont été conçus bien avant internet, déplacés dans un navigateur, et continuent de peiner à répondre aux besoins des équipes logicielles.

C'est ainsi que l'idée de construire Glossia a commencé. D'un côté, nous parierions sur des modèles devenant meilleurs dans d'autres langues que l'anglais et dans la traduction. De l'autre, nous construirions un système, initialement axé sur le contenu logiciel, qui se sent prêt à l'emploi. Quelque chose qui tourne en arrière-plan, cohérent avec votre vitesse de livraison, et vous donnant confiance que la sortie est juste et prête pour la production.

De nombreux développeurs considèrent la traduction comme une solution en un seul prompt. Quelques tokens, l'anglais entrée, la traduction sortie, et c'est fini. Mais quand vous parle avec eux, vous vous rendez compte qu'ils ne savent pas si la sortie est précise, capture la voix de leur organisation dans cette langue, ou communique le message prévu efficacement.

J'ai un pipeline similaire chez Tuist, traduisant dans des langues comme le japonais, et je le fais avec un manque énorme de confiance. Les langues ne sont pas de la logique. Nous pouvons écrire des tests pour nous assurer que le format est correct, mais cela ne nous dit pas **si les mots sont justes**.

« La traduction est la partie facile, », comme aime le dire ma femme.

C'est ainsi que nous nous sommes lancés pour découvrir à quoi ressemblerait le bon système. Nous l'appelons Glossia, et nous commençons à l'ouvrir aux personnes et aux organisations intéressées à nous aider à le faire évoluer ensemble.

## Décider quoi traduire

La première chose sur laquelle nous avons travaillé était d'aider les gens à décider quoi traduire. Le coût de la traduction baisse et continue de baisser, mais il ne sera jamais zéro. Les organisations doivent rester sélectives sur les langues dans lesquelles elles investissent.

Parfois, ce choix découle directement d'une décision commerciale. D'autres fois, les équipes ont une idée générale de leurs communautés et font une estimation éclairée. Nous pensions qu'il y avait beaucoup à apprendre des personnes visitant vos sites ou utilisant vos applications. Leurs préférences linguistiques, combinées à des informations sur les régions depuis lesquelles elles utilisent vos produits, peuvent vous offrir une meilleure base pour ces décisions.

La première fonctionnalité que nous avons intégrée dans Glossia était l'analyse. Ajoutez une ligne de code à votre site web, et les analyses commencent à affluer vers votre compte. Nous présentons ces informations autour de la décision que vous devez prendre : quelles langues devez-vous investir à l'avenir ?

À l'avenir, nous explorerons comment intégrer des expérimentations dans la dimension linguistique d'un produit. Imaginez mesurer à quelle fréquence les personnes cliquent sur un appel à l'action quand une page utilise des voix différentes dans la même langue. Ne serait-ce pas cool ? Comparer des variantes s'est traditionnellement concentré autour des décisions de produit et de design, mais les langues font aussi partie du produit.

## De zéro à traduction

Une fois que vous avez décidé de traduire un projet, l'étape suivante est sa configuration. En tant que développeur, je déteste les processus qui viennent avec beaucoup de friction. Nous avons convenu que passer de zéro à la traduction devrait idéalement ne prendre qu'un seul pas. C'est le niveau d'expérience que nous visons.

La configuration implique généralement deux choses. Premièrement, extraire le contenu du dépôt pour qu'il puisse être traduit, car il commence souvent sous forme de chaînes littérales dans le code. Deuxièmement, configurer le projet pour sélectionner le bon contenu en fonction de la langue. Cela peut provenir du dispositif de l'utilisateur ou, dans des cas plus sophistiqués, une préférence choisie.

Automatiser cela de manière fiable il y a quelques années aurait été un cauchemar. Les choses ont changé, et les agents peuvent être assez efficaces à cet égard.

Le processus se déroule ainsi : vous connectez votre dépôt GitHub, sélectionnez les langues dans lesquelles vous voulez traduire, et, après un certain temps, une demande de fusion s'ouvre avec les modifications. Une fois que vous la fusionnez, les traductions commencent. C'est tout.

Nous conservons les traductions dans le dépôt, aux côtés des vérifications de format et autres validations que vous exécutez déjà dans le cadre de [intégration continue](https://docs.github.com/en/actions/about-github-actions/understanding-github-actions). La pipeline de traduction renvoie les résultats de ces vérifications à l'agent de traduction. Cela élimine toute une catégorie de problèmes où une plateforme ouvre une demande de fusion et vous laisse gérer les échecs de vérification ou les conflits de fusion.

Combiné à d'autres mécanismes destinés à renforcer la confiance, cela permet de fusionner les traductions automatiquement. C'est le modèle que nous croyons. Il n'y a guère de valeur à demander à un développeur de vérifier si une demande de fusion de traduction passe et de cliquer sur un bouton, surtout quand il ne peut pas évaluer la langue lui-même. Nous avons toujours vu cette cérémonie supplémentaire comme un signe indiquant que le design pourrait être amélioré.

Nous croyons que le meilleur système de traduction est celui qui fonctionne sans que vous ayez à y réfléchir.

## Traduire uniquement ce qui a changé

Le système de traduction mérite sa propre section. Les tokens ne sont pas encore gratuits. Traduire tout tout le temps est lent, coûteux et gaspille des ressources.

Pour y remédier, nous avons construit un système de verrouillage de fichier qui nous indique si quelque chose a besoin d'être traduit. Nous appelons cela **traduction incrémentale**. L'idée n'est pas nouvelle : les systèmes de build l'utilisent depuis longtemps pour éviter de tout recompiler à chaque build. Nous avons adapté cette approche aux langues.

Le système prend en compte tout le contexte affectant une traduction particulière. Une partie de ce contexte réside dans le dépôt. Une partie réside dans Glossia et englobe plusieurs dépôts. Nous construisons un arbre de dépendance et utilisons [arbres de Merkle](https://en.wikipedia.org/wiki/Merkle_tree) pour calculer des hachages qui nous indiquent si les entrées d'une traduction ont changé.

Le fichier de verrouillage conserve cet arbre. Il peut expliquer pourquoi quelque chose a été envoyé pour traduction, ou pourquoi il ne l'était, au lieu de laisser les gens deviner.

[`L10N.md`](/docs/reference/l10n-md) fichiers fournissent un contexte de localisation à nos agents de traduction, tout comme `AGENTS.md` fichiers fournissent des instructions aux agents de codage. Ils supportent des contextes plus spécifiques dans des répertoires imbriqués, ainsi que des surcharges de langue à tous les niveaux.

Pour des informations applicables à plusieurs dépôts, comme la terminologie partagée, le serveur est la source de vérité. Le système s'assure qu'il utilise le bon contexte et le reflète dans le fichier de verrouillage. Lorsque ce contexte change, nous pouvons retracer le changement vers les traductions qui l'ont utilisé et nécessitent une mise à jour.

## Renforcer la confiance dans les mots

Le système est conçu pour converger vers un niveau de qualité. Pour y parvenir, nous disposons de plusieurs outils.

Le premier ce sont des vérifications adversaires qui s'exécutent après la traduction. Imaginez un collègue examinant le code que vous avez inclus dans une demande de fusion. Ici, les vérifications apportent des connaissances linguistiques à l'examen. Par exemple, une traduction ne doit pas ajouter ou retirer de sens de la source. Cela peut arriver car les modèles de langue ne produisent pas toujours la même sortie à partir des mêmes entrées.

Comme nous apprenons plus de nos utilisateurs et de nos propres recherches sur les modèles et les systèmes existants, nous ajouterons plus de vérifications automatisées à la pipeline. Chaque l'un devrait augmenter la confiance que vous pouvez avoir dans une traduction.

L'idée est d'atteindre un point où vous faites confiance au système assez pour ne pas avoir besoin de parcourir chaque demande de fusion. Cette confiance dépend à la fois du système et des modèles. Nous pouvons aider à choisir les modèles en fonction de la langue cible, car tous les modèles ne sont pas aussi bons dans les mêmes langues.

Même avec ces vérifications en place, vous pourrez peut-être avoir besoin de modifier une partie traduite. Cela pourrait être une correction ponctuelle, une terminologie qui n'a pas encore été écrite dans le contexte, ou l'une des nombreuses situations que nous sommes encore amener à survenir.

Quelqu'un devrait pouvoir contribuer ces modifications directement au dépôt. Mais nous pensons aussi que le système devrait traiter ces contributions comme des retours d'information et suggérer comment les reconcilier avec son contexte. Cela pourrait signifier ajouter un terme au glossaire ou ajuster la voix.

Cela est quelque chose qu'un humain peut faire asynchronement, sans interrompre la traduction continue. Le système devrait vous aider à le rendre plus efficace dans sa tâche en apprenant de ce que les gens ont à dire. Nous pourrions étendre cela aux personnes proposant des feedback directement depuis le produit. Ne serait-ce pas cool ?

Ces corrections doivent aussi être prises en compte pour que les futures traductions ne les écrasent pas. Un appel de traduction sans état n'a aucune connaissance des modifications que les gens ont faites avant. Dans les systèmes traditionnels, les mémoires de traduction aident à remplir ce rôle. Le besoin qu'elles servent ne disparaît pas simplement parce que la technologie change.

## Où allons-nous à partir d'ici

C'est Glossia. Nous l'utilisons déjà pour traduire Glossia, et je travaille dessus pour le configurer afin de traduire la documentation de Tuist, son site marketing et son tableau de bord dans les langues de nos communautés.

María José et moi construisons Glossia dans notre temps libre, suivant une curiosité qui fait partie de nos conversations depuis des années.

En programmation, beaucoup de gens interrogent le rôle des programmeurs et comment il évoluera. Je pense que l'industrie de la localisation bénéficierait d'un questionnement similaire de ses hypothèses et modèles. Comment pouvons-nous aider notre industrie à traduire plus, plus vite et à moindre coût, sans compromettre la qualité ?

Nous n'avons pas encore de réponses à toutes les questions. Mais nous croyons que nous avançons dans la bonne direction, avec la simplicité et l'attention au savoir-faire que nous aimons mettre dans tout ce que nous faisons.

Si cela résonne avec vous, [discutons-en](mailto:pedro@glossia.ai).
