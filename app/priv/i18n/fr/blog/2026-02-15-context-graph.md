%{
  title: "Le graphe de contexte : codifier des décennies de théorie linguistique pour l'ère des agents",
  summary: "Les modèles de langage sont puissants, mais ils ont besoin du bon contexte pour produire un excellent contenu. Nous concevons un graphe versionné et orienté pour capturer les connaissances linguistiques et les partager avec les agents, et nous pensons que c'est ce qui permettra à Glossia de se démarquer.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
J'ai beaucoup réfléchi à ce qui fait la différence entre un contenu qui semble généré par une machine et un contenu qui donne l'impression d'avoir été écrit par quelqu'un qui comprend le public, la marque et les nuances culturelles derrière chaque mot. La réponse revient toujours au même point : **contexte**.

Les modèles de langage deviennent de plus en plus performants en ce qui concerne les langues, et nous parions sur le fait que cette trajectoire continuera. Ils n'y sont pas encore totalement arrivés, mais le rythme d'amélioration est difficile à ignorer. Ce qui manque encore, pourtant, c'est le système qui se trouve entre le modèle et le contenu. Ce qui indique au modèle *qui* vous êtes, *comment* vous parlez, *ce qui* compte dans cette phrase en particulier, et *pourquoi* cette phrase existe en premier lieu. C'est le problème sur lequel nous travaillons chez Glossia, et je pense que c'est le plus intéressant de l'espace actuel.

## Trois éléments, deux que nous contrôlons

Quand je regarde ce qu'il faut pour permettre une approche véritablement nouvelle pour le contenu monolingue et multilingue, je vois trois éléments :

1. **Des modèles performants dans les langues.** Ils n'y sont pas encore tout à fait, mais ils s'améliorent rapidement et nous parions sur cette tendance. Nous n'avons pas besoin de construire un modèle de fondation. Nous devons être prêts à les utiliser bien quand ils y seront.
2. **Un système pour modéliser et partager le contexte dont les agents ont besoin.** C'est le composant qui se situe entre le modèle et le contenu. La couche qui capture votre voix, votre terminologie, votre ton, les attentes de votre public, et fournit tout cela à l'agent de manière structurée.
3. **Le contexte qui provient des utilisateurs.** Les humains apportent du jugement, une conscience culturelle et une direction créative. Aucun système ne peut pleinement remplacer cela. Mais un système peut le rendre facile à capturer et à réutiliser.

Sur ces trois éléments, deux dépendent de nous : le système lui-même, et la façon dont nous guidons les utilisateurs pour contribuer du contexte et aider à améliorer le système. Nous croyons que réussir les deux permettra à Glossia de se démarquer dans un espace qui se remplit rapidement de solutions « brancher simplement un LLM ». Le système est là où nous devons codifier des décennies de théorie linguistique dans les primitives qui émergent dans le monde agentique. Et l'expérience utilisateur autour de celui-ci est comment nous assurons que le bon contexte est réellement capturé, affiné et réinjecté dans la boucle.

Eugene Nida, l'un des fondateurs des études modernes sur la traduction, a argumenté que la bonne traduction ne vise pas une correspondance mot à mot. Son concept d'[équivalence dynamique](https://en.wikipedia.org/wiki/Dynamic_equivalence) dit que la relation entre le public cible et le message traduit devrait être ressentie comme celle existant entre le public original et la source. C'est une belle idée, mais elle nécessite une compréhension contextuelle profonde : qui lit, quel cadre culturel ils apportent, quel ton l'original visait. Ce sont exactement les types de choses qui doivent résider quelque part où un modèle puisse les accéder.

## Ce dont nous avons besoin de capturer, et comment

L'une des premières choses que nous explorons est quelles informations doivent être capturées, et comment les structurer pour que les agents puissent réellement les utiliser. Plus nous y avons réfléchi, plus nous avons réalisé que ce n'était pas un fichier de configuration plat ou une page de paramètres. Il fallait qu'il soit un graphe. Plus précisément, un **[graphe acyclique orienté](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Pourquoi un DAG ? Parce que **le contexte n'est pas plat**. Votre voix de marque influence votre terminologie. Votre terminologie façonne comment vous écrivez sur des fonctionnalités spécifiques. Les attentes de votre public informent le niveau de formalité, ce qui à son tour affecte le choix des mots. Ces relations ont une direction et une hiérarchie, et elles ne se referment pas en boucle sur elles-mêmes.

Il existe ici des travaux antérieurs. Les graphes de connaissances ont été utilisés pendant des années dans les systèmes d'IA pour représenter des relations structurées entre des concepts. Plus récemment, les [graphes de contexte](https://grokipedia.com/page/context-graph) ont étendu cette idée en ajoutant des couches de contexte dynamiques, exactement ce dont les agents ont besoin pour prendre des décisions éclairées. Et dans le monde multi-agent, les [DAGs sont devenus un schéma fondamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) pour modéliser les dépendances de tâches et le flux d'informations.

Mais voici la partie qui m'enthousiasme : **chaque nœud de ce graphe doit être versionné**. Lorsque vous changez votre voix de marque, vous ne devez pas perdre accès à la version précédente. Lorsque vous mettez à jour une entrée de terminologie, le système doit savoir quel contenu a été produit sous la vieille définition et quelles parties peuvent devoir être réexaminées. C'est ce qui nous permet d'optimiser le flux de travail des agents de sorte qu'il ne déclenche que pour les parties réellement impactées par un changement, plutôt que de tout retraiter.

## Bidirectionnel par conception

Nous croyons que la relation entre les nœuds de contexte et le contenu doit être directionnelle, et elle doit fonctionner dans les deux sens.

D'un point de vue d'un côté : vous devez savoir comment le contenu est connecté au contexte. Lorsqu'une partie du contexte change (disons que votre voix de marque change pour devenir plus décontractée), quels articles de blog, descriptions de produits ou articles d'aide ont été rédigés sous la précédente version ? Ce sont ceux qui doivent être réexaminés ou retraduits. C'est la **direction avant, du contexte vers le contenu**.

De l'autre côté : quand un linguiste examine une pièce de contenu et se demande pourquoi un choix particulier a été fait, il devrait pouvoir le remonter au contexte qui a guidé la décision. Quelle définition de voix était active ? Quelle règle de terminologie a été appliquée ? Cette **traçabilité ascendante** est ce qui permet aux humains de comprendre ce que les agents ont fait et d'itérer dessus avec confiance.

La NASA appelle cela la [traçabilité bidirectionnelle](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design) : la possibilité de suivre une association entre des entités dans les deux sens. C'est un principe de l'ingénierie des systèmes, et s'avère être exactement ce dont vous avez besoin lorsque vous essayez de créer une boucle de rétroaction entre le contexte linguistique et le contenu généré.

Cette qualité bidirectionnelle est ce qui rend possible l'**affinement progressif**. Un linguiste peut examiner une pièce de contenu, voir le contexte qui l'a façonnée, décider que la définition de la voix doit être ajustée, et créer cet ajustement. Le système sait alors exactement quels autres contenus sont touchés par le changement. C'est une boucle serrée, et c'est profondément humain.

## Au-delà d'un seul dépôt

Il existe une autre dimension de ce graphe que je trouve particulièrement intéressante. **Il ne peut pas résider dans un seul dépôt.** Le graphe de contexte doit être partageable à travers des projets, et potentiellement à travers des organisations.

Pensez-y : une entreprise possède une voix de marque. Cette voix s'applique à travers chaque produit, chaque site web, chaque article d'aide. Elle ne réside pas dans un seul dépôt. C'est une préoccupation transversale. Vous pouvez définir votre voix de base au niveau de l'organisation, puis appliquer des overrides au niveau du projet pour un produit ou un public spécifique. C'est l'**héritage de portée**, le même pattern auquel nous sommes habitués en programmation, mais appliqué au contexte linguistique.

Et ce contexte doit être versionné correctement. Vous ne pouvez pas simplement changer la définition de la voix et effacer la version précédente. Il y a beaucoup à apprendre de la façon dont [Git gère la version](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) via le stockage adressable par le contenu et les DAGs. Le modèle de Git pour les commits, les branches et les diffs est fondamentalement axé sur le suivi de l'évolution des choses dans le temps tout en préservant l'accès à chaque état précédent. C'est exactement ce dont nous avons besoin pour le contexte linguistique.

En fait, nous pensons qu'un changement de voix devrait survenir au travers de quelque chose que nous appelons une *demande de changement de voix*. Tout comme un pull request crée un espace pour discuter des modifications de code, une demande de changement de voix crée un espace pour débattre des modifications linguistiques. Pourquoi passons-nous à un ton plus conversationnel ? Quel impact aura-t-il ? Quel contenu sera touché ? Ce sont des conversations à avoir avant que le changement ne se propage.

## Là où les humains deviennent plus créatifs, et non moins pertinents

Et c'est là que les choses deviennent vraiment intéressantes. Au lieu d'éliminer les humains, ce qui est le récit que beaucoup projettent lorsqu'ils parlent de IA, ce système **donne aux humains un rôle plus créatif**.

Imaginez une équipe de linguistes et de stratèges du contenu dans une session où ils débattent des idées sur la direction linguistique de la marque. Ils pourraient explorer des concepts, débattre des changements de ton, et faire référence à un contexte culturel auquel aucun modèle n'a accès. Et puis, plutôt que de mettre à jour manuellement des centaines de fichiers, ils capturent leurs décisions comme des ajustements au graphe de contexte. Le système s'occupe de la propagation.

Ou allez encore plus loin : imaginez des sessions agentiques où un linguiste travaille avec un assistant IA pour explorer des idées linguistiques. « Et si nous rendions les messages d'erreur plus empathétiques ? » L'agent simule l'impact, montre comment le contexte actuel changerait, prévisualise à quoi pourrait ressembler le contenu mis à jour. Le linguiste affine, ajuste, et une fois satisfait, soumet une demande de changement de contexte. Ça ne serait pas quelque chose ?

**Ce n'est pas de remplacer le linguiste.** C'est de leur donner de meilleurs outils pour faire ce qu'ils font déjà si bien : prendre des décisions subtiles, informées culturellement, sur la langue. Le système gère les parties mécaniques (propagation, analyse d'impact, cohérence) tandis que les humains se concentrent sur les parties créatives (voix, ton, résonance culturelle).

Je reviens sans cesse à ce que Nida voulait dire avec l'équivalence dynamique. L'objectif n'est pas la précision linguistique au sens mécanique. Il s'agit de créer le même ressenti de relation entre le lecteur et le contenu, quelle que soit la langue. Cela requiert du goût, du jugement et une conscience culturelle. Des choses en lesquelles les humains sont remarquablement bons, et que les modèles peinent encore à gérer. Le rôle du système est de s'assurer que ces intuitions humaines soient capturées, structurées et réutilisables.

## Qu'est-ce qui suit

Dans un prochain article, nous allons devenir plus techniques et parler du rôle que des bac à sable joueront dans la création d'expériences non encore vues dans cet espace, et pourquoi nous investissons massivement dans les API. Il y a toute une dimension autour du staging, de la prévisualisation et du test des modifications linguistiques avant qu'elles ne soient mises en production que nous sommes impatients d'explorer.

Si tout cela résonne avec vous, que vous soyez un linguiste frustré par les outils actuels, un développeur qui a eu du mal avec les flux de travail de localisation, ou simplement quelqu'un qui réfléchit en profondeur sur comment la langue et la technologie s'entrelacent, nous aimerions avoir vos retours.