%{
  title: "Mémoire linguistique",
  summary:
    "Une couche de contexte versionnée qui capture la voix, la terminologie et le style de votre organisation. La mémoire linguistique guide chaque flux de travail et s'étend à vos propres outils via l'API et le serveur MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionné et auditable",
      description:
        "Chaque modification de votre voix ou de votre terminologie crée une nouvelle version immuable. Vous pouvez examiner l'historique, comparer les itérations et revenir en arrière si quelque chose dérive.",
      icon: "git-branch"
    },
    %{
      title: "Au-delà de la localisation",
      description:
        "La mémoire linguistique ne sert pas uniquement à la localisation. Utilisez-la pour générer du contenu marketing, rédiger une documentation, examiner des pull requests ou créer des publications sociales, tout cela dans la voix de votre organisation.",
      icon: "megaphone"
    },
    %{
      title: "Ouvert et extensible",
      description:
        "Accédez à la mémoire linguistique via l'API REST ou le serveur MCP. Intégrez-la dans vos propres pipelines CI, outils de contenu ou agents personnalisés pour maintenir la cohérence partout où vous écrivez.",
      icon: "puzzle"
    }
  ]
}
---
## Qu'est-ce que la mémoire linguistique ?

La mémoire linguistique est le contexte accumulé qui indique aux agents de Glossia la manière dont votre organisation communique. Elle est constituée de deux primitives fondamentales que vous créez et affinez au fil du temps :

**Voix** définit comment le contenu doit sonner. Tonalité, formalité, public cible et directives de format libre y résident. Vous pouvez définir une voix de base pour votre compte, puis surclasser des champs spécifiques pour des localisations individuelles, de sorte que votre contenu japonais puisse être plus formel tandis que votre anglais reste conversationnel.

**Terminologie** définit la signification des termes et la manière dont ils doivent être localisés. Chaque entrée comprend une définition et des traductions par localisation. Lorsque l'agent rencontre le terme "workspace" dans votre contenu source, la terminologie lui indique s'il doit localiser, translittérer ou le laisser tel quel, et exactement quel mot utiliser dans chaque langue cible.

Ensemble, la voix et la terminologie constituent une couche de contexte que les agents consultent à chaque exécution. Plus vous investissez dans cette couche, moins votre sortie a besoin de relecture.

## Versionnement immuable

La mémoire linguistique est append-only. Lorsque vous mettez à jour votre voix ou votre terminologie, Glossia crée une nouvelle version plutôt que d'écraser l'ancienne. Chaque version enregistre qui l'a créée, quand, et une note de changement facultative expliquant les évolutions.

Cela signifie que vous avez toujours une traçabilité complète. Vous pouvez comparer la version 3 contre la version 7 pour comprendre comment votre ton a évolué au cours d'un trimestre. Si un changement récent a introduit des incohérences, revenez à une version précédente et continuez.

La versionning rend également la collaboration plus sûre. Plusieurs membres de l'équipe peuvent proposer des modifications de voix sans se soucier des conflits, car chaque changement est un événement discret et traçable.

## Résolution sensible à la localisation

Quand un agent exécute un flux de travail pour une localisation spécifique, Glossia résout la mémoire linguistique pour ce contexte. Il commence avec vos paramètres de voix de base puis applique sur le dessus tous les ajustements spécifiques à la localisation. C'est la même chose pour la terminologie : seules les entrées disposant d'un terme localisé pour la localisation cible sont incluses.

Cette étape de résolution signifie que les agents travaillent toujours avec le contexte le plus pertinent. Vous n'avez pas besoin de maintenir des configurations séparées par langue. Définissez vos paramètres par défaut une fois, remplacez-les là où cela compte, et laissez le système de résolution gérer le reste.

## Utilisez-le partout

La mémoire linguistique a été conçue pour la localisation, mais elle est utile partout où vous produisez du texte. Parce que le contexte est accessible à travers le [REST API](/features/rest-api) , et le [serveur MCP](/features/mcp-server), vous pouvez l'intégrer dans des flux de travail au-delà de la localisation :

**Marketing et contenu social** -- Apportez la voix de votre organisation dans un agent de contenu qui rédige des publications pour les réseaux sociaux, des campagnes d'e-mail ou des textes de pages d'atterrissage. Terminologie maintient la cohérence des termes de marque et les paramètres de voix garantissent que le ton correspond à votre marque.

**Documentation** -- Alimentez la mémoire linguistique dans un pipeline de documentation afin que la rédaction technique suive les mêmes règles de style que le reste de votre contenu. Les entrées Terminologie évitent la dérive entre la documentation, les articles d'aide et les textes intégrés au produit.

**Revue de code** -- Créez un agent qui examine le contenu des pull requests (messages d'erreur, étiquettes d'interface, textes d'intégration) par rapport à votre voix et à votre terminologie. Signalez les incohérences avant leur mise en production.

**Agents personnalisés** -- Tout client compatible avec MCP peut lire et écrire la mémoire linguistique. Demandez à votre assistant de codage de "mettre à jour la terminologie avec le nouveau nom de produit" ou de "régler le ton de voix à professionnel pour la localisation allemande" et il traduira votre intention en l'appel API approprié.

## Affinement progressif

La mémoire linguistique s'améliore à l'usage. À chaque fois qu'un réviseur corrige une sortie de l'agent, cette correction alimente la prochaine version de votre voix ou de votre terminologie. Au fil du temps, l'écart entre la première ébauche et la sortie finale se resserre, et l'étape de révision devient plus rapide.

C'est la boucle de rétroaction au cœur de Glossia : générer, revoir, affiner le contexte, générer à nouveau. Les agents ne se contentent pas de suivre des instructions. Ils travaillent avec un contexte qui s'améliore à chaque cycle.