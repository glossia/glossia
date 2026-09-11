%{
  title:
    "Le graphe de contexte : codifier des décennies de théorie linguistique pour l'ère des agents.",
  summary:
    "Les modèles de langage sont puissants, mais ils ont besoin du bon contexte pour produire un excellent contenu. Nous concevons un graphe versionné et orienté pour capturer les connaissances linguistiques et les partager avec les agents, et nous pensons que c'est ce qui permettra à Glossia de se démarquer.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
J'ai beaucoup réfléchi à ce qui fait la différence entre un contenu qui semble généré par une machine et un contenu qui donne l'impression d'avoir été écrit par quelqu'un qui comprend le public, la marque et les nuances culturelles derrière chaque mot. La réponse revient toujours à la même chose : **contexte**.

Les modèles de langage s'améliorent dans les langues, et nous parions sur cette trajectoire qui continue. Ils ne sont pas encore tout à fait là, mais le rythme d'amélioration est difficile à ignorer. Ce qui manque encore, cependant, c'est le système qui se situe entre le modèle et le contenu. L'élément qui indique au modèle *qui* que vous êtes, *comment* vous parlez, *ce qui* compte dans cette phrase particulière, et *pourquoi* cette phrase existe du tout. C'est le problème sur lequel nous travaillons chez Glossia, et je pense qu'il s'agit du plus intéressant du domaine actuellement.

## Trois éléments, deux sous notre contrôle

Quand je regarde ce qu'il faut pour permettre une approche réellement nouvelle au contenu monolingue et multilingue, je vois trois éléments:

1. **Des modèles compétents en matière de langues.** Ils ne sont pas encore tout à fait là, mais ils s'améliorent rapidement et nous parions sur cette tendance. Nous n'avons pas besoin de construire un modèle de fondation. Nous devons être prêts à les utiliser efficacement une fois qu'ils seront parvenus à ce stade.
2. **Un système pour modéliser et partager le contexte dont les agents ont besoin.** C'est l'élément qui se situe entre le modèle et le contenu. La couche qui capture votre voix, votre terminologie, votre ton, vos attentes envers votre public, et sert tout cela à l'agent d'une manière structurée.
3. **Le contexte qui provient des utilisateurs.** Les humains apportent du jugement, une conscience culturelle et une direction créative. Aucun système ne peut pleinement remplacer cela. Mais un système peut le rendre facile à capturer et à réutiliser.

Parmi ces trois, deux sont sous notre contrôle : le système lui-même, et la manière dont nous guidons les utilisateurs pour contribuer du contexte et nous aider à améliorer le système. Nous croyons que réussir les deux est ce qui permettra à Glossia de se distinguer dans un espace qui se remplit rapidement de solutions "connectez simplement un LLM". Le système est là où nous devons codifier des décennies de théorie linguistique dans les primitives qui émergent dans le monde agentique. Et l'expérience utilisateur autour de celui-ci est la manière dont nous nous assurons que le bon contexte est en effet capturé, affiné et renvoyé dans la boucle.

Eugène Nida, l'un des fondateurs des études de traduction modernes, a soutenu que la bonne traduction ne consiste pas en une correspondance mot à mot. Son concept de [l'équivalence dynamique](https://en.wikipedia.org/wiki/Dynamic_equivalence) dit que la relation entre le public cible et le message traduit doit sembler aussi forte que celle entre le public d'origine et la source. C'est une idée magnifique, mais elle nécessite une compréhension contextuelle profonde : qui lit, quel cadre culturel ils apportent, quel ton l'original visait. Ce sont exactement ce genre de choses qui doivent vivre quelque part où un modèle peut y accéder.

## Ce qu'il faut capturer, et comment

L'une des premières choses que nous explorons est quelles informations doivent être capturées, et comment les structurer afin que les agents puissent réellement les utiliser. Plus nous y avons réfléchi, plus nous avons réalisé que ce n'était pas un fichier de configuration plat ou une page de paramètres. Il s'agissait d'un graphe. Précisément, un **[graphe acyclique orienté](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Pourquoi un DAG ? Parce que **le contexte n'est pas plat**. Votre ton de marque influence votre terminologie. Votre terminologie façonne la façon dont vous écrivez sur des fonctionnalités spécifiques. Les attentes de votre public déterminent le niveau de formalité, ce qui affecte à son tour le choix des mots. Ces relations ont une direction et une hiérarchie, et elles ne bouclent pas sur elles-mêmes.

Il existe déjà des précédents ici. Les graphes de connaissances ont été utilisés depuis des années dans les systèmes d'IA pour représenter des relations structurées entre des concepts. Plus récemment, [graphes de contexte](https://grokipedia.com/page/context-graph) ont étendu cette idée en ajoutant des couches de contexte dynamiques, exactement ce genre de chose dont les agents ont besoin pour prendre des décisions éclairées. Et dans le monde multi-agent, [les DAGs sont devenus un modèle fondamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) pour modéliser les dépendances de tâche et les flux d'information.

Mais voici la partie qui passionne vraiment : **chaque nœud de ce graphe doit être versionné**. Lorsque vous changez votre voix de marque, vous ne devez pas perdre d'accès à la version précédente. Lorsque vous mettez à jour une entrée de terminologie, le système doit savoir quel contenu a été produit sous l'ancienne définition et quels éléments pourraient devoir être réexaminés. C'est ce qui nous permet d'optimiser le flux agentique afin qu'il ne soit déclenché que pour les éléments réellement impactés par un changement, plutôt que de tout rejouer.

## Bidirectionnel par conception

Nous croyons que la relation entre les nœuds de contexte et le contenu doit être directionnelle et fonctionner dans les deux sens.

Du côté : vous devez savoir comment le contenu est connecté au contexte. Lorsque le contexte change (disons que la voix de votre marque devient plus décontractée), quels articles de blog, descriptions de produits ou articles d'aide ont été rédigés selon la version précédente ? Ceux-ci doivent être révisés ou retraduits. C'est la **direction avant, du contexte vers le contenu**.

Du côté opposé : lorsqu'un linguiste examine un contenu et se demande pourquoi un choix particulier a été fait, il doit pouvoir remonter jusqu'au contexte qui a guidé la décision. Quelle définition de voix était active ? Quelle règle de terminologie s'appliquait ? Ceci **traçabilité arrière** est ce qui permet aux humains de comprendre ce que les agents ont fait et d'itérer dessus avec confiance.

NASA appelle cela [traçabilité bidirectionnelle](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacité de suivre une association entre des entités dans les deux sens. C'est un principe de l'ingénierie des systèmes, et il s'avère être exactement ce dont vous avez besoin lorsque vous essayez de créer une boucle de rétroaction entre le contexte linguistique et le contenu généré.

Cette qualité bidirectionnelle est ce qui rend **l'amélioration progressive** possible. Un linguiste peut examiner un contenu, voir le contexte qui l'a façonné, décider que la définition de la voix nécessite un ajustement, et créer cet ajustement. Le système sait alors exactement quel autre contenu est affecté par le changement. C'est une boucle serrée, et elle est profondément humaine.

## Au-delà d'un seul dépôt

Il y a une autre dimension à ce graphe que je trouve particulièrement intéressante. **Il ne peut pas vivre dans un seul dépôt.** Le graphe de contexte doit être partageable entre les projets, et potentiellement entre les organisations.

Réfléchissez-y : une entreprise possède une voix de marque. Cette voix s'applique à chaque produit, site web et article d'assistance. Elle ne réside pas dans un seul dépôt. C'est une préoccupation transversale. Vous pouvez définir votre voix de base au niveau de l'organisation, puis appliquer des surrogates au niveau du projet pour un produit ou un public spécifique. Ceci est **l'héritage de portée**, le même modèle auquel nous sommes habitués en programmation, mais appliqué au contexte linguistique.

Et ce contexte doit être versionné correctement. Vous ne pouvez pas simplement modifier la définition de la voix et effacer la version précédente. Il y a beaucoup à apprendre de la manière [Git gère le versionnement](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) à travers le stockage adressable par le contenu et les DAGs. Le modèle de commits, branches et diffs de Git est fondamentalement axé sur le suivi des changements dans le temps tout en conservant l'accès à chaque état précédent. C'est exactement ce dont nous avons besoin pour le contexte linguistique.

En effet, nous pensons qu'un changement de voix devrait se produire via quelque chose que nous appelons une *demande de changement de voix*.

## Tout comme une pull request crée un espace de discussion autour des modifications de code, une demande de changement de voix crée un espace de discussion des modifications linguistiques. Pourquoi passons-nous à un ton plus conversationnel ? Quel impact cela aura-t-il ? Quels contenus seront concernés ? Ce sont des échanges à avoir avant que le changement ne se propage.

Là où les humains deviennent plus créatifs, et non moins pertinents **Et c'est là que les choses commencent à devenir vraiment intéressantes. Au lieu d'éliminer les humains, ce qui est le récit que bon nombre de personnes promeuvent lorsqu'ils parlent de l'IA, ce système**donne aux humains un rôle plus créatif

.

Ou prenons un pas de plus : imaginez des sessions agentiques où un linguiste travaille avec un assistant IA pour explorer des idées linguistiques. "Et si nous rendions les messages d'erreur plus empathétiques ?" L'agent simule l'impact, montre comment le contexte actuel évoluerait, prévisualise ce à quoi le contenu mis à jour pourrait ressembler. Le linguiste affine, ajuste, et lorsqu'ils sont satisfaits, soumet une demande de modification de contexte. N'est-ce pas formidable ?

**Il ne s'agit pas de remplacer le linguiste.** Il s'agit de leur fournir de meilleurs outils pour faire ce qu'ils font déjà si bien : prendre des décisions nuancées et informées culturellement au sujet de la langue. Le système gère les aspects mécaniques (propagation, analyse d'impact, cohérence) tandis que les humains se concentrent sur les aspects créatifs (voix, ton, résonance culturelle).

Je reviens sans cesse à ce que Nida visait avec l'équivalence dynamique. L'objectif n'est pas une précision linguistique au sens mécanique. Il s'agit de créer la même relation ressentie entre le lecteur et le contenu, quelle que soit la langue. Cela requiert du goût, du jugement et une conscience culturelle. Des qualités que les humains maîtrisent remarquablement bien et que les modèles peinent encore à atteindre. La mission du système est de s'assurer que ces connaissances humaines soient capturées, structurées et réutilisables.

## Qu'est-ce qui suit ?

Dans un prochain article, nous aborderons plus en profondeur les aspects techniques et discuterons du rôle que les bacs à sable joueront pour permettre des expériences inédites dans ce domaine, ainsi que des raisons qui nous poussent à investir massivement dans les APIs. Il y a toute une dimension liée à la phase de staging, de la prévisualisation et du test des modifications linguistiques avant leur mise en ligne, que nous sommes pressés d'explorer.

Si tout cela résonne avec vous, que vous soyez un linguiste frustré par l'outillage actuel, un développeur qui a eu du mal avec les workflows de localisation, ou simplement une personne qui réfléchit profondément à l'intersection du langage et de la technologie, nous aimerions entendre de votre part.