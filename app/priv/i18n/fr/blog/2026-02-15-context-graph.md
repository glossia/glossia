%{
  title:
    "Le graphe de contexte : codification de décennies de théorie linguistique pour l'ère des agents",
  summary:
    "Les modèles de langage sont puissants mais ont besoin du bon contexte pour produire un excellent contenu. Nous concevons un graphe versionné et orienté pour capturer les connaissances linguistiques et les partager avec les agents, et nous pensons que c'est ce qui permettra à Glossia de se démarquer.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Je réfléchis beaucoup à ce qui fait la différence entre un contenu qui semble généré par une machine et un contenu qui semble être écrit par quelqu'un qui comprend le public, la marque et les nuances culturelles derrière chaque mot. La réponse revient toujours à la même chose : **contexte**.

Les modèles de langage s'améliorent sur le plan linguistique, et nous parions sur la poursuite de cette trajectoire. Ils ne sont pas encore totalement là, mais le rythme d'amélioration est difficile à ignorer. Ce qui manque, cependant, est le système qui se situe entre le modèle et le contenu. La chose qui indique au modèle *qui* vous êtes, *comment* vous parlez, *ce qui* importe dans cette phrase en particulier, et *pourquoi* cette phrase existe dès le départ. C'est le problème sur lequel nous travaillons chez Glossia, et je pense qu'il est le plus intéressant du domaine pour le moment.

## Trois éléments, deux que nous contrôlons

Quand je regarde ce qu'il faut pour permettre une véritable nouvelle approche au contenu monolingue et multilingue, je vois trois éléments :

1. **Des modèles performants pour les langues.** Ils ne sont pas encore totalement là, mais ils s'améliorent rapidement et nous parions sur cette tendance. Nous n'avons pas besoin de construire un modèle de fondation. Nous devons être prêts à les utiliser bien quand ils y seront.
2. **Un système pour modéliser et partager le contexte dont les agents ont besoin.** C'est le composant qui se situe entre le modèle et le contenu. La couche qui capte votre voix, votre terminologie, votre ton, vos attentes de public, et sert tout cela à l'agent de manière structurée.
3. **Le contexte qui provient des utilisateurs.** Les humains apportent un jugement, une conscience culturelle et une direction créative. Aucun système ne peut les remplacer totalement. Mais un système peut rendre la capture et la réutilisation faciles.

Parmi ces trois points, deux sont sous notre contrôle : le système lui-même, et la façon dont nous guidons les utilisateurs pour contribuer du contexte et nous aider à améliorer le système. Nous croyons que maîtriser les deux est ce qui permettra à Glossia de se démarquer dans un espace qui se remplit rapidement de solutions "brancher simplement un LLM". Le système est là où nous devons codifier des décennies de théorie linguistique dans les primitives qui émergent dans le monde agentique. Et l'expérience utilisateur autour de lui est la méthode par laquelle nous assurons que le bon contexte soit réellement capturé, affiné et réinjecté dans la boucle.

Eugène Nida, l'un des fondateurs des études modernes de la traduction, affirmait que la bonne traduction ne concerne pas la correspondance mot à mot. Son concept de [équivalence dynamique](https://en.wikipedia.org/wiki/Dynamic_equivalence) dit que la relation entre le public cible et le message traduit doit être perçue de la même manière que celle entre le public d'origine et la source. C'est une idée magnifique, mais elle exige une compréhension contextuelle profonde : qui lit, quel cadre culturel ils apportent, quel ton visait l'original. Ce sont précisément les éléments qui doivent vivre quelque part où un modèle peut les y accéder.

## Ce que nous devons capturer, et comment

L'une des premières choses que nous explorons est quelles informations doivent être capturées, et comment les structurer afin que les agents puissent les utiliser réellement. Plus nous y avons réfléchi, plus nous avons réalisé que ce n'était pas un fichier de configuration plat ni une page de paramètres. Il devait être un graphe. Plus précisément, un **[graphe acyclique orienté](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Pourquoi un DAG ? Parce que **le contexte n'est pas plat**Votre voix de marque influence votre terminologie. Votre terminologie façonne la façon dont vous rédigez des fonctionnalités spécifiques. Les attentes de votre audience déterminent le niveau de formalité, ce qui à son tour affecte le choix des mots. Ces relations ont une direction et une hiérarchie, et elles ne bouclent pas sur elles-mêmes.

Il existe ici de l'art antérieur. Les graphes de connaissance ont été utilisés depuis des années dans les systèmes d'IA pour représenter des relations structurées entre concepts. Plus récemment, [graphes de contexte](https://grokipedia.com/page/context-graph) ont étendu cette idée en ajoutant des couches de contexte dynamique, exactement ce dont les agents ont besoin pour prendre des décisions éclairées. Et dans le monde multi-agent, [les DAG sont devenus un modèle fondamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) pour modéliser les dépendances de tâches et le flux d'informations.

Mais voici la partie qui me passionne : **chaque nœud de ce graphe doit être versionné**. Quand vous modifiez votre voix de marque, vous ne devriez pas perdre l'accès à la version précédente. Lors de la mise à jour d'une entrée terminologique, le système doit savoir quels contenus ont été produits sous l'ancienne définition et quels éléments pourraient devoir être réexaminés. C'est cela qui nous permet d'optimiser le flux de travail agentique pour qu'il ne déclenche que pour les éléments réellement impactés par un changement, plutôt que de tout re-traiter.

## Bidirectionnel par conception

Nous pensons que la relation entre les nœuds de contexte et le contenu doit être directionnelle et fonctionner dans les deux sens.

D'un côté : vous devez savoir comment le contenu est connecté au contexte. Quand un élément de contexte change (disons que votre ton de marque devient plus décontracté), quels articles de blog, descriptions de produits ou articles d'aide ont été rédigés sous la version précédente ? Ce sont ceux qui doivent être révisés ou retraduits. C'est la **direction directe, du contexte vers le contenu**.

De l'autre côté : lorsqu'un traducteur examine une partie du contenu et se demande pourquoi un choix particulier a été fait, il doit pouvoir remonter à celui qui a guidé la décision. Quelle définition de voix était active ? Quelle règle de terminologie s'appliquait ? Ceci **la traçabilité inverse** est ce qui permet aux humains de comprendre ce que les agents ont fait et d'itérer dessus avec confiance.

NASA appelle cela [la traçabilité bidirectionnelle](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacité de suivre une association entre des entités dans les deux sens. Il s'agit d'un principe de l'ingénierie des systèmes, et il s'avère qu'il est exactement ce dont vous avez besoin lorsque vous tentez de créer une boucle de rétroaction entre le contexte linguistique et le contenu généré.

Cette qualité bidirectionnelle est ce qui rend **l'affinement progressif** possible. Un linguiste peut examiner un contenu, voir le contexte qui l'a façonné, décider que la définition de la voix nécessite un ajustement, et créer cet ajustement. Le système sait ensuite exactement quels autres contenus sont affectés par ce changement. C'est une boucle serrée, et c'est profondément humain.

## Au-delà d'un seul dépôt

Il y a une autre dimension à ce graphe que je trouve particulièrement intéressante. **Cela ne peut pas vivre dans un seul dépôt.** Le graphe de contexte doit être partageable entre les projets, et potentiellement entre les organisations.

Rendez-vous un instant compte : une entreprise a une voix de marque. Cette voix s'applique à tous les produits, tous les sites web, tous les articles d'aide. Elle ne vit pas dans un seul dépôt. C'est une préoccupation transversale. Vous pouvez définir votre voix de base au niveau organisationnel, puis appliquer des surcharges au niveau projet pour un produit ou une audience spécifique. Il s'agit **l'héritage de portée**, le même schéma que nous utilisons habituellement en programmation, mais appliqué au contexte linguistique.

Et ce contexte doit être versionné de manière appropriée. Vous ne pouvez pas simplement modifier la définition de la voix et effacer la version précédente. Il y a beaucoup à apprendre de la façon dont [Git gère la gestion des versions](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) via le stockage adressable par contenu et les DAGs. Le modèle de Git de commits, de branches et de diffs est fondamentalement axé sur le suivi de l'évolution des éléments dans le temps tout en préservant l'accès à chaque état antérieur. C'est exactement ce dont nous avons besoin pour le contexte linguistique.

En fait, nous pensons qu'un changement de ton devrait se faire via quelque chose que nous appelons une *demande de changement de ton*. Tout comme une pull request crée un espace pour discuter des modifications de code, une demande de changement de ton offre un espace pour discuter des modifications linguistiques. Pourquoi passons-nous à un ton plus conversationnel ? Quel impact cela aura-t-il ? Quels contenus seront concernés ? Ce sont des conversations à avoir avant que le changement ne se propage.

## Là où les humains deviennent plus créatifs, pas moins pertinents

C'est ici que les choses deviennent vraiment intéressantes. Au lieu d'éliminer les humains, ce qui est le récit que beaucoup de gens promeuvent quand ils parlent de l'IA, ce système **donne aux humains un rôle plus créatif**.

Imaginez une équipe de linguistes et de stratèges du contenu ayant une réunion où ils discutent d'idées sur la direction linguistique de la marque. Ils pourraient explorer des concepts, débattre des changements de ton, faire référence à un contexte culturel auquel aucun modèle n'a accès. Et puis, plutôt que de mettre à jour manuellement des centaines de fichiers, ils capturent leurs décisions comme des ajustements au graphe de contexte. Le système s'occupe de la propagation.

Ou poussez cela encore plus loin : imaginez des sessions avec agents où un traducteur collabore avec un assistant IA pour explorer des idées linguistiques. \\"Et si nous rendions les messages d'erreur plus empathiques ?\\" L'agent simule l'impact, montre comment le contexte actuel évoluerait, anticipe à quoi pourrait ressembler le contenu mis à jour. Le traducteur affine, ajuste, et une fois satisfait, soumet une demande de modification de contexte. Ne serait-ce pas formidable ?

**Il ne s'agit pas de remplacer le traducteur.** Il s'agit de leur donner de meilleurs outils pour faire ce qu'ils font déjà si bien : prendre des décisions nuancées et culturellement informées sur la langue. Le système gère les aspects mécaniques (propagation, analyse d'impact, cohérence) tandis que les humains se concentrent sur les aspects créatifs (voix, ton, résonance culturelle).

Je reviens sans cesse à ce que Nida visait avec l'équivalence dynamique. L'objectif n'est pas la précision linguistique au sens mécanique. Il s'agit de créer la même relation ressentie entre le lecteur et le contenu, quelle que soit la langue. Cela nécessite du goût, du jugement et une conscience culturelle. Des qualités que les humains maîtrisent remarquablement bien, alors que les modèles ont encore du mal avec elles. La mission du système est de s'assurer que ces intuitions humaines soient capturées, structurées et réutilisables.

## La suite

Dans un prochain article, nous approfondirons l'aspect technique et parlerons du rôle que les bacs à sable joueront pour rendre possibles des expériences encore inédites dans ce domaine, et des raisons pour lesquelles nous investissons massivement dans les API. Il y a toute une dimension autour de l'environnement de préproduction, de la prévisualisation et du test des changements linguistiques avant leur mise en ligne que nous avons hâte d'explorer.

Si tout cela résonne en vous, que vous soyez un traducteur frustré par l'outillage actuel, un développeur ayant eu du mal avec les flux de travail de localisation, ou simplement quelqu'un qui réfléchit profondément à l'intersection de la langue et de la technologie, nous serions ravis d'entendre de vous.