%{
  title: "Le graphe de contexte : codifier des décennies de théorie linguistique pour l’ère agentique",
  summary: "Les modèles de langage sont puissants, mais ils ont besoin du contexte approprié pour produire du contenu de qualité. Nous concevons un graphe orienté et versionné afin de représenter les connaissances linguistiques et de les partager avec des agents. Nous pensons que cette approche permettra à Glossia de se démarquer.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Je réfléchis beaucoup à ce qui distingue un contenu qui semble généré par une machine d’un contenu qui paraît avoir été écrit par une personne qui comprend le public, la marque et les nuances culturelles derrière chaque mot. La réponse revient toujours au même élément : **le contexte**.

Les modèles de langage maîtrisent de mieux en mieux les langues, et nous parions sur la poursuite de cette évolution. Ils ne sont pas encore tout à fait au point, mais le rythme des progrès est difficile à ignorer. Ce qui manque encore, cependant, c’est le système qui s’interpose entre le modèle et le contenu. Celui qui indique au modèle *qui* vous êtes, *comment* vous vous exprimez, *ce qui* compte dans cette phrase précise et *pourquoi* cette phrase existe. C’est le problème sur lequel nous travaillons chez Glossia, et je pense que c’est actuellement le plus intéressant dans ce domaine.

## Trois éléments, dont deux sous notre contrôle

Lorsque j’examine ce qui est nécessaire pour permettre une approche véritablement nouvelle du contenu monolingue et multilingue, j’identifie trois éléments :

1. **Des modèles qui maîtrisent les langues.** Ils ne sont pas encore tout à fait au point, mais ils progressent rapidement et nous parions sur cette tendance. Nous n’avons pas besoin de développer un modèle de fondation. Nous devons être prêts à bien les utiliser lorsqu’ils seront au point.
2. **Un système pour modéliser et partager le contexte dont les agents ont besoin.** Il s’agit de l’élément qui s’interpose entre le modèle et le contenu. La couche qui recueille votre voix, votre terminologie, votre ton et les attentes de votre public, puis fournit l’ensemble de ces informations à l’agent de manière structurée.
3. **Le contexte fourni par les utilisateurs.** Les humains apportent leur discernement, leur sensibilité culturelle et leur orientation créative. Aucun système ne peut les remplacer entièrement. Mais un système peut faciliter la collecte et la réutilisation de ces éléments.

Parmi ces trois éléments, deux sont sous notre contrôle : le système lui-même, ainsi que la manière dont nous guidons les utilisateurs pour qu’ils apportent du contexte et nous aident à améliorer le système. Nous pensons que la maîtrise de ces deux aspects permettra à Glossia de se distinguer dans un secteur qui se remplit rapidement de solutions consistant simplement à « intégrer un grand modèle de langage ». Le système est l’endroit où nous devons transposer des décennies de théorie linguistique dans les primitives qui émergent dans le monde des agents. L’expérience utilisateur qui l’entoure doit garantir que le contexte pertinent est effectivement recueilli, affiné et réinjecté dans la boucle.

Eugene Nida, l’un des fondateurs de la traductologie moderne, soutenait qu’une bonne traduction ne repose pas sur une correspondance mot à mot. Son concept d’[équivalence dynamique](https://en.wikipedia.org/wiki/Dynamic_equivalence) affirme que la relation entre le public cible et le message traduit doit être ressentie de la même manière que celle qui existe entre le public d’origine et le texte source. C’est une idée remarquable, mais elle exige une compréhension approfondie du contexte : qui lit le texte, quel cadre culturel cette personne mobilise et quel ton le texte d’origine cherchait à adopter. Ce sont précisément les types d’informations qui doivent être stockés dans un espace auquel un modèle peut accéder.

## Ce que nous devons recueillir, et comment

L’une des premières questions que nous avons étudiées est celle des informations à recueillir et de la manière de les structurer pour que les agents puissent réellement les utiliser. Plus nous y avons réfléchi, plus il est devenu évident qu’un simple fichier de configuration ou une page de paramètres ne suffirait pas. Il fallait un graphe. Plus précisément, un **[graphe orienté acyclique](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Pourquoi un graphe orienté acyclique ? Parce que **le contexte n’est pas plat**. La voix de votre marque influence votre terminologie. Votre terminologie détermine la manière dont vous présentez certaines fonctionnalités. Les attentes de votre public définissent le niveau de formalité, qui influence à son tour le choix des mots. Ces relations ont une direction et une hiérarchie, et elles ne forment pas de boucles.

Il existe déjà des précédents. Les graphes de connaissances sont utilisés depuis des années dans les systèmes d’intelligence artificielle pour représenter les relations structurées entre les concepts. Plus récemment, les [graphes contextuels](https://grokipedia.com/page/context-graph) ont étendu cette idée en ajoutant des couches de contexte dynamiques, exactement ce dont les agents ont besoin pour prendre des décisions éclairées. Et dans le monde multi-agents, les [DAG sont devenus un modèle fondamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) pour modéliser les dépendances entre les tâches et les flux d’informations.

Mais voici ce qui me paraît particulièrement prometteur : **chaque nœud de ce graphe doit être versionné**. Lorsque vous modifiez la voix de votre marque, vous ne devez pas perdre l’accès à la version précédente. Lorsque vous mettez à jour une entrée de terminologie, le système doit savoir quels contenus ont été produits selon l’ancienne définition et lesquels pourraient devoir être révisés. Cela nous permet d’optimiser le flux de travail agentique afin qu’il ne se déclenche que pour les éléments réellement affectés par une modification, au lieu de tout retraiter.

## Bidirectionnel par conception

Nous considérons que la relation entre les nœuds de contexte et le contenu doit être directionnelle et fonctionner dans les deux sens.

D’un côté, vous devez savoir comment le contenu est relié au contexte. Lorsqu’un élément de contexte change, par exemple lorsque la voix de votre marque adopte un ton plus informel, quels articles de blog, descriptions de produits ou articles d’aide ont été rédigés selon la version précédente ? Ce sont ceux qui doivent être révisés ou retraduits. Il s’agit de la **direction avant, du contexte vers le contenu**.

De l’autre côté, lorsqu’un linguiste examine un contenu et cherche à comprendre pourquoi un choix particulier a été effectué, il doit pouvoir remonter jusqu’au contexte qui a guidé cette décision. Quelle définition de voix était active ? Quelle règle de terminologie s’appliquait ? Cette **traçabilité en amont** permet aux humains de comprendre ce que les agents ont fait et d’améliorer le résultat en toute confiance.

La NASA appelle cela la [traçabilité bidirectionnelle](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design) : la capacité à suivre une association entre des entités dans les deux sens. Ce principe issu de l’ingénierie des systèmes correspond précisément à ce qui est nécessaire pour créer une boucle de rétroaction entre le contexte linguistique et le contenu généré.

Cette propriété bidirectionnelle rend possible le **raffinement progressif**. Un linguiste peut examiner un contenu, consulter le contexte qui l’a façonné, décider que la définition de voix doit être ajustée, puis effectuer cet ajustement. Le système sait alors exactement quels autres contenus sont affectés par cette modification. La boucle est étroite et profondément humaine.

## Au-delà d’un seul dépôt

Ce graphe présente une autre dimension que je trouve particulièrement intéressante. **Il ne peut pas résider dans un seul dépôt.** Le graphe contextuel doit pouvoir être partagé entre plusieurs projets, voire entre plusieurs organisations.

Prenons un exemple : une entreprise possède une voix de marque. Cette voix s’applique à chaque produit, chaque site web et chaque article d’assistance. Elle ne réside pas dans un seul dépôt. Elle constitue une préoccupation transversale. Vous pouvez définir votre voix principale au niveau de l’organisation, puis appliquer des substitutions au niveau du projet pour un produit ou un public spécifique. Il s’agit de **l’héritage de portée**, le même modèle que celui utilisé en programmation, mais appliqué au contexte linguistique.

Ce contexte doit également être correctement versionné. Vous ne pouvez pas simplement modifier la définition de voix et effacer la version précédente. La manière dont [Git gère le versionnage](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) au moyen d’un stockage adressé par le contenu et de DAG offre de nombreux enseignements. Le modèle de validations, de branches et de différences de Git vise fondamentalement à suivre l’évolution des éléments dans le temps tout en préservant l’accès à chaque état antérieur. C’est exactement ce dont nous avons besoin pour le contexte linguistique.

En réalité, nous pensons qu’un changement de voix devrait passer par ce que nous appelons une *demande de changement de voix*. Tout comme une demande de fusion crée un espace de discussion autour des modifications du code, une demande de changement de voix crée un espace pour discuter des modifications linguistiques. Pourquoi adoptons-nous un ton plus conversationnel ? Quel en sera l’impact ? Quel contenu sera concerné ? Ces échanges méritent d’avoir lieu avant que le changement ne se propage.

## Quand les humains deviennent plus créatifs, sans perdre en pertinence

Et c’est là que les choses deviennent vraiment intéressantes. Au lieu d’écarter les humains, comme le laisse entendre le discours que beaucoup tiennent lorsqu’ils parlent d’intelligence artificielle, ce système **leur confère un rôle plus créatif**.

Imaginez une équipe de linguistes et de spécialistes de la stratégie de contenu réunie pour discuter de l’orientation linguistique de la marque. Elle pourrait explorer des concepts, débattre de changements de ton et s’appuyer sur un contexte culturel auquel aucun modèle n’a accès. Puis, au lieu de mettre à jour manuellement des centaines de fichiers, elle consignerait ses décisions sous forme d’ajustements du graphe de contexte. Le système se chargerait de leur propagation.

Poussons l’idée plus loin : imaginez des sessions agentiques au cours desquelles un linguiste collabore avec un assistant fondé sur l’intelligence artificielle afin d’explorer des pistes linguistiques. « Et si nous rendions les messages d’erreur plus empathiques ? » L’agent simule l’impact, montre comment le contexte actuel évoluerait et donne un aperçu du contenu mis à jour. Le linguiste affine et ajuste le résultat, puis, lorsqu’il en est satisfait, soumet une demande de changement du contexte. Ce serait remarquable, n’est-ce pas ?

**Il ne s’agit pas de remplacer le linguiste.** Il s’agit de lui fournir de meilleurs outils pour accomplir ce qu’il maîtrise déjà : prendre des décisions linguistiques nuancées et éclairées par la culture. Le système gère les aspects mécaniques (propagation, analyse d’impact, cohérence), tandis que les humains se concentrent sur les aspects créatifs (voix, ton, résonance culturelle).

Je reviens sans cesse à ce que Nida cherchait à exprimer avec l’équivalence dynamique. L’objectif n’est pas l’exactitude linguistique au sens mécanique. Il s’agit de créer la même relation sensible entre le lecteur et le contenu, quelle que soit la langue. Cela exige du goût, du discernement et une connaissance culturelle. Autant de qualités que les humains maîtrisent remarquablement bien et qui posent encore problème aux modèles. Le rôle du système consiste à garantir que ces connaissances humaines sont consignées, structurées et réutilisables.

## Prochaine étape

Dans un prochain article, nous entrerons davantage dans les détails techniques pour expliquer le rôle que les sandbox joueront dans la création d’expériences encore inédites dans ce domaine, ainsi que les raisons pour lesquelles nous investissons fortement dans les interfaces de programmation d’applications. Nous sommes impatients d’explorer tout ce qui concerne la préparation, la prévisualisation et le test des changements linguistiques avant leur mise en production.

Si ces idées vous parlent, que vous soyez linguiste insatisfait des outils actuels, développeur confronté aux difficultés des processus de localisation ou simplement une personne qui réfléchit en profondeur aux interactions entre langue et technologie, nous serions ravis d’échanger avec vous.