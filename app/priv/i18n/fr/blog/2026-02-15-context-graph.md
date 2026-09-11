%{
  title:
    "Le graphe de contexte : codification de décennies de théorie linguistique pour l'ère des agents",
  summary:
    "Les modèles linguistiques sont puissants, mais ils ont besoin du bon contexte pour produire un excellent contenu. Nous concevons un graphe orienté et versionné pour capturer la connaissance linguistique et la partager avec les agents ; nous pensons que c'est ce qui permettra à Glossia de se démarquer.",
  date: ~D[2026-02-15],
  slug: "2026-02-15-context-graph",
  author: "pedro"
}
---
Je réfléchis beaucoup à ce qui fait la différence entre un contenu qui semble généré par une machine et un contenu qui donne l'impression d'avoir été écrit par quelqu'un qui comprend le public, la marque et les nuances culturelles derrière chaque mot. La réponse revient sans cesse à la même chose : **contexte**.

Les modèles de langage progressent dans leur maîtrise des langues, et nous parions sur cette trajectoire. Ils n'y sont pas encore totalement là, mais le rythme d'amélioration est difficile à ignorer. Toutefois, ce qui manque, c'est le système qui se trouve entre le modèle et le contenu. La chose qui dit au modèle *qui* vous êtes, *comment* vous parlez, *ce qui* importe dans cette phrase en particulier, et *pourquoi* cette phrase existe en premier lieu. C'est le problème sur lequel nous travaillons à Glossia, et je pense que c'est le plus intéressant de l'espace actuellement.

## Trois éléments, deux que nous contrôlons

Quand je regarde ce qu'il faut pour permettre une approche véritablement nouvelle aux contenus monolingues et multilingues, je vois trois éléments :

1. **Modèles performants pour les langues.** Ils ne sont pas encore tout à fait là, mais ils s'améliorent rapidement et nous parions sur cette tendance. Nous n'avons pas besoin de construire un modèle de fondation. Nous devons être prêts à les bien utiliser quand ils seront là.
2. **Un système pour modéliser et partager le contexte dont les agents ont besoin.** C'est le maillon qui se situe entre le modèle et le contenu. La couche qui capture votre voix, votre terminologie, votre ton, les attentes de votre public, et transmet tout cela à l'agent d'une manière structurée.
3. **Le contexte provenant des utilisateurs.** Les humains apportent du jugement, une conscience culturelle et une direction créative. Aucun système ne peut pleinement remplacer cela. Mais un système peut le rendre facile à capturer et à réutiliser.

Parmi ces trois éléments, nous en contrôlons deux : le système lui-même, et la manière dont nous guidons les utilisateurs pour contribuer au contexte et nous aider à améliorer le système. Nous croyons que maîtriser les deux est ce qui permettra à Glossia de se démarquer dans un espace qui se remplit rapidement de solutions de type « juste brancher un LLM ». Le système est l'endroit où nous devons codifier des décennies de théorie linguistique dans les primitives qui émergent dans le monde agentique. Et l'expérience utilisateur qui l'entoure est la manière dont nous nous assurons que le bon contexte est effectivement capturé, affiné et réinjecté dans la boucle.

Eugène Nida, l'un des fondateurs des études de traduction modernes, a soutenu que la bonne traduction ne repose pas sur une correspondance mot à mot. Son concept de [équivalence dynamique](https://en.wikipedia.org/wiki/Dynamic_equivalence) il stipule que la relation entre le public cible et le message traduit doit se ressentir de la même manière que celle entre le public original et la source. C'est une idée magnifique, mais elle exige une compréhension contextuelle approfondie : qui lit, quel cadre culturel ils apportent, quel ton visait l'original. Ce sont précisément les types de choses qui doivent résider quelque part où un modèle puisse y accéder.

## Ce que nous devons capturer, et comment

L'une des premières choses que nous explorons est quelles informations doivent être capturées, et comment les structurer afin que les agents puissent concrètement les utiliser. Plus nous y avons réfléchi, plus nous avons réalisé que ce n'était pas un fichier de configuration plat ni une page de paramètres. Il fallait qu'il s'agisse d'un graphe. Plus précisément, un **[graphe acyclique orienté](https://en.wikipedia.org/wiki/Directed_acyclic_graph)**.

Pourquoi un DAG ? Parce que **le contexte n'est pas plat**. Votre voix de marque influence votre terminologie. Votre terminologie façonne la manière dont vous écrivez sur des fonctionnalités spécifiques. Les attentes de votre public déterminent le niveau de formalité, ce qui à son tour affecte le choix des mots. Ces relations ont une direction et une hiérarchie, et elles ne font pas de boucle sur elles-mêmes.

Il existe des travaux antérieurs ici. Les graphes de connaissances ont été utilisés depuis des années dans les systèmes d'IA pour représenter des relations structurées entre des concepts. Plus récemment, [graphes de contexte](https://grokipedia.com/page/context-graph) ont étendu cette idée en ajoutant des couches de contexte dynamiques, exactement ce dont les agents ont besoin pour prendre des décisions éclairées. Et dans le monde multi-agent, [les DAGs sont devenus un modèle fondamental](https://santanub.medium.com/directed-acyclic-graphs-the-backbone-of-modern-multi-agent-ai-d9a0fe842780) pour modéliser les dépendances de tâches et les flux d'informations.

Mais voici la partie qui m'enthousiasme : **chaque nœud de ce graphe doit être versionné**. Lorsque vous changez votre ton de marque, vous ne devez pas perdre accès à la version précédente. Lorsque vous mettez à jour une entrée terminologique, le système doit savoir quel contenu a été produit sous l'ancienne définition et quelles pièces pourraient avoir besoin d'être réexaminées. C'est ce qui nous permet d'optimiser le flux de travail des agents de telle sorte qu'il ne soit déclenché que pour les pièces réellement impactées par un changement, plutôt que de tout rétraiter.

## Bidirectionnel par conception

Nous pensons que la relation entre les nœuds de contexte et le contenu doit être directionnelle et qu'elle doit fonctionner dans les deux sens.

En examinant cela d'un côté, vous devez savoir comment le contenu est connecté au contexte. Lorsqu'un élément de contexte change (par exemple, votre voix de marque devient plus décontractée), quels articles de blog, quelles descriptions de produits ou quels articles d'aide ont été rédigés sous la précédente version ? Ce sont ceux qui doivent être réexaminés ou retraduits. Ceci est la **direction avant, du contexte au contenu**.

De l'autre côté : lorsqu'un linguiste examine un élément de contenu et se demande pourquoi un choix particulier a été fait, il doit pouvoir remonter au contexte qui a guidé la décision. Quelle définition de voix était active ? Quelle règle de terminologie s'appliquait ? Cette **traçabilité inverse** est ce qui permet aux humains de comprendre ce que les agents ont fait et d'y itérer avec confiance.

La NASA appelle cela [traçabilité bidirectionnelle](https://swehb.nasa.gov/display/SWEHBVB/SWE-059+-+Bidirectional+Traceability+Between+Software+Requirements+and+Software+Design): la capacité de suivre une association entre des entités dans les deux directions. C'est un principe de l'ingénierie des systèmes, et cela s'avère être exactement ce dont vous avez besoin lorsque vous essayez de créer une boucle de rétroaction entre le contexte linguistique et le contenu généré.

Cette qualité bidirectionnelle est ce qui rend **l'affinement progressif** possible. Un linguiste peut examiner un contenu, voir le contexte qui l'a façonné, décider que la définition de la voix nécessite un ajustement, et créer cet ajustement. Le système sait alors exactement quel autre contenu est affecté par ce changement. C'est une boucle serrée, et c'est profondément humain.

## Au-delà d'un seul référentiel

Il existe une autre dimension à ce graphe que je trouve particulièrement intéressante. **Il ne peut pas vivre dans un seul dépôt.** Le graphe de contexte doit être partageable entre les projets, et potentiellement entre les organisations.

Réfléchissez-y : une entreprise a une voix de marque. Cette voix s'applique à tous les produits, tous les sites web, tous les articles d'aide. Elle ne réside pas dans un seul dépôt. C'est une préoccupation transversale. Vous pouvez définir votre voix centrale au niveau de l'organisation, puis appliquer des modifications au niveau du projet pour un produit ou un public spécifique. C'est **l'héritage de portée**, le même schéma auquel nous sommes habitués en programmation, mais appliqué au contexte linguistique.

Et ce contexte doit être versionné correctement. Vous ne pouvez pas simplement modifier la définition de la voix et supprimer la version précédente. Il y a beaucoup à apprendre de la façon dont [Git gère les versions](https://www.ephraimsiegfried.ch/posts/git-as-a-fancy-dag) , à travers le stockage adressable par le contenu et les DAGs. Le modèle de Git de commits, branches et diffs est fondamentalement axé sur le suivi de l'évolution des choses au fil du temps tout en préservant l'accès à tous les états précédents. Cela correspond exactement à ce dont nous avons besoin pour le contexte linguistique.

En fait, nous pensons qu'un changement de voix devrait se produire via quelque chose que nous appelons une *demande de changement de voix*. Tout comme un pull request offre un espace de discussion sur les modifications de code, une demande de changement de voix prône une discussion autour des modifications linguistiques. Pourquoi passons-nous à un ton plus conversationnel ? Quel impact aura-t-il ? Quel contenu sera concerné ? Ce sont des conversations à tenir avant la propagation du changement.

## Là où les humains deviennent plus créatifs, et non moins pertinents

Et c'est là que les choses commencent à vraiment devenir intéressantes. Au lieu d'éliminer les humains, ce qui est le récit que beaucoup prônent lorsqu'ils parlent d'IA, ce système **offre aux humains un rôle plus créatif**.

Imaginez une équipe de linguistes et de stratèges de contenu tenant une session où ils discutent des idées sur la direction linguistique de la marque. Ils pourraient explorer des concepts, débattre des changements de ton, faire référence à un contexte culturel inaccessible aux modèles. Puis, plutôt que de mettre à jour manuellement des centaines de fichiers, ils capturent leurs décisions comme ajustements du graphe de contexte. Le système gère la propagation.

Ou allez-y plus loin : imaginez des sessions agentic où un linguiste travaille avec un assistant IA pour explorer des idées linguistiques. « Que diriez-vous de rendre les messages d'erreur plus empathétiques ? » L'agent simule l'impact, montre comment le contexte actuel évoluerait, prévisualise à quoi pourrait ressembler le contenu mis à jour. Le linguiste affine, ajuste, et une fois satisfait, soumet une demande de modification de contexte. Ce ne serait pas quelque chose ?

**Il ne s'agit pas de remplacer le linguiste.** Il s'agit de leur donner de meilleurs outils pour ce qu'ils maîtrisent déjà : prendre des décisions nuancées et culturellement informées sur la langue. Le système gère les parties mécaniques (propagation, analyse d'impact, cohérence) tandis que les humains se concentrent sur les parties créatives (la voix, le ton, la résonance culturelle).

Je reviens sans cesse à l'idée de Nida concernant l'équivalence dynamique. L'objectif n'est pas l'exactitude linguistique au sens mécanique. Il s'agit de créer la même relation ressentie entre le lecteur et le contenu, quelle que soit la langue. Cela nécessite du goût, du jugement et une sensibilité culturelle. Des qualités aux quels les humains sont remarquablement performants, et que les modèles peinent encore à maîtriser. La mission du système est de s'assurer que ces intuitions humaines soient capturées, structurées et réutilisables.

## Que vient ensuite

Dans un prochain billet, nous allons être plus techniques et parlerons du rôle que les boîtes à sable joueront pour permettre des expériences jusqu'ici inédites dans ce secteur, et de la raison pour laquelle nous investissons massivement dans les API. Il y a tout un volet autour de la mise en production, de la prévisualisation et du test des modifications linguistiques avant leur déploiement que nous sommes impatients d'explorer.

Si tout cela résonne avec vous, que vous soyez un linguiste frustré par l'outillage actuel, un développeur qui a eu du mal avec les flux de travail de localisation, ou simplement quelqu'un qui réfléchit profondément à l'intersection entre la langue et la technologie, nous serions ravis d'en entendre.