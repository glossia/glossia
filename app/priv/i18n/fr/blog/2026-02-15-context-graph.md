%{
  title:
    "Le graphe de contexte : codification de décennies de théorie linguistique pour l'ère des agents",
  summary:
    "Les modèles de langage sont puissants, mais ils ont besoin du bon contexte pour produire un excellent contenu. Nous concevons un graphe versionné et orienté pour capturer les connaissances linguistiques et les partager avec les agents, et nous pensons que c'est ce qui permettra à Glossia de se démarquer.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Je réfléchis beaucoup à ce qui fait la différence entre le contenu qui semble généré par une machine et le contenu qui a l'air d'avoir été écrit par quelqu'un qui comprend le public, la marque et les nuances culturelles derrière chaque mot. La réponse revient toujours au même point : **contexte**.

Les modèles de langage s'améliorent dans les langues, et nous parions sur la poursuite de cette trajectoire. Ils n'y sont pas encore tout à fait parvenus, mais le rythme d'amélioration est difficile à ignorer. Ce qui manque encore, en revanche, c'est le système qui se situe entre le modèle et le contenu. La chose qui indique au modèle *qui* vous êtes, *comment* vous parlez, *ce qui* compte dans cette phrase particulière, et *pourquoi* cette phrase existe en premier lieu. C'est le problème sur lequel nous travaillons chez Glossia, et je pense qu'il s'agit du plus intéressant du domaine en ce moment.

## Trois éléments, deux que nous contrôlons

Lorsque je regarde ce qui est nécessaire pour permettre une nouvelle approche véritablement nouvelle du contenu monolingue et multilingue, je vois trois éléments :

1. **Des modèles excellents en langues.** Ils ne sont pas encore totalement là, mais ils s'améliorent rapidement et nous parions sur cette tendance. Nous n'avons pas besoin de construire un modèle de fondation. Nous devons être prêts à les bien utiliser quand ils y seront.
2. **Un système pour modéliser et partager le contexte dont les agents ont besoin.** C'est le composant qui se situe entre le modèle et le contenu. La couche qui capture votre voix, votre terminologie, votre ton, vos attentes en matière de public, et qui met tout cela à disposition de l'agent de manière structurée.
3. **Le contexte qui provient des utilisateurs.** Les humains apportent jugement, conscience culturelle et orientation créative. Aucun système ne peut entièrement les remplacer. Mais un système peut faciliter la capture et la réutilisation.

De ces trois éléments, deux sont sous notre contrôle : le système lui-même, et la façon dont nous guidons les utilisateurs pour contribuer au contexte et nous aider à améliorer le système. Nous croyons que maîtriser les deux est ce qui permettra à Glossia de se démarquer dans un espace qui se remplit rapidement de solutions "brancher simplement un LLM". Le système est là où nous devons codifier des décennies de théorie linguistique dans les primitives qui émergent dans le monde agentique. Et l'expérience utilisateur autour est celle qui nous permet de nous assurer que le contexte adéquat soit effectivement capturé, affiné et réinjecté dans la boucle.

Eugène Nida, l'un des fondateurs des études modernes sur la traduction, affirmait que la bonne traduction ne relève pas d'une correspondance mot-à-mot. Son concept de [équivalence dynamique](https://en.wikipedia.org/wiki/Dynamic_equivalence) dit que la relation entre le public cible et le message traduit devrait sembler aussi naturelle que celle entre le public d'origine et la source. C'est une idée magnifique, mais elle requiert une compréhension contextuelle approfondie : qui lit, quel cadre culturel ils apportent, quel ton l'original visait. Ce sont précisément les types de choses qui doivent se trouver quelque part où un modèle puisse y accéder.

## Ce que nous devons capturer, et comment

L'une des premières choses que nous explorons est quelle information doit être capturée et comment la structurer afin que les agents puissent vraiment l'utiliser. Plus nous y avons réfléchi, plus nous avons réalisé que ce n'était pas un fichier de configuration plat ou une page de paramètres. Il fallait qu'il s'agisse d'un graphe. Plus précisément, un **[graphe acyclique orienté](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Pourquoi un DAG ? Parce que **le contexte n'est pas plat**. La voix de votre marque influence votre terminologie. Votre terminologie façonne la manière dont vous écrivez sur des fonctionnalités spécifiques. Les attentes de votre audience déterminent le niveau de formalité, ce qui à son tour affecte le choix des mots. Ces relations ont une direction et une hiérarchie, et elles ne se referment pas sur elles-mêmes.

Il y a ici un état de l'art. Les graphes de connaissances ont été utilisés depuis des années dans les systèmes d'intelligence artificielle pour représenter des relations structurées entre les concepts. Plus récemment, [les graphes de contexte](https://grokipedia.com/page/context-graph) ont étendu cette idée en ajoutant des couches de contexte dynamique, exactement le genre de chose dont les agents ont besoin pour prendre des décisions éclairées. Et dans le monde multi-agent, [les DAGs sont devenus un motif fondamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) pour modéliser les dépendances de tâches et les flux d'information.

Mais voici la partie qui me passionne: **chaque nœud de ce graphe doit être versionné**. Lorsque vous modifiez votre voix de marque, vous ne devriez pas perdre l'accès à la version précédente. Lorsque vous mettez à jour une entrée de terminologie, le système doit savoir quel contenu a été produit sous l'ancienne définition et quels éléments pourraient devoir être réexaminés. C'est ce qui nous permet d'optimiser le flux de travail agentique pour qu'il ne soit déclenché que pour les éléments réellement touchés par un changement, plutôt que de tout re-traiter.

## Bidirectionnel par conception

Nous croyons que la relation entre les nœuds de contexte et le contenu doit être directionnelle et fonctionner dans les deux sens.

En y regardant d'un côté : vous devez savoir comment le contenu est connecté au contexte. Lorsqu'un élément de contexte change (par exemple, votre voix de marque passe à un ton plus décontracté), quels articles de blog, descriptions de produits ou articles d'aide ont été rédigés sous la version précédente ? Ce sont ceux qui doivent être revus ou retraduits. C'est la **direction avant, du contexte vers le contenu**.

De l'autre côté : lorsqu'un linguiste examine un élément de contenu et se demande pourquoi un choix particulier a été fait, il doit pouvoir remonter jusqu'au contexte qui a guidé la décision. Quelle définition de voix était active ? Quelle règle de terminologie s'appliquait ? Celle-ci **traçabilité rétroactive** est ce qui permet aux humains de comprendre ce que les agents ont fait et d'itérer dessus en toute confiance.

NASA appelle cela [traçabilité bidirectionnelle](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacité de suivre une association entre des entités dans les deux sens. C'est un principe de l'ingénierie système, et il s'avère qu'il est exactement ce dont vous avez besoin lorsque vous essayez de créer une boucle de rétroaction entre le contexte linguistique et le contenu généré.

Cette qualité bidirectionnelle est ce qui rend **affinement progressif** possible. Un linguiste peut réviser un contenu, voir le contexte qui l'a façonné, décider que la définition de la voix nécessite un ajustement, et créer cet ajustement. Le système sait ensuite exactement quels autres contenus sont affectés par le changement. C'est une boucle serrée, et c'est profondément humain.

## Au-delà d'un seul dépôt

Il y a une autre dimension à ce graphe que je trouve particulièrement intéressante. **Il ne peut pas exister dans un seul dépôt.** Le graphe de contexte doit être partageable entre les projets, et potentiellement entre les organisations.

Pensez-y : une entreprise a une voix de marque. Cette voix s'applique à chaque produit, chaque site web, chaque article de support. Elle ne vit pas dans un seul dépôt. C'est une préoccupation transversale. Vous pouvez définir votre voix centrale au niveau organisationnel, puis appliquer des surcharges au niveau projet pour un produit ou un public donné. Cela est **l'héritage de portée**, le même schéma que nous connaissons en programmation, mais appliqué au contexte linguistique.

Et ce contexte doit être versionné correctement. Vous ne pouvez pas simplement modifier la définition de la voix et effacer la version précédente. Il y a beaucoup à apprendre de la manière [dont Git gère la version des changements](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) par le stockage adressable par le contenu et les DAGs. Le modèle de Git concernant les commits, les branches et les diffs consiste fondamentalement à suivre comment les choses changent au fil du temps tout en préservant l'accès à chaque état précédent. C'est exactement ce dont nous avons besoin pour le contexte linguistique.

En fait, nous pensons qu'un changement de voix devrait survenir via quelque chose que nous appelons un *demande de changement de voix*. À l'instar d'une pull request qui crée un espace de discussion autour des changements de code, une demande de changement de voix crée un espace pour débattre des changements linguistiques. Pourquoi faisons-nous le virage vers un ton plus conversationnel ? Quel impact cela aura-t-il ? Quels contenus seront concernés ? Ce sont des conversations à avoir avant que le changement ne se propage.

## Là où les humains deviennent plus créatifs, et non moins pertinents

Et c'est là que les choses commencent à devenir vraiment intéressantes. Au lieu d'éliminer les humains, ce qui est le récit avancé par la plupart des gens lorsqu'ils parlent d'IA, ce système **confère aux humains un rôle plus créatif**.

Imaginez une équipe de linguistes et de stratèges du contenu en session pour discuter des idées de la direction linguistique de la marque. Ils pourraient explorer des concepts, débattre des changements de ton, faire référence à un contexte culturel auquel aucun modèle n'a accès. Et puis, plutôt que de mettre à jour manuellement des centaines de fichiers, ils capturent leurs décisions en ajustements du graphe de contexte. Le système gère la propagation.

Ou faisons un pas de plus : imaginons des sessions d'agents IA où un linguiste collabore avec un assistant IA pour explorer des idées linguistiques. « Et si nous rendions les messages d'erreur plus empathiques ? » L'agent simule l'impact, montre comment le contexte actuel évoluerait et anticipe à quoi pourrait ressembler le contenu mis à jour. Le linguiste affine, ajuste et lorsqu'il est satisfait, soumet une demande de modification de contexte. N'est-ce pas formidable ?

**Ce n'est pas d'une question de remplacer le linguiste.** Il s'agit de leur donner de meilleurs outils pour faire ce qu'ils font déjà si bien : prendre des décisions subtiles et culturellement informées sur la langue. Le système gère les aspects mécaniques (propagation, analyse d'impact, cohérence) tandis que les humains se concentrent sur les aspects créatifs (voix, ton, résonance culturelle).

Je reviens sans cesse à ce que Nida visait avec l'équivalence dynamique. L'objectif n'est pas la précision linguistique au sens mécanique. Il s'agit de créer le même ressenti entre le lecteur et le contenu, quel que soit le langage. Cela requiert du goût, du jugement et une conscience culturelle. Des qualités que les humains excellent à avoir, et que les modèles peinent encore à maîtriser. Le rôle du système est de s'assurer que ces intuitions humaines soient capturées, structurées et réutilisables.

## À suivre

Dans le prochain article, nous allons approfondir le sujet et parler du rôle que joueront les bacs à sable pour permettre des expériences inédites dans ce domaine, et de l'importance que nous accordons aux API. Il existe toute une dimension autour du staging, de la prévisualisation et du test des modifications linguistiques avant leur mise en ligne que nous sommes ravis d'explorer.

Si cela résonne avec vous, que vous soyez un linguiste frustré par l'outillage actuel, un développeur ayant rencontré des difficultés avec les flux de travail de localisation, ou simplement quelqu'un qui réfléchit profondément à l'intersection entre la langue et la technologie, nous serions ravis de vous entendre.