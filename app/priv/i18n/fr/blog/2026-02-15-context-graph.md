%{
  title:
    "Le graphe de contexte : codifier des décennies de théorie linguistique pour l'ère agentique.",
  summary:
    "Les modèles de langage sont puissants, mais ils ont besoin du contexte adéquat pour générer un excellent contenu. Nous concevons un graphe versionné et orienté pour capturer les connaissances linguistiques et les partager avec les agents, et nous pensons que c'est ce qui permettra à Glossia de se démarquer.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
J'ai beaucoup réfléchi à ce qui fait la différence entre un contenu qui a l'air généré par une machine et un contenu qui semble écrit par quelqu'un qui comprend le public, la marque, et les nuances culturelles derrière chaque mot. La réponse revient toujours à la même chose : **le contexte**.

Les modèles de langage s'améliorent, et nous parions sur le fait que cette trajectoire continuera. Ils ne le sont pas encore intégralement, mais le rythme de l'amélioration est difficile à ignorer. Ce qui manque, cependant, c'est le système qui se trouve entre le modèle et le contenu. L'élément qui dicte au modèle *qui* vous êtes, *comment* vous parlez, *ce qui* compte dans cette phrase précise, et *pourquoi* cette phrase existe en premier lieu. C'est le problème sur lequel nous travaillons chez Glossia, et je pense qu'il est le plus intéressant actuellement dans l'espace.

## Trois éléments, deux sous notre contrôle

Quand je regarde ce qu'il faut pour permettre une approche réellement nouvelle pour le contenu monolingue et multilingue, je vois trois éléments :

1. **Des modèles performants dans les langues.** Ils ne le sont pas encore intégralement, mais ils s'améliorent vite et nous parions sur cette tendance. Nous n'avons pas besoin de construire un modèle fondation. Nous devons être prêts à les utiliser bien quand ils y arriveront.
2. **Un système pour modéliser et partager le contexte dont les agents ont besoin.** C'est la pièce qui se situe entre le modèle et le contenu. La couche qui capture votre voix, votre terminologie, votre ton, vos attentes du public, et sert tout cela à l'agent de manière structurée.
3. **Le contexte qui vient des utilisateurs.** Les humains apportent le jugement, la conscience culturelle et la direction créative. Aucun système ne peut le remplacer entièrement. Mais un système peut le rendre facile à capturer et réutiliser.

De ces trois éléments, il y en a deux que nous maîtrisons : le système lui-même, et la façon dont nous guidons les utilisateurs pour contribuer du contexte et nous aider à améliorer le système. Nous croyons qu'obtenir les deux juste est ce qui fera ressortir Glossia dans un espace qui se remplit rapidement de solutions "brancher simplement un LLM". Le système est là où nous devons codifier des décennies de théorie linguistique dans les primitives qui émergent dans le monde agentique. Et l'expérience utilisateur autour est comment nous nous assurons que le bon contexte est en effet capturé, affiné et réinjecté dans la boucle.

Eugène Nida, l'un des fondateurs des études de traduction modernes, soutenait que la bonne traduction ne repose pas sur une correspondance mot à mot. Son concept [équivalence dynamique](https://en.wikipedia.org/wiki/Dynamic_equivalence) explique que la relation entre le public cible et le message traduit devrait sembler la même que la relation entre le public initial et la source. C'est une idée magnifique, mais elle nécessite une compréhension contextuelle profonde : qui lit, quel cadre culturel ils apportent, quelle tonalité l'original visait. Ce sont exactement ce genre de choses qui doivent vivre quelque part dont un modèle peut y accéder.

## Ce que nous devons capturer, et comment

L'une des premières choses que nous explorons est l'information qui doit être capturée, et comment la structurer pour que les agents puissent réellement l'utiliser. Plus nous avons pensé à cela, plus nous avons réalisé qu'il ne s'agissait pas d'un fichier de configuration plat ou d'une page de paramètres. Il a fallu être un graphe. Plus précisément, un **[graphe acyclique orienté](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Pourquoi un GAO ? Parce que **le contexte n'est pas plat**.

Il existe déjà des précédents en la matière. Les graphes de connaissances ont été utilisés pendant des années dans les systèmes d'IA pour représenter les relations structurées entre les concepts. Plus récemment, les [graphes de contexte](https://grokipedia.com/page/context-graph) ont étendu cette idée en ajoutant des couches de contexte dynamiques, exactement ce dont les agents ont besoin pour prendre des décisions informées. Et dans le monde multi-agent, les [DAGs sont devenus un motif fondamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) pour modéliser les dépendances de tâches et le flux d’information.

Mais voici ce qui m'enthousiasme : **chaque nœud de ce graphe doit être versionné**. Lorsque vouschangez votre ton de marque, vous ne devez pas perdre accès à la version précédente. Lorsque vous mettez à jour une entrée de terminologie, le système doit savoir quel contenu a été produit sous la définition précédente et quels éléments pourraient nécessiter une révision. C'est ce qui nous permet d'optimiser le flux de travail des agents afin qu'il ne soit déclenché que pour les éléments effectivement impactés par un changement, plutôt que de rejouer tout le processus.

## Bidirectionnel par conception

Nous croyons que la relation entre les nœuds de contexte et le contenu doit être directionnelle, et qu'elle doit fonctionner dans les deux sens.

Si l'on regarde d'un côté : vous devez savoir comment le contenu est relié au contexte. Lorsqu'une partie du contexte change (par exemple, votre ton de marque évolue pour devenir plus décontracté), quels articles de blog, descriptions de produits ou articles d'aide ont été rédigés sous la version précédente ? Ce sont ceux qui nécessitent une révision ou une redistribution. C'est la **direction avant, du contexte au contenu**.

De l'autre côté : lorsqu'un linguiste examine un contenu et se demande pourquoi un choix particulier a été fait, il doit pouvoir le relier au contexte qui a guidé la décision. Quelle définition de ton était active ? Quelle règle terminologique s'appliquait ? Cette **traçabilité inverse** est ce qui permet aux humains de comprendre ce que les agents ont fait et de l'itérer avec confiance.

NASA appelle cela [la traçabilité bidirectionnelle](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design) : la capacité de suivre une association entre des entités dans les deux sens. C'est un principe de l'ingénierie système, et il s'avère être exactement ce dont vous avez besoin lorsque vous essayez de créer une boucle de rétroaction entre le contexte linguistique et le contenu généré.

Cette qualité bidirectionnelle est ce qui rend le **raffinement progressif** possible. Un linguiste peut réviser une pièce de contenu, voir le contexte qui l'a façonnée, décider que la définition de la voix nécessite un ajustement, et créer cet ajustement. Le système sait ensuite exactement quel autre contenu est affecté par le changement. C'est une boucle serrée, et c'est profondément humain.

## Au-delà d'un seul dépôt

Il existe une autre dimension à ce graphe que je trouve particulièrement intéressante. **Il ne peut vivre dans un seul dépôt.** Le graphe de contexte doit être partageable entre les projets, et potentiellement entre les organisations.

Pensez-y : une entreprise a un ton de marque. Ce ton s'applique à tous les produits, tous les sites web, tous les articles d'aide. Il ne vit pas dans un seul dépôt. C'est une préoccupation transversale. Vous pouvez définir votre ton de base au niveau de l'organisation, puis appliquer des chevauchements au niveau du projet pour un produit ou un public spécifique. C'est l'**héritage de la portée**, le même motif que nous utilisons en programmation, mais appliqué au contexte linguistique.

Et ce contexte doit être versionné correctement. Vous ne pouvez pas simplement changer la définition du ton et effacer la version précédente. Il y a beaucoup à apprendre de la façon [dont Git gère la versionning](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) grâce au stockage adressable au contenu et aux DAGs. Le modèle de commits, branches et diffs de Git est fondamentalement axé sur la façon dont les choses changent avec le temps, tout en préservant l'accès à chaque état précédent. C'est exactement ce dont nous avons besoin pour le contexte linguistique.

En fait, nous pensons qu'un changement de voix doit se faire par l'intermédiaire de quelque chose que nous appelons une *demande de modification de la voix*. Tout comme une pull request crée un espace pour discuter des changements de code, une demande de modification de la voix crée un espace pour discuter des changements linguistiques. Pourquoi passons-nous à un ton plus conversationnel ? Quel impact aura-t-il ? Quels contenus seront touchés ? Ce sont des conversations qu'il vaut la peine d'avoir avant que le changement ne se propage.

## Là où les humains deviennent plus créatifs, pas moins pertinents

Et c'est là que les choses commencent à devenir vraiment intéressantes. Au lieu d'éliminer les humains, ce qui est le récit que beaucoup poussent lorsqu'ils parlent d'IA, ce système **donne aux humains un rôle plus créatif**.

Imaginez une équipe de linguistes et de stratèges du contenu ayant une séance où ils discutent des idées concernant la direction linguistique de la marque. Ils pourraient explorer des concepts, débattre des changements de ton, faire référence à un contexte culturel auquel aucun modèle n'a accès. Et puis, plutôt que de mettre à jour manuellement des centaines de fichiers, ils capturent leurs décisions sous forme d'ajustements au graphe de contexte. Le système s'occupe de la propagation.

Ou prenez-le une étape de plus : imaginez des séances agentiques où un linguiste travaille avec un assistant IA pour explorer des idées linguistiques. "Et si on rendait les messages d'erreur plus empathiques ?" L'agent simule l'impact, montre comment le contexte actuel changerait, prévisualise à quoi pourrait ressembler le contenu mis à jour. Le linguiste affine, ajuste et, lorsqu'il est satisfait, soumet une demande de modification du contexte. N'est-ce pas quelque chose ?

**Ce n'est pas de remplacer le linguiste.** C'est de leur donner de meilleurs outils pour faire ce qu'ils sont déjà excellents à : prendre des décisions nuancées et informées culturellement sur la langue. Le système gère les parties mécaniques (propagation, analyse d'impact, cohérence) tandis que les humains se concentrent sur les parties créatives (voix, ton, résonance culturelle).

Je reviens sans cesse sur ce que Nida visait avec l'équivalence dynamique. L'objectif n'est pas la justesse linguistique dans un sens mécanique. C'est de créer le même lien ressenti entre le lecteur et le contenu, quel que soit la langue. Cela requiert du goût, du jugement et une conscience culturelle. Des choses pour lesquelles les humains excellent remarquablement, et que les modèles peinent encore à maîtriser. Le rôle du système est de s'assurer que ces insights humains soient capturés, structurés et réutilisables.

## La suite

Dans un prochain article, nous allons être plus technique et parler du rôle que joueront les bacs à sable pour permettre des expériences qui n'ont pas encore été vues, et pourquoi nous investissons lourdement dans les API. Il y a toute une dimension autour de la mise en préproduction, de la prévisualisation et du test des changements linguistiques avant qu'ils ne soient mis en production sur laquelle nous sommes impatients d'explorer.

Si cela résonne avec vous, que vous soyez un linguiste frustré par l'outillage actuel, un développeur qui a eu du mal avec les flux de localisation, ou tout simplement quelqu'un qui pense profondément à l'intersection entre la langue et la technologie, nous aimerions entendre vos dires.