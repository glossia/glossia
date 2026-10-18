%{
  title: "Mémoire linguistique",
  summary:
    "Une couche de contexte versionnée qui capture la voix, le glossaire et le style de votre organisation. La mémoire linguistique guide chaque flux de travail des agents et s'étend à vos propres outils via l'API et MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionné et auditable",
      description:
        "Chaque modification de votre voix ou glossaire crée une nouvelle version immuable. Vous pouvez examiner l'historique, comparer les itérations et revenir en arrière si quelque chose dérive.",
      icon: "git-branch"
    },
    %{
      title: "Au-delà de la localisation",
      description:
        "La mémoire linguistique ne sert pas uniquement à la localisation. Utilisez-la pour générer du contenu marketing, rédiger de la documentation, examiner des pull requests ou créer des publications sociales, le tout dans la voix de votre organisation.",
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

## Quelle est la mémoire linguistique ?

La mémoire linguistique est le contexte accumulé qui indique aux agents de Glossia comment votre organisation communique. Elle se compose de deux primitives fondamentales que vous créez et affinez au fil du temps :

**Voix** définit la manière dont le contenu doit sonner. Le ton, la formalité, l'audience cible et les directives libres s'inscrivent toutes ici. Vous pouvez définir une voix de base pour votre compte, puis surcharger des champs spécifiques pour des locaux individuels, afin que votre contenu japonais puisse être plus formel tandis que votre anglais reste conversationnel.

**Glossaire** définit la signification des termes et comment ils doivent être localisés. Chaque entrée porte une définition et des traductions par localisation. Lorsqu'un agent rencontre « workspace » dans votre contenu source, le glossaire l'indique pour savoir s'il doit localiser, translittérer ou le laisser tel quel, et exactement quel mot utiliser dans chaque langue cible.

Ensemble, la voix et le glossaire forment une couche de contexte que les agents consultent à chaque exécution. Plus vous y investissez, moins votre résultat nécessite de révision.

## Versionnement immuable

La mémoire linguistique est append-only. Lorsque vous mettez à jour votre voix ou votre glossaire, Glossia crée une nouvelle version au lieu d'écraser l'ancienne. Chaque version enregistre qui l'a créée, à quand, et une note de modification facultative expliquant les évolutions.

Cela signifie que vous disposez toujours d'un historique d'audit complet. Vous pouvez comparer la version 3 à la version 7 pour comprendre comment votre ton a évolué au cours d'un trimestre. Si un changement récent a introduit des incohérences, revenez à une version précédente et continuez.

Le versionnement rend également la collaboration plus sûre. Plusieurs membres de l'équipe peuvent proposer des modifications de la voix sans se soucier des conflits, car chaque changement est un événement discret et traçable.

## Résolution sensible à la localisation

Lorsqu'un agent exécute un workflow pour une localisation spécifique, Glossia résout la mémoire linguistique pour ce contexte. Il commence par vos paramètres de voix de base, puis applique les surcharges spécifiques à la localisation en superposition. C'est le même cas pour le glossaire : seules les entrées disposant d'un terme localisé pour la localisation cible sont incluses.

Cette étape de résolution signifie que les agents travaillent toujours avec le contexte le plus pertinent. Vous n'avez pas besoin de maintenir des configurations séparées par langue. Définissez vos valeurs par défaut une fois, surchargez là où cela compte, et laissez le système de résolution s'occuper du reste.

## L'utilisez partout

La mémoire linguistique a été conçue pour la localisation, mais elle est utile partout où vous produisez du texte. Parce que le contexte est accessible via la [REST API](/features/rest-api) et le [serveur MCP](/features/mcp-server), vous l'intégrez dans des workflows au-delà de la localisation :

**Marketing et contenu social** -- Intégrez la voix de votre organisation dans un agent de contenu qui rédige des posts sur les réseaux sociaux, des campagnes e-mail ou des textes de page d'atterrissage. Le Glossaire conserve la cohérence des termes de la marque et les paramètres de voix assurent que le ton correspond à votre marque.

**Documentation** -- Injectez la mémoire linguistique dans une pipeline de documentation pour que la rédaction technique suive les mêmes règles de style que le reste de votre contenu. Les entrées du Glossaire éviteront la dérive entre la documentation, les articles d'aide et le contenu intégré.

**Revue de code** -- Créez un agent qui examine les textes des pull requests (messages d'erreur, étiquettes UI, textes d'accueil) par rapport à votre voix et à votre glossaire. Signalez les incohérences avant la mise en production.

**Agents personnalisés** -- Tout client compatible MCP peut lire et écrire la mémoire linguistique. Demandez à votre assistant de codage de « mettre à jour le glossaire avec le nouveau nom du produit » ou de « définir le ton de la voix professionnel pour la localisation allemande » et il traduira votre intention dans l'appel API correspondant.

## Affinement progressif

La mémoire linguistique s'améliore avec l'utilisation. Chaque fois qu'un relecteur corrige la sortie d'un agent, cette correction se réinjecte dans la prochaine version de votre voix ou de votre glossaire. Au fil du temps, l'écart entre la première ébauche et la sortie finale se réduit, et l'étape de révision devient plus rapide.

Ceci est la boucle de rétroaction au cœur de Glossia : générer, réviser, affiner le contexte, générer à nouveau. Les agents ne suivent pas seulement les instructions. Ils travaillent avec un contexte qui s'améliore à chaque cycle.
