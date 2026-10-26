%{
  title: "Mémoire linguistique",
  summary:
    "Une couche de contexte versionnée qui capture la voix, le glossaire et le style de votre organisation. La mémoire linguistique guide chaque flux de travail d'agent et s'étend à vos propres outils via l'API et MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionné et auditable",
      description:
        "Chaque modification de votre voix ou de votre glossaire crée une nouvelle version immuable. Vous pouvez examiner l'historique, comparer les itérations et revenir en arrière si quelque chose dérive.",
      icon: "git-branch"
    },
    %{
      title: "Au-delà de la localisation",
      description:
        "La mémoire linguistique ne se limite pas à la localisation. Utilisez-la pour générer du contenu marketing, rédiger de la documentation, revoir les pull requests, ou concevoir des publications sociales, le tout dans la voix de votre organisation.",
      icon: "megaphone"
    },
    %{
      title: "Ouvert et extensible",
      description:
        "Accédez à la mémoire linguistique via l'API REST ou le serveur MCP. Intégrez-la dans vos propres pipelines CI, outils de contenu ou agents personnalisés pour maintenir la cohérence partout où vous rédigez.",
      icon: "puzzle"
    }
  ]
}
---

## Quelle est la mémoire linguistique ?

La mémoire linguistique est le contexte accumulé qui indique aux agents de Glossia comment votre organisation communique. Elle est composée de deux primitives de base que vous créez et affinez avec le temps :

**Voix** définit la manière dont le contenu doit sonner. Le ton, la formalité, la cible et les directrices libres y figurent toutes. Vous pouvez définir une voix de base pour votre compte, puis surcharger des champs spécifiques pour les localisations individuelles, afin que votre texte en japonais soit plus formel tandis que votre anglais reste conversationnel.

**Glossaire** définit la signification des termes et comment ils doivent être localisés. Chaque entrée contient une définition et des traductions par localisation. Lorsqu'un agent rencontre « workspace » dans votre contenu source, le glossaire lui indique s'il faut localiser, transcrire, ou le laisser tel quel, ainsi que le mot exact à utiliser dans chaque langue cible.

Ensemble, la voix et le glossaire forment une couche de contexte que les agents consultent à chaque exécution. Plus vous investissez dans cette couche, moins votre sortie nécessite de relecture.

## Versionnement immuable

La mémoire linguistique est à chaque écriture uniquement. LorsquVous updatez votre voix ou votre glossaire, Glossia crée une nouvelle version plutôt que de remplacer l'ancienne. Chaque version enregistre qui l'a créée, quand, et une note de changement explicative sur ce qui a évolué.

Cela signifie que vous avez toujours un tracé d'audit complet. Vous pouvez comparer la version 3 à la version 7 pour comprendre comment votre ton a évolué sur un trimestre. Si un changement récent a introduit des incohérences, retournez à une version précédente et continuez.

Le versionnement rend aussi la collaboration plus sûre. Plusieurs membres d'équipe peuvent proposer des changements de voix sans se soucier des conflits, car chaque changement est un événement distinct et traçable.

## Résolution sensible à la localisation

Lorsqu'un agent exécute un flux de travail pour une localisation spécifique, Glossia résout la mémoire linguistique pour ce contexte. Il commence par vos paramètres de voix de base, puis applique n'importe quelles surcharges locales spécifiques par-dessus. Il en va de même pour le glossaire : seules les entrées qui ont un terme localisé pour la localisation cible sont incluses.

Cette étape de résolution signifie que les agents travaillnt toujours avec le contexte le plus pertinent. Vous n'avez pas besoin de maintenir des configurations séparées par langue. Définissez vos par défaut une fois, et surchargez là où cela compte, et laissez le système de résolution gérer le reste.

## L'utiliser partout

La mémoire linguistique a été conçue pour la localisation, mais elle est utile partout où vous produisez du texte. Parce que le contexte est accessible via le [REST API](/features/rest-api) et le [MCP server](/features/mcp-server), vous pouvez l'intégrer dans des flux de travail au-delà de la localisation :

**Marketing et contenu social** -- Tirez la voix de votre organisation vers un agent de contenu qui rédige des posts pour les médias sociaux, des campagnes par e-mail, ou des textes de page d'atterrissage. Le glossaire garde les termes de marque cohérents et les paramètres de voix assurent que le ton correspond à votre marque.

**Documentation** -- Alimentez la mémoire linguistique dans un pipeline de documentation afin que l'écriture technique suive les mêmes règles de style que le reste de votre contenu. Les entrées du glossaire empêchent la dérive entre les documents, les articles d'aide et le contenu du produit.

**Revue de code** -- Construisez un agent qui examine les textes de la pull request (messages d'erreur, étiquettes UI, texte d'initialisation) par rapport à votre voix et glossaire. Signalez les incohérences avant qu'elles ne soient déployées.

**Agents personnalisés** -- Tout client compatible MCP peut lire et écrire la mémoire linguistique. Demandez à votre assistant de codage d'« mettre à jour le glossaire avec le nouveau nom de produit » ou de « définir le ton de la voix à professionnel pour la localisation allemande » et il traduira votre intention vers le bon appel API.

## Affinement progressif

La mémoire linguistique s'améliore avec l'usage. Chaque fois qu'un réviseur corrige la sortie d'un agent, cette correction alimente la version suivante de votre voix ou glossaire. Au fil du temps, l'écart entre le premier brouillon et la sortie finale se rétrécit, et l'étape de relecture devient plus rapide.

Il s'agit de la boucle de rétroaction au cœur de Glossia : générer, réviser, affiner le contexte, générer à nouveau. Les agents ne suivent pas seulement des instructions. Ils travaillent avec un contexte qui s'améliore à chaque cycle.
