%{
  title: "Mémoire linguistique",
  summary:
    "Une couche de contexte versionnée qui capture la voix, le glossaire et le style de votre organisation. La mémoire linguistique guide chaque flux de travail de l'agent et s'étend à vos propres outils via l'API et MCP.",
  order: 5,
  icon: "brain",
  hero_cta_text: "Commencer",
  hero_cta_url: "/signup",
  highlights: [
    %{
      title: "Versionné et auditable",
      description:
        "Tout changement apporté à votre voix ou glossaire crée une nouvelle version immuable. Vous pouvez consulter l'historique, comparer les itérer et revenir en arrière si quelque chose dévie.",
      icon: "git-branch"
    },
    %{
      title: "Au-delà de la localisation",
      description:
        "La mémoire linguistique ne sert pas uniquement à la localisation. Utilisez-la pour générer du contenu marketing, rédiger de la documentation, revoir les demandes de pull ou créer des publications sur les réseaux sociaux, le tout dans la voix de votre organisation.",
      icon: "megaphone"
    },
    %{
      title: "Ouvert et extensible",
      description:
        "Accédez à la mémoire linguistique via l'API REST ou le serveur MCP. Alimentez-la dans vos propres pipelines CI, outils de contenu ou agents personnalisés pour maintenir la cohérence partout où vous rédigez.",
      icon: "puzzle"
    }
  ]
}
---
## Qu'est-ce que la mémoire linguistique ?

La mémoire linguistique est le contexte accumulé qui indique aux agents de Glossia comment votre organisation communique. Elle se compose de deux primitives fondamentales que vous créez et affinez au fil du temps :

**Voix** définit comment le contenu doit sonner. Le ton, la formalité, le public cible et les directives libres s'y trouvent. Vous pouvez définir une voix de base pour votre compte, puis surcharger des champs spécifiques pour chaque locale, de sorte que vos contenus japonais puissent être plus formels tandis que votre anglais reste conversationnel.

**Glossaire** définit la signification des termes et comment ils doivent être localisés. Chaque entrée comporte une définition et des traductions par locale. Lorsqu'un agent rencontre "workspace" dans votre contenu source, le glossaire lui indique s'il doit le localiser, le translittérer ou le laisser tel quel, et exactement quel mot utiliser pour chaque langue cible.

Ensemble, la voix et le glossaire forment une couche de contexte que les agents consultent à chaque exécution. Plus vous investissez dans cette couche, moins votre résultat nécessite de relecture.

## Versionnement immuable

La mémoire linguistique fonctionne par ajout uniquement. Lorsque vous mettez à jour votre voix ou votre glossaire, Glossia crée une nouvelle version au lieu de remplacer l'ancienne. Chaque version enregistre qui l'a créée, quand, et une note de changement optionnelle expliquant les évolutions.

Cela signifie que vous disposez toujours d'une traçabilité complète. Vous pouvez comparer la version 3 à la version 7 pour comprendre comment votre ton a évolué au cours d'un trimestre. Si un changement récent a introduit des incohérences, revenez à une version précédente et continuez.

La gestion des versions rend également la collaboration plus sûre. Plusieurs membres d'une équipe peuvent proposer des changements de voix sans s'inquiéter des conflits, car chaque changement est un événement discret et traçable.

## Résolution locale-adaptative

Lorsqu'un agent exécute un flux de travail pour une locale spécifique, Glossia résout la mémoire linguistique pour ce contexte. Elle commence par vos paramètres de voix de base, puis applique toutes les surcharges spécifiques à la locale par-dessus. Il en va de même pour le glossaire : seules les entrées qui disposent d'un terme localisé pour la locale cible sont incluses.

Cette étape de résolution signifie que les agents travaillent toujours avec le contexte le plus pertinent. Vous n'avez pas besoin de maintenir des configurations séparées par langue. Définissez vos paramètres par défaut une fois, surchargez-les là où cela compte, et laissez le système de résolution gérer le reste.

## Utilisez-le partout

La mémoire linguistique a été conçue pour la localisation, mais elle est utile partout où vous produisez du texte. Parce que le contexte est accessible à travers le [REST API](/features/rest-api) et le [serveur MCP](/features/mcp-server), vous pouvez l'intégrer à des flux de travail au-delà de la localisation :

**Marketing et contenus sociaux** -- Intégrez la voix de votre organisation dans un agent de contenu qui rédige des publications sur les réseaux sociaux, des campagnes e-mail ou des textes de pages d'atterrissage. Le Glossaire maintient la cohérence des termes de marque et les paramètres de voix garantissent que le ton correspond à votre marque.

**Documentation** -- Alimentez la mémoire linguistique dans un pipeline de documentation afin que l'écriture technique respecte les mêmes règles de style que le reste de votre contenu. Les entrées du Glossaire empêchent la dérive sur la documentation, les articles d'aide et les textes intégrés au produit.

**Revue de code** -- Construisez un agent qui examine le contenu des pull requests (messages d'erreur, labels d'interface utilisateur, textes d'accompagnement) par rapport à votre voix et votre glossaire. Signalez les incohérences avant leur mise en production.

**Agents personnalisés** -- Tout client compatible MCP peut lire et écrire la mémoire linguistique. Demandez à votre assistant de codage de "mettre à jour le glossaire avec le nouveau nom de produit" ou de "définir le ton de la voix sur professionnel pour la localisation allemande" et il traduira votre intention dans le bon appel API.

## Affinement progressif

La mémoire linguistique s'améliore avec l'utilisation. Chaque fois qu'un examinateur corrige une réponse de l'agent, cette correction alimente la prochaine version de votre voix ou de votre glossaire. Au fil du temps, l'écart entre le premier brouillon et la production finale se réduit, et l'étape de révision devient plus rapide.

Ceci est la boucle de rétroaction au cœur de Glossia : générer, examiner, affiner le contexte, générer à nouveau. Les agents ne se contentent pas de suivre des instructions. Ils travaillent avec un contexte qui s'améliore à chaque cycle.