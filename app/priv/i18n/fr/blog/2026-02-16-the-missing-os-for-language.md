%{
  title: "Le système d'exploitation qui manquait à la langue",
  summary: "Le logiciel dispose de frameworks, de systèmes de conception et de Git. La langue, elle, n'a... rien. Nous pensons qu'il est temps de créer le système d'exploitation où les linguistes prennent les rênes et où les organisations accordent enfin au contenu le même soin qu'au code.",
  date: ~D[2026-02-16],
  slug: "2026-02-16-the-missing-os-for-language",
  author: "pedro"
}
---
Pensez aux progrès accomplis par les logiciels pour fournir aux équipes des outils communs leur permettant de travailler de manière cohérente. Les [frameworks](https://en.wikipedia.org/wiki/Software_framework) permettent aux développeurs d’exprimer la logique selon des schémas prévisibles. Les [systèmes de conception](https://en.wikipedia.org/wiki/Design_system) permettent aux designers et aux ingénieurs de partager un langage visuel commun sur chaque écran et chaque interface. [Git](https://en.wikipedia.org/wiki/Git) nous a fourni une base pour la collaboration, le versionnage et la revue, que [GitHub](https://github.com) et [GitLab](https://gitlab.com) ont transformée en un outil utilisé chaque jour par des millions de personnes.

> [!NOTE]
> Si vous n’êtes pas développeur : [Git](https://en.wikipedia.org/wiki/Git) est un système de [gestion de versions](https://en.wikipedia.org/wiki/Version_control), un outil qui suit chaque modification apportée à un ensemble de fichiers afin que les équipes puissent collaborer sans écraser le travail des autres. Imaginez une fonctionnalité de « suivi des modifications » dans un logiciel de traitement de texte, mais appliquée à des projets entiers. [GitHub](https://github.com) et [GitLab](https://gitlab.com) sont des plateformes fondées sur Git qui permettent de proposer facilement des modifications, de revoir le travail des autres et de discuter des améliorations avant de les accepter.

Pensez maintenant à la langue. Aux mots que votre produit adresse réellement aux utilisateurs. Au ton de vos messages d’erreur. À la manière dont vos textes marketing s’expriment en japonais par rapport à l’allemand. À la terminologie employée par votre équipe d’assistance par rapport à celle de l’interface utilisateur de votre produit.

Il n’existe aucun système commun pour tout cela. Aucun framework. Aucun système de conception. Aucun Git. Rien.

## Nous n’avons jamais construit l’infrastructure

Ce n’est pas que les théories n’existent pas. La linguistique est un domaine riche. Le concept d’[équivalence dynamique](https://en.wikipedia.org/wiki/Dynamic_equivalence) d’[Eugene Nida](https://en.wikipedia.org/wiki/Eugene_Nida) nous a appris qu’une bonne traduction ne consiste pas à remplacer des mots, mais à recréer la même relation ressentie entre le lecteur et le message. L’analyse du discours, la pragmatique et la sociolinguistique : toutes ces disciplines étudient depuis des décennies le fonctionnement de la langue en contexte. Les fondements intellectuels existent.

Mais personne n’a construit de système autour de ces fondements.

Lorsque l’internet est apparu, les entreprises de localisation ont déplacé leurs applications de bureau propriétaires vers le navigateur. Le modèle sous-jacent est resté le même : [mémoires de traduction](https://en.wikipedia.org/wiki/Translation_memory), [correspondance approximative](https://en.wikipedia.org/wiki/Fuzzy_matching_(computer-assisted_translation)), tarification au mot. Elles ont continué à construire sur les mêmes fondations et, lorsque la traduction automatique s’est améliorée, elles l’y ont greffée. Aucune remise en question, aucune réinvention. Simplement le même flux de travail, reposant sur un moteur plus rapide.

Puis les intermédiaires sont arrivés.

Entre vous, la personne ou l’entreprise qui possède du contenu, et le linguiste, la personne qui comprend réellement la langue, tout un secteur d’intermédiaires a émergé. Plateformes d’intégration. Systèmes de gestion de traduction. Agences de traduction. Niveaux d’assurance qualité. Tableaux de bord de gestion de projet. Chacun ajoute de la complexité et prélève sa part. La personne qui apporte le plus de valeur, le linguiste qui contribue par sa connaissance culturelle, sa précision terminologique et son discernement créatif, se retrouve tout au bout de la chaîne et perçoit la rémunération la plus faible.

Des [rapports du secteur](https://traductoresnativos.com/en/translation-agencies-2025-summary-2026/) montrent que les tarifs de post-édition de contenus produits par l’intelligence artificielle peuvent tomber à 50-70 % de tarifs au mot déjà modestes, tandis que les agences exigent en plus des remises de 30-40 %. La chaîne d’approvisionnement exerce la pression la plus forte sur les personnes dont elle dépend le plus.

## Un signe qu’il manque quelque chose

Voici un signe que les outils actuels ne suffisent pas : les entreprises créent un poste appelé ["Language Manager"](https://slator.com/10-language-jobs-big-tech-is-hiring-for-right-now/). Ces personnes se consacrent entièrement à la gestion de la terminologie, à la supervision des flux de traduction, à l'application cohérente de la terminologie et à la coordination entre les linguistes, les équipes produit et les services marketing.

L'existence même de ce poste est révélatrice. Elle signifie que les organisations ont besoin d'une cohérence linguistique sur l'ensemble de leurs supports et que leurs outils ne la garantissent pas. Elles recrutent donc une personne pour assurer la liaison.

Ces personnes se retrouvent alors face à un dilemme inconfortable. D'un côté, elles peuvent demander des ressources d'ingénierie pour créer un système interne, mais cela exige un investissement considérable dans un domaine qui ne constitue pas le cœur de métier de leur employeur. De l'autre, elles peuvent rechercher un outil externe, mais personne n'a véritablement conçu de solution complète pour répondre à ce besoin. Les solutions existantes sont des composants plus restreints et déconnectés qu'elles doivent orchestrer et relier elles-mêmes. Aucune de ces options n'est satisfaisante.

C'est précisément cette lacune qu'un système doit combler. Non pas en remplaçant le Language Manager, mais en lui fournissant, ainsi qu'à chaque linguiste avec qui il travaille, un véritable système d'exploitation pour accomplir son travail.

## Ce que nous construisons avec Glossia

Selon nous, la réponse ressemble moins à un outil de traduction qu'à ce que GitHub a créé pour le code.

GitHub a pris Git, un système de suivi des modifications apportées aux fichiers, et l'a transformé en une plateforme collaborative où les développeurs examinent mutuellement leur travail, discutent des modifications et les améliorent ensemble. Avant GitHub, contribuer à des projets logiciels impliquait d'envoyer des fichiers par e-mail dans les deux sens. Après GitHub, toute personne disposant d'un compte pouvait participer.

Nous voulons faire de même pour la langue.

Glossia est le système d'exploitation dans lequel les organisations consignent leurs préférences linguistiques, leur voix, leur terminologie, leur ton et les attentes de leur public. Les linguistes y occupent une place centrale dans l'amélioration continue de ces préférences. Pas au bout d'une chaîne. Pas derrière trois niveaux d'intermédiaires. Au centre.

Nous avons abordé ce sujet dans notre article sur [le graphe de contexte](https://glossia.ai/blog/2026-02-15-context-graph) : nous construisons une cartographie structurée de connaissances interconnectées qui consigne au fil du temps tout ce qu'une organisation sait de son langage. Définitions de voix, entrées de terminologie, profils de public, règles de formalité. Chaque élément est versionné, ce qui permet de voir ce qui a changé et à quel moment, et relié à tout ce qui lui est associé. Lorsqu'un élément change, le système sait exactement quels contenus sont concernés et lesquels doivent être réexaminés.

Il s'agit de votre compte sur Glossia et des nombreux projets auxquels vous pouvez contribuer. Un linguiste peut travailler pour plusieurs organisations, apporter son expertise dans différents contextes et observer comment l'incidence de ses décisions se propage dans le système. À l'image d'un développeur qui contribue à plusieurs projets sur GitHub, un linguiste sur Glossia peut façonner la manière dont des dizaines de produits s'expriment.

## L'intelligence artificielle comme amplificateur, et non comme substitut

Le discours dominant sur l'intelligence artificielle et la langue porte sur le remplacement. Plus rapide, moins cher, avec moins d'humains. Nous pensons que cette vision est profondément erronée et, franchement, qu'elle méprise l'étendue de l'expertise apportée par les linguistes.

Notre approche est différente. L'intelligence artificielle est un outil qui fonctionne au sein d'un système façonné par les contributions linguistiques. Elle ne remplace pas le linguiste. Elle amplifie ce que les linguistes rendent possible.

Lorsqu'un linguiste affine une définition de voix dans Glossia, cette amélioration est appliquée à chaque contenu traité par le système. Lorsqu'un terminologue met à jour une entrée de terminologie, cette modification est prise en compte dès qu'un agent génère ou transforme à nouveau du contenu pour cette organisation. La décision humaine est ainsi répercutée sur des centaines ou des milliers de résultats. Ce potentiel de démultiplication n'avait jamais été accessible auparavant.

La traduction est le cas d’usage le plus évident, et c’est par là que nous avons commencé. Mais ce n’est pas le seul. Dès lors qu’une organisation a constitué un graphe contextuel riche, alimenté par la mémoire linguistique que son équipe de linguistes a développée au fil des mois et des années, les possibilités se multiplient :

- Une équipe marketing peut connecter ses outils de rédaction à ce système d’exploitation via le [MCP](https://modelcontextprotocol.io/) (Model Context Protocol, un standard qui permet aux outils d’intelligence artificielle de communiquer avec des systèmes externes) et veiller à ce que chaque campagne respecte la terminologie et la voix de l’entreprise.
- Une équipe produit peut vérifier que les textes de son interface utilisateur correspondent au ton défini pour son public.
- Une équipe d’assistance peut générer des réponses qui reflètent la marque, plutôt que celles d’un agent conversationnel générique.

Les connaissances linguistiques deviennent une ressource partagée, comparable à un système de conception, mais appliqué au langage.

## Les linguistes méritent de meilleurs outils

Si vous êtes linguiste ou traducteur et que vous lisez ceci, sachez que ce projet existe grâce à vous, et non malgré vous.

Depuis des années, le secteur de la localisation vous éloigne toujours davantage des personnes et des organisations que vous accompagnez. Il a banalisé votre travail, comprimé vos tarifs et relégué votre expertise au second plan dans une chaîne optimisée pour le débit.

Nous pensons que les linguistes doivent participer pleinement à la manière dont les organisations communiquent. Vous maîtrisez le registre, la pragmatique, le contexte culturel et les nuances subtiles entre ce qu’une phrase dit et ce qu’elle signifie. Aucun modèle ne peut remplacer cela. Mais un système peut permettre à vos analyses d’avoir une portée plus large, de perdurer et d’influencer bien davantage qu’une seule traduction ne pourrait jamais le faire.

Nous concevons Glossia afin que votre expertise devienne le socle sur lequel repose tout le reste. Pas une étape au bout d’une chaîne. Le socle.

## La suite

Nous n’en sommes encore qu’au début. Nous avons commencé par l’[agent CLI](https://glossia.ai/docs) (un outil en ligne de commande, avec lequel vous interagissez en saisissant des commandes dans un terminal plutôt qu’en cliquant sur des boutons dans une interface visuelle), car c’est là que se trouvent les problèmes d’infrastructure les plus complexes : lire les fichiers sources, générer les résultats, les valider avec vos propres outils et boucler le cycle de retour d’information. Mais comme nous l’avons expliqué dans notre [premier article](https://glossia.ai/blog/2026-02-03-why-glossia), le terminal est la première interface, pas la seule.

Nous concevons des expériences permettant aux linguistes de consulter simultanément le contenu et son contexte, d’affiner les définitions de la voix lors de sessions collaboratives et de suivre en temps réel la propagation de leurs décisions dans le système. Nous souhaitons que la contribution d’une expertise linguistique soit aussi naturelle et valorisante que la contribution de code sur GitHub.

Si cette vision vous parle, que vous soyez linguiste et vous sentiez marginalisé par les outils que l’on vous demande d’utiliser, responsable de la localisation à la recherche du système dont vous auriez aimé disposer, ou simplement convaincu que notre manière de nous exprimer compte autant que notre manière de concevoir, nous serions ravis d’échanger avec vous. Rejoignez notre [Discord](https://discord.gg/7FRHkwvs) ou suivez le [blog](https://glossia.ai/blog). La conversation ne fait que commencer.