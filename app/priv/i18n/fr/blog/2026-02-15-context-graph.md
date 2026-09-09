%{
  title:
    "Le graphe de contexte : codifiant des décennies de théorie linguistique pour l'ère agentique",
  summary:
    "Les modèles de langage sont puissants mais ils ont besoin du bon contexte pour produire un contenu de qualité. Nous concevons un graphe versionné et orienté pour capturer les connaissances linguistiques et les partager avec des agents, et nous pensons que c'est ce qui permettra à Glossia de se démarquer.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Je réfléchis beaucoup à ce qui fait la différence entre un contenu qui a l'air généré par une machine et un contenu qui semble avoir été écrit par quelqu'un qui comprend le public, la marque et les nuances culturelles derrière chaque mot. La réponse revient toujours à la même chose : **contexte**.

Les modèles de langage s'améliorent dans leur maîtrise des langues, et nous parions sur cette trajectoire qui se poursuit. Ils ne sont pas encore tout à fait parvenus, mais le rythme d'amélioration est difficile à ignorer. Cependant, ce qui manque encore, c'est le système qui se situe entre le modèle et le contenu. Ce qui indique au modèle *qui* vous êtes, *comment* vous parlez, *ce qui* importe dans cette phrase précise, et *pourquoi* cette phrase existe en premier lieu. C'est le problème sur lequel nous travaillons à Glossia, et je pense que c'est le plus intéressant de ce secteur actuellement.

## Trois éléments, deux que nous contrôlons

Quand je regarde ce qui est nécessaire pour permettre une approche véritablement nouvelle concernant le contenu monolingue et multilingue, je vois trois éléments :

1. **Des modèles performants en matière de langues.** Ils ne sont pas encore tout à fait prêts, mais ils progressent rapidement et nous parions sur cette tendance. Nous n'avons pas besoin de construire un modèle de fondation. Nous devons être prêts à les utiliser efficacement quand ils y parviendront.
2. **Un système pour modéliser et partager le contexte dont les agents ont besoin.** C'est la pièce qui se situe entre le modèle et le contenu. La couche qui capture votre voix, votre terminologie, votre ton, les attentes de votre public, et sert tout cela à l'agent de manière structurée.
3. **Le contexte issu des utilisateurs.** Les humains apportent du jugement, une conscience culturelle et une direction créative. Aucun système ne peut entièrement remplacer cela. Mais un système peut rendre facile la capture et la réutilisation.

De ces trois, nous en avons deux que nous contrôlons : le système lui-même, et la manière dont nous guidons les utilisateurs pour contribuer du contexte et nous aider à améliorer le système. Nous croyons que maîtriser les deux est ce qui fera de Glossia se démarquer dans un espace qui se remplit rapidement de solutions de "brancher un LLM". Le système est l'endroit où nous devons codifier des décennies de théorie linguistique dans les primitives qui émergent dans le monde des agents. Et l'expérience utilisateur autour de lui est la façon dont nous nous assurons que le bon contexte soit effectivement capté, affiné et réinjecté dans la boucle.

Eugène Nida, l'un des pères fondateurs des études de traduction modernes, affirmait que la bonne traduction ne se résume pas à une correspondance mot à mot. Son concept de [l'équivalence dynamique](https://en.wikipedia.org/wiki/Dynamic_equivalence) dit que la relation entre le public cible et le message traduit doit sembler la même que celle entre le public original et la source. C'est une idée magnifique, mais elle nécessite une compréhension contextuelle profonde : qui lit, quel cadre culturel ils apportent, quel ton l'original visait. Ce sont exactement ce genre de choses qui doivent vivre quelque part accessible à un modèle.

## Ce que nous devons capturer, et comment

L'un des premiers aspects que nous explorons est quelles informations doivent être capturées et comment les structurer afin que les agents puissent réellement les utiliser. Plus nous y avons réfléchi, plus nous avons réalisé que ce n'était pas un fichier de configuration plat ni une page de paramètres. Il devait s'agir d'un graphe. Plus précisément, un **[graphe orienté acyclique](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Pourquoi un DAG ? Parce que **le contexte n'est pas plat**. Le ton de votre marque influence votre terminologie. Votre terminologie façonne la façon dont vous rédigez sur des fonctionnalités spécifiques. Les attentes de votre audience déterminent le niveau de formalité, ce qui, à son tour, affecte le choix des mots. Ces relations sont dirigées et hiérarchiques, et elles ne forment pas de boucles sur elles-mêmes.

Il existe déjà des antéceptions ici. Les graphes de connaissances ont été utilisés depuis des années dans les systèmes d'IA pour représenter des relations structurées entre des concepts. Plus récemment, [graphes de contexte](https://grokipedia.com/page/context-graph) ont étendu cette idée en ajoutant des couches de contexte dynamiques, exactement le genre de chose dont les agents ont besoin pour prendre des décisions éclairées. Et dans le monde multi-agent, [les DAG sont devenus un schéma fondamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) pour modéliser les dépendances de tâches et le flux d'informations.

Mais voici la partie qui me passionne : **chaque nœud de ce graphe doit être versionné**. Lorsque vous changez votre voix de marque, vous ne devriez pas perdre l'accès à la version précédente. Lorsque vous mettez à jour une entrée terminologique, le système doit savoir quel contenu a été produit sous la définition ancienne et quels éléments pourraient avoir besoin d'être révisés. C'est ce qui nous permet d'optimiser le flux de travail agentique pour qu'il ne soit déclenché que pour les éléments réellement impactés par un changement, plutôt que de tout retraiter.

## Bidirectionnel par conception

Nous croyons que la relation entre les nœuds de contexte et le contenu doit être directionnelle et fonctionnelle dans les deux sens.

En examinant cela d'un côté : vous devez savoir comment le contenu est connecté au contexte. Lorsqu'un élément de contexte change (dites, votre voix de marque passe à un ton plus décontracté), quels articles de blog, descriptions de produits ou articles d'aide ont été rédigés sous la version précédente ? Ce sont ceux qui doivent être revus ou retraduits. C'est la **direction avant, du contexte au contenu**.

De l'autre côté : lorsqu'un linguiste examine un élément de contenu et se demande pourquoi un choix particulier a été fait, il doit pouvoir retracer cela vers le contexte qui a guidé la décision. Quelle définition de voix était active ? Quelle règle de terminologie s'appliquait ? Cette **rétro-traçabilité** est ce qui permet aux humains de comprendre ce que les agents ont fait et d'y itérer avec confiance.

NASA appelle cela [traçabilité bidirectionnelle](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la possibilité de suivre une association entre des entités dans les deux sens. C'est un principe du génie système, et il s'avère être exactement ce dont vous avez besoin lorsque vous essayez de créer une boucle de rétroaction entre le contexte linguistique et le contenu généré.

Cette qualité bidirectionnelle est ce qui rend **l'affinement progressif** possible. Un linguiste peut examiner un contenu, voir le contexte qui l'a façonné, décider que la définition de la voix a besoin d'ajustement, et créer cet ajustement. Le système sait alors exactement quels autres contenus sont affectés par le changement. C'est une boucle serrée, et elle est profondément humaine.

## Au-delà d'un seul référentiel

Il y a une autre dimension de ce graphe que je trouve particulièrement intéressante. **Elle ne peut pas exister dans un seul dépôt.** Le graphe de contexte doit être partageable entre les projets, et potentiellement entre les organisations.

Pensez-y : une entreprise a une voix de marque. Cette voix s'applique à chaque produit, chaque site web, chaque article de support. Elle ne vit pas dans un seul dépôt. C'est un enjeu transversal. Vous pouvez définir votre voix centrale au niveau de l'organisation, puis appliquer des surcharges au niveau du projet pour un produit ou une audience spécifique. C'est **héritage de portée**, le même modèle auquel nous sommes habitués en programmation, mais appliqué au contexte linguistique.

Et ce contexte doit être versionné correctement. Vous ne pouvez pas simplement modifier la définition de la voix et effacer la version précédente. Il y a beaucoup à apprendre sur la façon dont [Git gère les versions](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) par le stockage adressable par le contenu et les graphes acycliques dirigés (DAG). Le modèle Git de commits, branches et diffs repose fondamentalement sur le suivi des changements au fil du temps tout en préservant l'accès à chaque état précédent. C'est exactement ce dont nous avons besoin pour le contexte linguistique.

En fait, nous pensons qu'un changement de voix devrait se faire à travers quelque chose que nous appelons une *demande de changement de voix*. Tout comme une pull request crée un espace pour discuter des changements de code, une demande de changement de voix crée un espace pour discuter des modifications linguistiques. Pourquoi évoyons-nous un ton plus conversationnel ? Quel sera l'impact ? Quels contenus seront affectés ? Ce sont des conversations à avoir avant que le changement ne se propage.

## Là où les humains deviennent plus créatifs, et non moins pertinents

Et c'est ici que les choses commencent à devenir vraiment intéressantes. Plutôt que d'éliminer les humains, ce qui est le récit que beaucoup promeuvent lorsqu'ils parlent de l'IA, ce système **donne aux humains un rôle plus créatif**.

Imaginez une équipe de linguistes et de stratèges de contenu ayant une session où ils discutent des idées sur l'orientation linguistique de la marque. Ils pourraient explorer des concepts, débattre des changements de ton, se référer à un contexte culturel inaccessible aux modèles. Ensuite, au lieu de mettre à jour manuellement des centaines de fichiers, ils capturent leurs décisions sous forme d'ajustements au graphe de contexte. Le système s'occupe de la propagation.

Ou prenons cela un cran plus loin : imaginez des sessions d'agents où un linguiste collabore avec un assistant IA pour explorer des idées linguistiques. « Que se passerait-il si nous rendions les messages d'erreur plus empathiques ? » L'agent simule l'impact, montre comment le contexte actuel changerait, et anticipe à quoi pourrait ressembler le contenu mis à jour. Le linguiste affine, ajuste, et lorsqu'il est satisfait, soumet une demande de changement de contexte. N'est-ce pas formidable ?

**Il ne s'agit pas de remplacer le linguiste.** Il s'agit de leur offrir de meilleurs outils pour faire ce qu'ils excellent déjà à faire : prendre des décisions nuancées et culturellement informées sur la langue. Le système gère les aspects mécaniques (propagation, analyse d'impact, cohérence), tandis que les humains se concentrent sur les aspects créatifs (voix, ton, résonance culturelle).

Je reviens souvent à l'idée de Nida avec l'équivalence dynamique. L'objectif n'est pas l'exactitude linguistique au sens mécanique. Il s'agit de créer la même relation ressentie entre le lecteur et le contenu, quelle que soit la langue. Cela requiert du goût, du jugement et une conscience culturelle. Des qualités dont les humains font preuve de manière remarquable, et avec lesquelles les modèles peinent encore. La mission du système est d'assurer que ces intuitions humaines soient capturées, structurées et réutilisables.

## La suite

Dans un article complémentaire, nous approfondirons le point technique et discuterons du rôle que les bacs joueront pour permettre des expériences inédites dans ce domaine, et de notre investissement massif dans les API. Il existe une dimension entière autour de la mise en production, de la prévisualisation et du test des modifications linguistiques avant leur mise en ligne que nous sommes impatients d'explorer.

Si cela résonne avec vous, que vous soyez un linguiste frustré par l'outillage actuel, un développeur en butte à des problèmes de flux de travail de localisation, ou simplement une personne qui réfléchit profondément à l'intersection entre la langue et la technologie, nous aimerions vous lire.