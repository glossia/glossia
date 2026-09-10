%{
  title:
    "Le graphe de contexte : codifier des décennies de théorie linguistique pour l'ère agentique.",
  summary:
    "Les modèles de langage sont puissants, mais ils ont besoin du bon contexte pour produire un contenu excellent. Nous concevons un graphe versionné et orienté pour capturer les connaissances linguistiques et les partager avec les agents, et nous pensons que c'est ce qui permettra à Glossia de se démarquer.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
J'ai beaucoup réfléchi à ce qui fait la différence entre le contenu qui a l'air généré par une machine et le contenu qui donne l'impression d'avoir été écrit par quelqu'un qui comprend le public, la marque et les nuances culturelles derrière chaque mot. La réponse revient toujours à la même chose : **contexte**,.

Les modèles de langage sont de plus en plus performants en matière de langues, et nous parions sur le fait que cette trajectoire se poursuivra. Ils n'y sont pas encore complètement arrivés, mais le rythme des améliorations est difficile à ignorer. Ce qui manque encore, cependant, c'est le système qui se situe entre le modèle et le contenu. La chose qui dit au modèle *que* vous êtes, *comment* vous parlez, *ce qui* compte dans cette phrase en particulier, et *pourquoi* cette phrase existe dès le début. C'est le problème sur lequel nous travaillons chez Glossia, et je pense qu'il s'agit du plus intéressant de ce domaine actuellement.

## Trois éléments, dont deux que nous contrôlons

Lorsque j'examine ce qui est nécessaire pour mettre en œuvre une approche véritablement nouvelle du contenu monolingue et multilingue, je vois trois éléments :

1. **Les modèles performants pour les langues.** Ils ne sont pas encore totalement prêts, mais ils s'améliorent rapidement et nous parions sur cette tendance. Nous n'avons pas besoin de construire un modèle de fondation. Nous devons être prêts à les utiliser efficacement une fois qu'ils seront à la hauteur.
2. **Un système pour modéliser et partager le contexte dont les agents ont besoin.** Il s'agit de la pièce qui se situe entre le modèle et le contenu. La couche qui capture votre voix, votre terminologie, votre ton, vos attentes du public, et qui sert tout cela à l'agent de manière structurée.
3. **Le contexte qui provient des utilisateurs.** Les humains apportent du jugement, de la conscience culturelle et une direction créative. Aucun système ne peut entièrement remplacer cela. Mais un système peut le rendre facile à capturer et à réutiliser.

Parmi ces trois-là, deux relèvent de notre contrôle : le système lui-même et la façon dont nous guidons les utilisateurs pour contribuer au contexte et nous aider à améliorer le système. Nous croyons qu'obtenir les deux correctement est ce qui permettra à Glossia de se démarquer dans un domaine qui se remplit rapidement de solutions "simplement branchez un LLM". Le système est l'endroit où nous devons codifier des décennies de théorie linguistique dans les primitives qui émergent dans le monde des agents. Et l'expérience utilisateur qui l'entoure est comment nous nous assurons que le bon contexte est réellement capturé, affiné et réinjecté dans la boucle.

Eugène Nida, l'un des fondateurs des études modernes de traduction, a soutenu que la bonne traduction ne concerne pas la correspondance mot à mot. Son concept de [équivalence dynamique](https://en.wikipedia.org/wiki/Dynamic_equivalence) indique que la relation entre le public cible et le message traduit doit sembler identique à celle entre le public original et la source. C'est une belle idée, mais elle nécessite une compréhension contextuelle profonde : qui lit, quel cadre culturel ils apportent, quel ton l'original visait. Ce sont précisément ce genre de chose qui doivent résider quelque part où un modèle puisse y accéder.

## Ce qu'il faut capturer, et comment

L'une des premières choses que nous explorons est quelles informations doivent être capturées, et comment les structurer afin que les agents puissent réellement les utiliser. Plus nous avons réfléchi à cela, plus nous avons réalisé que ce n'était pas un fichier de configuration plat ou une page de paramètres. Il fallait que ce soit un graphe. Plus précisément, un **[graphe acyclique orienté](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Pourquoi un DAG ? Parce que **le contexte n'est pas plat**. La voix de votre marque influence votre terminologie. Votre terminologie façonne la façon dont vous écrivez sur des fonctionnalités spécifiques. Les attentes de votre public déterminent le niveau de formalité, ce qui à son tour affecte le choix des mots. Ces relations ont une direction et une hiérarchie, et elles ne se referment pas sur elles-mêmes.

L'art antérieur est présent ici. Les graphes de connaissances ont été utilisés pendant des années dans les systèmes d'IA pour représenter des relations structurées entre des concepts. Plus récemment, [graphes de contexte](https://grokipedia.com/page/context-graph) ont étendu cette idée en ajoutant des couches de contexte dynamiques, exactement ce que les agents ont besoin pour prendre des décisions éclairées. Et dans le monde multi-agent, [les DAGs sont devenus un modèle fondamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) pour modéliser les dépendances de tâches et le flux d'informations.

Mais voici la partie qui m'enthousiasme : **chaque nœud de ce graphe doit être versionné**. Lorsque vous modifiez votre voix de marque, vous ne devriez pas perdre l'accès à la version précédente. Lorsque vous mettez à jour une entrée terminologique, le système doit savoir quel contenu a été produit sous l'ancienne définition et quels éléments pourraient être réexaminés. C'est ce qui nous permet d'optimiser le flux de travail agentique afin qu'il ne soit déclenché que pour les éléments réellement impactés par une modification, plutôt que de tout rejouer.

## Bidirectionnel par conception

Nous croyons que la relation entre les nœuds de contexte et le contenu doit être directionnelle et fonctionner dans les deux sens.

Du point de vue d'un côté : vous devez savoir comment le contenu est connecté au contexte. Lorsqu'un élément de contexte change (disons, votre ton de marque passe pour être plus décontracté), quels articles de blog, descriptions de produits ou articles d'aide ont été rédigés sous la version précédente ? Ce sont eux qui doivent être réexaminés ou retraduits. C'est **direction avant, du contexte au contenu**,

De l'autre côté : lorsqu'un linguiste examine un bout de contenu et se demande pourquoi tel choix a été fait, il doit pouvoir remonter jusqu'au contexte qui a guidé la décision. Quelle définition de voix était active ? Quelle règle de terminologie s'appliquait ? C'est **traçabilité inverse** est ce qui permet aux humains de comprendre ce que les agents ont fait et d'itérer avec confiance.

NASA l'appelle ainsi [la traçabilité bidirectionnelle](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacité à suivre une association entre des entités dans les deux sens. C'est un principe de l'ingénierie des systèmes, et il s'avère être exactement ce dont vous avez besoin lorsque vous essayez de créer une boucle de rétroaction entre le contexte linguistique et le contenu généré.

C'est cette qualité bidirectionnelle qui rend **l'affinement progressif** possible. Un linguiste peut passer en revue un élément de contenu, voir le contexte qui l'a façonné, décider que la définition de la voix nécessite un ajustement, et appliquer cet ajustement. Le système sait alors précisément quels autres contenus sont affectés par ce changement. C'est une boucle serrée, et c'est profondément humain.

## Au-delà d'un seul dépôt

Il existe une autre dimension de ce graphe que je trouve particulièrement intéressante. **Il ne peut pas vivre dans un seul référentiel.** Le graphe de contexte doit être partageable entre les projets, et potentiellement entre les organisations.

Pensez-y : une entreprise a une voix de marque. Cette voix s'applique à chaque produit, chaque site web, chaque article d'aide. Elle ne vit pas dans un seul dépôt. C'est un sujet transversal. Vous pouvez définir votre voix principale au niveau de l'organisation, puis appliquer des corrections au niveau du projet pour un produit ou un public spécifique. Ceci est **héritage de portée**, le même modèle que nous connaissons en programmation, mais appliqué au contexte linguistique.

Et ce contexte doit être versionné correctement. Vous ne pouvez pas simplement modifier la définition de la voix et effacer la version précédente. Il y a beaucoup à apprendre sur la façon [Git gère la version](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) , via un stockage adressable par le contenu et des DAGs. Le modèle de commits, de branches et de diffs de Git consiste fondamentalement à suivre l'évolution des choses dans le temps tout en préservant l'accès à chaque état précédent. C'est exactement ce dont nous avons besoin pour le contexte linguistique.

En fait, nous pensons qu'un changement de voix devrait survenir à travers quelque chose que nous appelons un *demande de changement de voix*. De même qu'une demande de fusion crée un espace de discussion autour des modifications de code, une demande de changement de voix crée un espace pour discuter des changements linguistiques. Pourquoi passons-nous à un ton plus conversationnel ? Quel impact cela aura-t-il ? Quel contenu sera concerné ? Ce sont des conversations dignes d'intérêt à mener avant que le changement ne se propage.

## Là où les humains deviennent plus créatifs, et non moins pertinents

Et c'est là que les choses deviennent vraiment intéressantes. Au lieu d'éliminer les humains, qui est le récit que beaucoup de gens font valoir lorsqu'ils parlent d'IA, ce système **donne aux humains un rôle plus créatif**.

Imaginez une équipe de linguistes et de stratèges du contenu en session où ils discutent des idées sur l'orientation linguistique de la marque. Ils pourraient explorer des concepts, débattre des changements de ton, faire référence à un contexte culturel auquel aucun modèle n'a accès. Et puis, plutôt que de mettre à jour manuellement des centaines de fichiers, ils capturent leurs décisions en tant qu'ajustements au graphe de contexte. Le système gère la propagation.

Ou prenons cela une étape de plus : imaginez des sessions agentes où un linguiste collabore avec un assistant IA pour explorer des idées linguistiques. \\"Que se passerait-il si nous rendions les messages d'erreur plus empathiques ?\\" L'agent simule l'impact, montre comment le contexte actuel évoluerait, présente un aperçu de ce à quoi le contenu mis à jour pourrait ressembler. Le linguiste affine, ajuste, et lorsqu'il est satisfait, soumet une demande de modification de contexte. N'est-ce pas quelque chose de worthwhile ?

**Il ne s'agit pas de remplacer le linguiste.** Il s'agit plutôt de leur offrir de meilleurs outils pour accomplir ce qu'ils excellent déjà : prendre des décisions nuancées et éclairées culturellement au sujet du langage. Le système gère les aspects mécaniques (propagation, analyse d'impact, cohérence) tandis que les humains se concentrent sur les aspects créatifs (voix, ton, résonance culturelle).

Je reviens sans cesse sur ce que Nida entendait par l'équivalence dynamique. L'objectif n'est pas l'exactitude linguistique au sens mécanique. Il s'agit de créer la même relation ressentie entre le lecteur et le contenu, peu importe la langue. Cela nécessite du goût, du jugement et une sensibilité culturelle. Des compétences dans lesquelles les humains excellent, et que les modèles peinent encore à maîtriser. La tâche du système est de s'assurer que ces apports humains soient capturés, structurés et réutilisables.

## La suite

Dans un prochain article, nous serons plus techniques et parlerons du rôle que les bac à sable joueront dans l'activation d'expériences inédites dans ce domaine, et de la raison pour laquelle nous investissons massivement dans les APIs. Il y a toute une dimension autour de la préproduction, de la prévisualisation et du test des changements linguistiques avant leur mise en ligne que nous sommes ravis d'explorer.

Si cela vous parle, que vous soyez un linguiste frustré par l'outillage actuel, un développeur qui a lutté avec les flux de localisation, ou simplement quelqu'un qui réfléchit profondément à l'intersection entre la langue et la technologie, nous aimerions vous entendre.