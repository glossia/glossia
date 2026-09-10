%{
  title:
    "Le graphe de contexte : codifier des décennies de théorie linguistique pour l'ère des agents",
  summary:
    "Les modèles de langage sont puissants, mais ils ont besoin du bon contexte pour produire un excellent contenu. Nous concevons un graphe versionné et orienté pour capturer les connaissances linguistiques et les partager avec les agents, et nous pensons que c'est ce qui permettra à Glossia de se démarquer.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
J'y réfléchis beaucoup à ce qui fait la différence entre du contenu qui sonne généré par machine et du contenu qui donne l'impression d'avoir été écrit par quelqu'un qui comprend le public, la marque et les nuances culturelles derrière chaque mot. La réponse revient toujours à la même chose : **contexte**.

Les modèles linguistiques deviennent meilleurs dans les langues, et nous parions sur le fait que cette trajectoire continue. Ils ne sont pas tout à fait là encore, mais le rythme d'amélioration est difficile à ignorer. Ce qui manque, cependant, c'est le système qui se situe entre le modèle et le contenu. Ce qui informe le modèle *qui* vous êtes, *comment* vous parlez, *ce qui* importe dans cette phrase particulière, et *pourquoi* cette phrase existe en premier lieu. C'est le problème sur lequel nous travaillons chez Glossia, et je pense que c'est le plus interessant du domaine pour le moment.

## Trois éléments, deux que nous contrôlons

Lorsque je regarde ce qu'il faut pour permettre une approche véritablement nouvelle au contenu monolingue et multilingue, je vois trois éléments :

1. **Des modèles performants en langues.** Ils ne sont pas encore totalement là, mais ils s'améliorent rapidement et nous parions sur cette tendance. Nous n'avons pas besoin de construire un modèle fondamental. Nous devons être prêts à les utiliser efficacement lorsqu'ils y seront.
2. **Un système pour modéliser et partager le contexte dont les agents ont besoin.** C'est l'élément qui se situe entre le modèle et le contenu. La couche qui capture votre voix, votre terminologie, votre ton, vos attentes du public, et sert tout cela à l'agent de manière structurée.
3. **Le contexte qui vient des utilisateurs.** Les humains apportent le jugement, la conscience culturelle, et une direction créative. Aucun système ne peut supprimer cela. Mais un système peut en faire la capture et la réutilisation faciles.

Parmi ces trois là, nous en contrôlons deux : le système lui-même, et la manière dont nous guidons les utilisateurs pour contribuer du contexte et nous aider à améliorer le système. Nous croyons que réussir les deux est ce qui permettra à Glossia de se démarquer dans un espace qui se remplit rapidement de solutions "il suffit de brancher un LLM". Le système est là où nous devons formaliser des décennies de théorie linguistique dans les primitives qui émergent dans le monde agentique. Et l'expérience utilisateur autour de lui est la façon dont nous nous assurons que le bon contexte est véritablement capturé, raffiné, et réinjecté dans la boucle.

Eugène Nida, l'un des fondateurs des études modernes de traduction, a soutenu que la bonne traduction ne porte pas sur une correspondance mot à mot. Son concept de [l'équivalence dynamique](https://en.wikipedia.org/wiki/Dynamic_equivalence) dit que la relation entre le public cible et le message traduit devrait se sentir aussi naturelle que celle entre le public original et la source. C'est une belle idée, mais elle exige une compréhension contextuelle approfondie : qui lit, quel cadre culturel ils apportent, quel ton l'original visait. Ce sont précisément les types de choses qui doivent vivre quelque part où un modèle puisse les retrouver.

## Ce que nous devons capturer, et comment

L'une des premières choses que nous explorons est quelles informations doivent être capturées et comment les structurer pour que les agents puissent en faire un usage concret. Plus nous y avons réfléchi, plus nous avons réalisé qu'il ne s'agissait pas d'un fichier de configuration plat ni d'une page de paramètres. Il fallait qu'il s'agisse d'un graphe. Plus précisément, un **[graphe acyclique dirigé](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Pourquoi un DAG ? Parce que **le contexte n'est pas plat**. Votre voix de marque influence votre terminologie. Votre terminologie façonne la manière dont vous écrivez sur des fonctionnalités spécifiques. Les attentes de votre audience déterminent le niveau de formalité, ce qui à son tour affecte le choix des mots. Ces relations ont une direction et une hiérarchie, et elles ne bouclent pas sur elles-mêmes.

Il existe déjà des travaux antérieurs ici. Les graphes de connaissances ont été utilisés ces dernières années dans les systèmes d'IA pour représenter des relations structurées entre les concepts. Plus récemment, [graphes de contexte](https://grokipedia.com/page/context-graph) ont étendu cette idée en ajoutant des couches de contexte dynamiques, exactement ce dont les agents ont besoin pour prendre des décisions éclairées. Et dans le monde multi-agent [les DAGs sont devenus un motif fondamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) pour modéliser les dépendances de tâches et le flux d'informations.

Mais voici ce qui me motive : **chaque nœud de ce graphe doit être versionné**. Lorsque vous modifiez le ton de la marque, vous ne devez pas perdre l'accès à la version précédente. Lorsque vous mettez à jour une entrée de terminologie, le système doit savoir quel contenu a été produit sous l'ancienne définition et quelles pièces pourraient nécessiter une révision. C'est ce qui nous permet d'optimiser le flux de travail agentique afin qu'il ne soit déclenché que pour les pièces effectivement impactées par un changement, plutôt que tout retraiter.

## Bidirectionnel par conception

Nous pensons que la relation entre les nœuds de contexte et le contenu doit être directionnelle et qu'elle doit fonctionner dans les deux sens.

D'un point de vue : vous devez savoir comment le contenu est connecté au contexte. Lorsqu'un élément de contexte change (par exemple, votre ton de marque passe à un ton plus décontracté), quels articles de blog, descriptions de produits ou articles d'aide ont été rédigés sur la base de la version précédente ? Ce sont ceux qui doivent être réexaminés ou retraduits. C'est le **direction directe, du contexte au contenu**.

De l'autre côté : lorsqu'un linguiste examine un extrait de contenu et s'interroge sur un choix particulier, il doit pouvoir remonter au contexte qui a guidé la décision. Quelle définition de voix était active ? Quelle règle de terminologie s'appliquait ? Ceci **traçabilité inversée** ce qui permet aux humains de comprendre ce que les agents ont fait et d'itérer dessus avec confiance.

NASA appelle cela [traçabilité bidirectionnelle](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacité de suivre une association entre des entités dans les deux directions. C'est un principe du génie des systèmes, et il se révèle être exactement ce dont vous avez besoin lorsque vous cherchez à créer une boucle de rétroaction entre un contexte linguistique et du contenu généré.

Cette qualité bidirectionnelle est ce qui rend **l'affinement progressif** possible. Un linguiste peut examiner un extrait de contenu, voir le contexte qui l'a façonné, décider que la définition de la voix nécessite un ajustement, et créer cet ajustement. Le système sait alors exactement quels autres contenus sont touchés par ce changement. C'est une boucle serrée, et c'est profondément humain.

## Au-delà d'un seul dépôt

Il existe une autre dimension de ce graphe que je trouve particulièrement intéressante. **Il ne peut vivre dans un seul dépôt.** Le graphe de contexte doit pouvoir être partagé entre projets, et potentiellement entre organisations.

Réfléchissez-y : une entreprise possède une voix de marque. Cette voix s'applique à chaque produit, chaque site web, chaque article de support. Elle ne vit pas dans un seul dépôt. C'est une préoccupation transversale. Vous pouvez définir votre voix centrale au niveau organisationnel, puis appliquer des surcharges au niveau projet pour un produit ou un public spécifique. C'est **"héritage de portée",**le même schéma que nous utilisons en programmation, mais appliqué au contexte linguistique.

Et ce contexte doit être versionné correctement. Vous ne pouvez pas simplement modifier la définition de voix et effacer la version précédente. Il y a beaucoup à apprendre de la façon dont [Git gère le versionnement](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) grâce au stockage adressable par contenu et aux DAGs. Le modèle de Git des commmits, branches et diffs est fondamentalement axé sur le suivi des changements au fil du temps tout en préservant l'accès à chaque état précédent. C'est exactement ce dont nous avons besoin pour le contexte linguistique.

En fait, nous pensons qu'un changement de ton devrait survenir à travers quelque chose que nous appelons une *demande de changement de ton.*. Tout comme une pull request crée un espace de discussion autour des changements de code, une demande de changement de ton crée un espace pour discuter des changements linguistiques. Pourquoi passons-nous à un ton plus conversationnel ? Quel impact cela aura-t-il ? Quels contenus seront touchés ? Ce sont des conversations à avoir avant que le changement ne se propage.

## Là où les humains deviennent plus créatifs, pas moins pertinents

Et c'est là que les choses deviennent vraiment intéressantes. Au lieu d'éliminer les humains, ce qui est le récit que beaucoup de gens promeuvent lorsqu'ils parlent d'IA, ce système **donne aux humains un rôle plus créatif**.

Imaginez une équipe de linguistes et de stratèges du contenu en session pour discuter d'idées concernant la direction linguistique de la marque. Ils pourraient explorer des concepts, débattre de changements de ton, se référer à un contexte culturel auquel aucun modèle n'a accès. Et puis, plutôt que de mettre à jour manuellement des centaines de fichiers, ils capturent leurs décisions sous forme d'ajustements au graphe de contexte. Le système gère la propagation.

Ou poussons cela un cran plus loin : imaginez des sessions agentiques où un linguiste travaille avec un assistant IA pour explorer des idées linguistiques. "Qu'en serait-il si nous rendions les messages d'erreur plus empathiques ?" L'agent simule l'impact, montre comment le contexte actuel changerait, prévisualise à quoi le contenu mis à jour pourrait ressembler. Le linguiste affine, ajuste, et une fois satisfait, soumet une demande de changement de contexte. N'est-ce pas formidable ?

**Il ne s'agit pas de remplacer le linguiste.** Il s'agit de leur offrir de meilleurs outils pour accomplir ce qu'ils font déjà si bien : prendre des décisions nuancées et informées culturellement. Le système prend en charge les aspects mécaniques (propagation, analyse d'impact, cohérence) tandis que les humains se concentrent sur les aspects créatifs (voix, ton, résonance culturelle).

Je reviens constamment à ce que Nida entendait par l'équivalence dynamique. L'objectif n'est pas la précision linguistique dans un sens mécanique. Il s'agit de créer la même relation ressentie entre le lecteur et le contenu, peu importe la langue. Cela demande du goût, du jugement et une conscience culturelle. Des qualités que les humains possèdent remarquablement bien, et que les modèles peinent encore à atteindre. Le rôle du système est de s'assurer que ces intuitions humaines soient captées, structurées et réutilisables.

## La suite

Dans un article suivant, nous entrerons plus dans le vif du sujet et parlerons du rôle que les bacs à sable joueront pour permettre des expériences inédites dans ce domaine, et de la raison pour laquelle nous investissons fortement dans les API. Il y a toute une dimension autour de la préproduction, de la prévisualisation et du test des changements linguistiques avant leur mise en ligne que nous sommes enthousiastes à explorer.

Si cela résonne en vous, que vous soyez un linguiste frustré par les outils actuels, un développeur qui a lutté avec les flux de localisation, ou simplement quelqu'un qui réfléchit profondément à la façon dont le langage et la technologie se croisent, nous aimerions que vous nous contactiez.