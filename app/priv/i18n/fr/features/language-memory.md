%{
  title: "Mémoire linguistique",
  summary:
    "Une couche de contexte versionnée qui capture la voix, la terminologie et le style de votre organisation. La mémoire linguistique guide chaque flux de travail d'agent et s'étend à vos propres outils via l'API et MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionné et traçable",
      description:
        "Chaque modification de votre voix ou de votre terminologie crée une nouvelle version immuable. Vous pouvez consulter l'historique, comparer des itérations et revenir en arrière en cas de dérive.",
      icon: "git-branch"
    },
    %{
      title: "Au-delà de la localisation",
      description:
        "La mémoire linguistique ne sert pas uniquement à la localisation. Utilisez-la pour générer du contenu marketing, rédiger la documentation, examiner des pull requests, ou créer des publications sur les réseaux sociaux, tout dans la voix de votre organisation.",
      icon: "megaphone"
    },
    %{
      title: "Ouvert et extensible",
      description:
        "Accédez à la mémoire linguistique via l'API REST ou le serveur MCP. Alimentez-la dans vos propres pipelines CI, outils de contenu ou agents personnalisés pour maintenir la cohérence partout où vous écrivez.",
      icon: "puzzle"
    }
  ]
}
---
## Qu'est-ce que la mémoire linguistique ?

La mémoire linguistique est le contexte accumulé qui indique aux agents de Glossia comment votre organisation communique. Elle est constituée de deux primitives de base que vous créez et raffinez au fil du temps :

**Voix** définit la manière dont le contenu doit résonner. Tonalité, formalité, public cible et directives de libre rédaction s'y trouvent. Vous pouvez configurer une voix de base pour votre compte et ensuite surécrire des champs spécifiques pour chaque localisation, afin que vos contenus en japonais puissent être plus formels tandis que votre anglais reste conversationnel.

**Terminologie** définit la signification des termes et comment ils doivent être traduits. Chaque entrée contient une définition et des traductions par localisation. Lorsqu'un agent rencontre « workspace » dans votre contenu source, la terminologie lui indique s'il doit traduire, translittérer ou le laisser tel quel, et exactement quel mot utiliser dans chaque langue cible.

Ensemble, la voix et la terminologie forment une couche de contexte que les agents consultent à chaque exécution. Plus vous investissez dans cette couche, moins votre résultat nécessite de relecture.

## Versionnages immuables

La mémoire linguistique est en ajout uniquement. Lorsque vous mettez à jour votre voix ou votre terminologie, Glossia crée une nouvelle version plutôt que de surécrire l'ancienne. Chaque version enregistre qui l'a créée, la date et une note d'évolution optionnelle expliquant les modifications.

Cela signifie que vous disposez toujours d'une traçabilité complète. Vous pouvez comparer la version 3 à la version 7 pour comprendre comment votre ton a évolué sur un trimestre. Si un changement récent a introduit des incohérences, revenez à une version précédente et continuez.

La versionnisation rend également la collaboration plus sûre. Plusieurs membres de l'équipe peuvent proposer des modifications de voix sans s'inquiéter des conflits, car chaque modification est un événement distinct et traçable.

## Résolution locale

Lorsqu'un agent exécute un flux de travail pour une localisation spécifique, Glossia résout la mémoire linguistique pour ce contexte. Il commence par vos paramètres vocaux de base puis applique les surcharges spécifiques à la localisation. Le même processus s'applique à la terminologie : seules les entrées disposant d'un terme localisé pour la localisation cible sont incluses.

Cette étape de résolution signifie que les agents fonctionnent toujours avec le contexte le plus pertinent. Vous n'avez pas besoin de maintenir des configurations séparées par langue. Définissez vos valeurs par défaut une fois, surchargez là où c'est nécessaire et laissez le système de résolution s'occuper du reste.

## Utilisez-le partout

La mémoire linguistique a été conçue pour la localisation, mais elle est utile partout où vous produisez du texte. Parce que le contexte est accessible via le [REST API](/features/rest-api) et le [serveur MCP](/features/mcp-server), vous pouvez l'intégrer dans des workflows au-delà de la localisation :

**Contenu marketing et social** -- L'organisation de la voix de votre organisation à un agent de contenu qui rédige des publications sur les réseaux sociaux, des campagnes d'e-mail ou des textes de pages d'atterrissage. La Terminologie maintient la cohérence des termes de marque et les paramètres de voix assurent que le ton correspond à votre marque.

**Documentation** -- Intégrez la mémoire linguistique dans une chaîne de documentation afin que l'écriture technique respecte les mêmes règles de style que le reste de votre contenu. Les entrées de Terminologie empêchent la dérive entre la documentation, les articles d'aide et les textes du produit.

**Revue de code** -- Créez un agent qui vérifie le texte des pull requests (messages d'erreur, étiquettes d'interface, textes d'accueil) par rapport à votre voix et votre terminologie. Signalez les incohérences avant leur mise en production.

**Agents personnalisés** -- Tout client compatible avec MCP peut lire et écrire la mémoire linguistique. Demandez à votre assistant de codage de "mettre à jour la terminologie avec le nouveau nom du produit" ou de "régler le ton de la voix sur professionnel pour la locale allemande" et il traduira votre intention dans l'appel API approprié.

## Raffinement progressif

La mémoire linguistique s'améliore avec l'utilisation. Chaque fois qu'un réviseur corrige la sortie d'un agent, cette correction se réinjecte dans la prochaine version de votre voix ou de votre terminologie. Au fil du temps, l'écart entre la première ébauche et la sortie finale se réduit, et l'étape de revue devient plus rapide.

C'est la boucle de rétroaction au cœur de Glossia : générer, examiner, affiner le contexte, générer à nouveau. Les agents ne se contentent pas de suivre des instructions. Ils travaillent avec un contexte qui s'améliore à chaque cycle.