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
J'ai beaucoup réfléchi à ce qui fait la différence entre un contenu qui sonne généré par la machine et un contenu qui semble écrit par quelqu'un qui comprend le public, la marque et les nuances culturelles derrière chaque mot. La réponse revient toujours à la même chose : **contexte**.

Les modèles de langage s'améliorent sur les langues, et nous parions sur le fait que cette trajectoire se prolongera. Ils ne sont pas encore tout à fait là, mais le rythme d'amélioration est difficile à ignorer. Ce qui manque pourtant, c'est le système qui se trouve entre le modèle et le contenu. L'élément qui guide le modèle *qui* vous êtes, *comment* vous parlez, *Ce qui* importe dans cette phrase précise, et *Pourquoi* cette phrase existe en premier lieu. C'est le problème sur lequel nous travaillons à Glossia, et je pense qu'il s'agit du plus intéressant du domaine pour l'instant.

## Trois éléments, deux que nous contrôlons

Lorsque je regarde ce qui est nécessaire pour permettre une approche véritablement nouvelle aux contenus monolingues et multilingues, je vois trois éléments :

1. **Des modèles performants pour les langues.** Ils ne sont pas tout à fait là encore, mais ils s'améliorent rapidement et nous parions sur cette tendance. Nous n'avons pas besoin de créer un modèle de fondation. Nous devons être prêts à les utiliser efficacement lorsqu'ils seront là.
2. **Un système pour modéliser et partager le contexte dont les agents ont besoin.** C'est le composant intermédiaire entre le modèle et le contenu. La couche qui capture votre voix, votre terminologie, votre ton, vos attentes en matière d'audience et livre tout cela à l'agent de manière structurée.
3. **Le contexte qui provient des utilisateurs.** Les humains apportent du jugement, une conscience culturelle et une direction créative. Aucun système ne peut pleinement le remplacer. Cependant, un système peut faciliter sa capture et sa réutilisation.

Parmi ces trois éléments, il y en a deux que nous maîtrisons : le système lui-même, et la manière dont nous guidons les utilisateurs pour contribuer du contexte et nous aider à améliorer le système. Nous croyons que maîtriser les deux permettra à Glossia de se démarquer dans un domaine qui se remplit rapidement de solutions « brancher simplement une LLM ». Le système est l'endroit où nous devons codifier des décennies de théorie linguistique dans les primitives émergentes dans le monde agentique. Et l'expérience utilisateur associée est la façon dont nous nous assurons que le contexte approprié soit réellement capturé, affiné et réinjecté dans la boucle.

Eugène Nida, l'un des fondateurs des études modernes de traduction, a soutenu que la bonne traduction ne se limite pas à la correspondance mot-à-mot. Son concept de [« équivalence dynamique »](https://en.wikipedia.org/wiki/Dynamic_equivalence) dit que la relation entre le public cible et le message traduit doit sembler identique à celle entre le public original et la source. C'est une belle idée, mais elle exige une compréhension contextuelle approfondie : qui lit, quel cadre culturel ils apportent, quel ton visait l'original. Ce sont précisément le genre de choses qui doivent résider quelque part accessible à un modèle.

## Ce qu'il faut capturer, et comment

L'une des premières choses que nous explorons est quelles informations doivent être capturées et comment les structurer de manière à ce que les agents puissent les utiliser effectivement. Plus nous y avons réfléchi, plus nous avons réalisé qu'il ne s'agissait pas d'un fichier de configuration plat ou d'une page de paramètres. Il fallait un graphe. Plus précisément, un **[graphe orienté acyclique](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Pourquoi un DAG ? Parce que **le contexte n'est pas plat**. La voix de votre marque influence votre terminologie. Votre terminologie façonne la manière dont vous écrivez sur des fonctionnalités spécifiques. Les attentes de votre public influencent le niveau de formalité, ce qui affecte à son tour le choix des mots. Ces relations ont une direction et une hiérarchie, et elles ne forment pas de boucle sur elles-mêmes.

Des antécédents existent ici. Les graphes de connaissances ont été utilisés pendant des années dans les systèmes d'IA pour représenter les relations structurées entre les concepts. Plus récemment, [Les graphes de contexte](https://grokipedia.com/page/context-graph) ont étendu cette idée en ajoutant des couches de contexte dynamiques, exactement ce dont les agents ont besoin pour prendre des décisions éclairées. Et dans le monde multi-agent, [Les DAGs sont devenus un motif fondamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) pour la modélisation des dépendances de tâches et du flux d'information.

Mais voici la partie qui m'enthousiasme : **chaque nœud de ce graphe doit être versionné**. Lorsque vous changez votre voix de marque, vous ne devez pas perdre l'accès à la version précédente. Lorsque vous mettez à jour une entrée de terminologie, le système doit savoir quel contenu a été produit sous l'ancienne définition et quels éléments pourraient devoir être revus. C'est ce qui nous permet d'optimiser le flux de travail agentique de sorte qu'il ne déclenche que pour les éléments réellement impactés par un changement, au lieu de tout retraiter.

## Bidirectionnel par conception

Nous pensons que la relation entre les nœuds de contexte et le contenu doit être directionnelle, et qu'elle doit fonctionner dans les deux sens.

En considérant cela d'un seul côté : il vous faut savoir comment le contenu est connecté au contexte. Lorsqu'un élément de contexte change (disons, votre voix de marque devient plus décontractée), quels articles de blog, quelles descriptions de produits ou articles d'aide ont été rédigés avec la version précédente ? Ce sont ceux qui doivent être révisés ou retraduits. C'est la **direction en avant, du contexte vers le contenu**.

De l'autre côté : lorsqu'un linguiste examine un élément de contenu et se demande pourquoi un choix particulier a été fait, il doit pouvoir remonter au contexte qui a guidé la décision. Quelle définition de voix était active ? Quelle règle de terminologie s'appliquait ? Cette **traçabilité inversée** est ce qui permet aux humains de comprendre ce que les agents ont fait et d'y itérer avec confidence.

NASA appelle cela [la traçabilité bidirectionnelle](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacité de suivre une association entre des entités dans les deux sens. C'est un principe de l'ingénierie des systèmes, et il s'avère que c'est exactement ce dont vous avez besoin lorsque vous tentez de créer une boucle de rétroaction entre le contexte linguistique et le contenu généré.

Cette qualité bidirectionnelle est ce qui rend **l'affinement progressif** possible. Un linguiste peut examiner un élément de contenu, voir le contexte qui l'a façonné, décider que la définition de la voix nécessite un ajustement et le réaliser. Le système sait ensuite exactement quels autres contenus sont affectés par le changement. C'est une boucle serrée, et c'est profondément humain.

## Au-delà d'un seul dépôt

Il y a une autre dimension à ce graphe que je trouve particulièrement intéressante. **Il ne peut pas vivre dans un seul dépôt.** Le graphe de contexte doit être partageable entre plusieurs projets, et potentiellement entre plusieurs organisations.

Pensez-y : une entreprise a une voix de marque. Cette voix s'applique à chaque produit, chaque site web, chaque article de support. Elle ne réside pas dans un seul dépôt. C'est une préoccupation transversale. Vous pouvez définir votre voix principale au niveau de l'organisation, puis appliquer des surcharges au niveau du projet pour un produit ou un public spécifique. C'est **héritage de portée**, le même schéma que nous connaissons dans la programmation, mais appliqué au contexte linguistique.

Et ce contexte doit être versionné correctement. Vous ne pouvez pas simplement modifier la définition de la voix et effacer la version précédente. Il y a beaucoup à apprendre de la façon dont [Git gère les versions](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) par stockage basé sur le contenu et les DAGs. Le modèle de Git concernant les commits, les branches et les diffs s'agit fondamentalement de tracer comment les choses changent au fil du temps tout en préservant l'accès à tous les états précédents. C'est exactement ce dont nous avons besoin pour le contexte linguistique.

En fait, nous pensons qu'un changement de ton devrait survenir via ce que nous appelons une *demande de changement de ton*. Tout comme une pull request crée un espace pour discuter des changements de code, une demande de changement de ton crée un espace pour discuter des changements linguistiques. Pourquoi passons-nous à un ton plus conversationnel ? Quel impact cela aura-t-il ? Quel contenu sera concerné ? Ce sont des conversations à avoir avant que le changement ne se propage.

## Là où l'humain devient plus créatif, et non moins pertinent

Et c'est là que les choses commencent vraiment à devenir intéressantes. Au lieu d'éliminer les humains, ce qui est le récit que beaucoup de gens avancent lorsqu'ils parlent d'IA, ce système **donne aux humains un rôle plus créatif**.

Imaginez une équipe de linguistes et de stratèges du contenu ayant une session où ils discutent des idées sur la direction linguistique de la marque. Ils pourraient explorer des concepts, débattre des changements de ton, faire référence à un contexte culturel auquel aucun modèle n'a accès. Et puis, au lieu de mettre à jour manuellement des centaines de fichiers, ils captent leurs décisions comme des ajustements au graphe de contexte. Le système gère la propagation.

Ou prenons le tout une étape plus loin : imaginez des sessions agentiques où un linguiste collabore avec un assistant IA pour explorer des idées linguistiques. « Et si nous rendions les messages d'erreur plus empathétiques ? » L'agent simule l'impact, montre comment le contexte actuel évoluerait, anticipe à quoi ressemblerait le contenu mis à jour. Le linguiste affine, ajuste, et lorsqu'il est satisfait, soumet une demande de changement de contexte. N'y pensez-vous pas ?

**Il ne s'agit pas de remplacer le linguiste.** Il s'agit de leur offrir de meilleurs outils pour accomplir ce en quoi ils excellent déjà : prendre des décisions nuancées et informées culturellement sur la langue. Le système gère les aspects mécaniques (propagation, analyse d'impact, cohérence) tandis que les humains se concentrent sur les aspects créatifs (voix, ton, résonance culturelle).

Je reviens constamment à ce que Nida entendait par l'équivalence dynamique. L'objectif n'est pas la précision linguistique au sens mécanique. Il s'agit de créer la même relation ressentie entre le lecteur et le contenu, quelle que soit la langue. Cela nécessite du goût, du jugement et une conscience culturelle. Des qualités dont les humains sont remarquablement dotés, et que les modèles peinent encore à maîtriser. Le rôle du système est de s'assurer que ces intuitions humaines soient capturées, structurées et réutilisées.

## Ce qui suit

Dans un billet de suivi, nous allons approfondir le côté technique et parler du rôle que les bac à sable joueront pour permettre des expériences inédites dans ce domaine, et expliquer pourquoi nous investissons massivement dans les API. Il y a toute une dimension autour du staging, de la prévisualisation et du test des modifications linguistiques avant leur mise en ligne que nous sommes impatients d'explorer.

Si tout cela résonne avec vous, que vous soyez un linguiste frustré par l'outillage actuel, un développeur qui a rencontré des difficultés dans les flux de localisation, ou simplement quelqu'un qui réfléchit profondément à la manière dont la langue et la technologie s'entremêlent, nous serions ravis de votre retour.